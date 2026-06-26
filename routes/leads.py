from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from datetime import datetime, date

from database import get_db
from models.users import User, UserRole
from models.leads import Lead
from models.customers import Customer
from schemas.leads import LeadCreate, LeadUpdate, LeadResponse, LeadConvertResponse
from utils.auth import get_current_user

router = APIRouter(prefix="/leads", tags=["Leads"])


@router.post("/", response_model=LeadResponse)
async def create_lead(
    lead_in: LeadCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Only agents can create leads")

    new_lead = Lead(
        agent_id=current_user.id,
        name=lead_in.name,
        phone=lead_in.phone,
        email=lead_in.email,
        insurance_type=lead_in.insurance_type,
        source=lead_in.source,
        status=lead_in.status,
        notes=lead_in.notes,
        follow_up_date=lead_in.follow_up_date,
    )
    db.add(new_lead)
    await db.commit()
    await db.refresh(new_lead)
    return new_lead


@router.get("/", response_model=List[LeadResponse])
async def list_leads(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Access denied")

    result = await db.execute(
        select(Lead).where(Lead.agent_id == current_user.id).order_by(Lead.created_at.desc())
    )
    return result.scalars().all()


@router.get("/today-followups")
async def today_followups(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return count and list of leads with follow_up_date = today"""
    today_start = datetime.combine(date.today(), datetime.min.time())
    today_end = datetime.combine(date.today(), datetime.max.time())

    result = await db.execute(
        select(Lead).where(
            Lead.agent_id == current_user.id,
            Lead.follow_up_date >= today_start,
            Lead.follow_up_date <= today_end,
            Lead.status == "Follow-up Scheduled",
        )
    )
    leads = result.scalars().all()
    return {"count": len(leads), "leads": leads}


@router.get("/{lead_id}", response_model=LeadResponse)
async def get_lead(
    lead_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Lead).where(Lead.id == lead_id, Lead.agent_id == current_user.id)
    )
    lead = result.scalar_one_or_none()
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found")
    return lead


@router.put("/{lead_id}", response_model=LeadResponse)
async def update_lead(
    lead_id: int,
    lead_in: LeadUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Lead).where(Lead.id == lead_id, Lead.agent_id == current_user.id)
    )
    lead = result.scalar_one_or_none()
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found")

    update_data = lead_in.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(lead, field, value)

    lead.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(lead)
    return lead


@router.delete("/{lead_id}")
async def delete_lead(
    lead_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Lead).where(Lead.id == lead_id, Lead.agent_id == current_user.id)
    )
    lead = result.scalar_one_or_none()
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found")

    await db.delete(lead)
    await db.commit()
    return {"message": "Lead deleted successfully"}


@router.post("/{lead_id}/convert", response_model=LeadConvertResponse)
async def convert_lead_to_customer(
    lead_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Convert a lead to a customer — copies name, phone, email to a new customer record."""
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Only agents can convert leads")

    result = await db.execute(
        select(Lead).where(Lead.id == lead_id, Lead.agent_id == current_user.id)
    )
    lead = result.scalar_one_or_none()
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found")

    if lead.status == "Converted":
        raise HTTPException(status_code=400, detail="Lead is already converted")

    # Create customer profile (no separate user account needed for lead conversion)
    new_customer = Customer(
        full_name=lead.name,
        phone=lead.phone,
        email=lead.email,
        agent_id=current_user.id,
    )
    db.add(new_customer)
    await db.flush()

    # Update lead status
    lead.status = "Converted"
    lead.converted_customer_id = new_customer.id
    lead.updated_at = datetime.utcnow()

    await db.commit()
    await db.refresh(new_customer)

    return LeadConvertResponse(
        message=f"Lead '{lead.name}' converted to customer successfully",
        customer_id=new_customer.id,
        lead_id=lead.id,
    )
