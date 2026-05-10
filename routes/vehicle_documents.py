from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_
from database import get_db
from utils.auth import get_current_user
from models.users import User
from models.vehicle_documents import VehicleDocument
from models.customers import Customer
from schemas.vehicle_documents import (
    VehicleDocumentCreate, VehicleDocumentUpdate,
    VehicleDocumentResponse, VehicleDocSummary,
    _compute_doc_status
)
from datetime import date, timedelta
from typing import Optional
import httpx
import os

router = APIRouter(prefix="/api/vehicle-docs", tags=["Vehicle Documents"])


# ── Helper: load customer ─────────────────────────────────────────────────
async def _get_customer(customer_id: Optional[int], db: AsyncSession) -> Optional[Customer]:
    if customer_id is None:
        return None
    result = await db.execute(select(Customer).where(Customer.id == customer_id))
    return result.scalar_one_or_none()


# ── List ──────────────────────────────────────────────────────────────────
@router.get("/", response_model=list[VehicleDocumentResponse])
async def list_vehicle_docs(
    status:  Optional[str] = Query(None, description="Filter: expired | expiring_soon | valid"),
    search:  Optional[str] = Query(None, description="Search by vehicle number"),
    db:      AsyncSession  = Depends(get_db),
    current_user: User     = Depends(get_current_user),
):
    stmt = select(VehicleDocument).where(VehicleDocument.agent_id == current_user.id)
    if search:
        stmt = stmt.where(VehicleDocument.vehicle_number.ilike(f"%{search.upper()}%"))

    result = await db.execute(stmt.order_by(VehicleDocument.created_at.desc()))
    vehicles = result.scalars().all()

    items = []
    for v in vehicles:
        customer = await _get_customer(v.customer_id, db)
        resp = VehicleDocumentResponse.from_orm_obj(v, customer)
        if status and resp.overall_status != status:
            continue
        items.append(resp)
    return items


# ── Summary dashboard counts ──────────────────────────────────────────────
@router.get("/summary", response_model=VehicleDocSummary)
async def get_summary(
    db:           AsyncSession = Depends(get_db),
    current_user: User         = Depends(get_current_user),
):
    result = await db.execute(
        select(VehicleDocument).where(VehicleDocument.agent_id == current_user.id)
    )
    vehicles = result.scalars().all()

    today = date.today()
    cutoff = today + timedelta(days=30)

    def _expiring(d: Optional[date]) -> bool:
        return d is not None and today <= d <= cutoff

    def _expired(d: Optional[date]) -> bool:
        return d is not None and d < today

    total              = len(vehicles)
    insurance_expiring = sum(1 for v in vehicles if _expiring(v.insurance_expiry))
    puc_expiring       = sum(1 for v in vehicles if _expiring(v.puc_expiry))
    rc_expiring        = sum(1 for v in vehicles if _expiring(v.rc_expiry))
    license_expiring   = sum(1 for v in vehicles if _expiring(v.license_expiry))
    fitness_expiring   = sum(1 for v in vehicles if _expiring(v.fitness_expiry))

    expired_set  = set()
    expiring_set = set()
    valid_set    = set()
    for v in vehicles:
        dates = [v.insurance_expiry, v.puc_expiry, v.rc_expiry, v.license_expiry, v.fitness_expiry]
        has_expired  = any(_expired(d)  for d in dates)
        has_expiring = any(_expiring(d) for d in dates)
        if has_expired:
            expired_set.add(v.id)
        elif has_expiring:
            expiring_set.add(v.id)
        else:
            valid_set.add(v.id)

    return VehicleDocSummary(
        total=total,
        insurance_expiring=insurance_expiring,
        puc_expiring=puc_expiring,
        rc_expiring=rc_expiring,
        license_expiring=license_expiring,
        fitness_expiring=fitness_expiring,
        total_expiring_soon=len(expiring_set),
        total_expired=len(expired_set),
        total_valid=len(valid_set),
    )


# ── Create ────────────────────────────────────────────────────────────────
@router.post("/", response_model=VehicleDocumentResponse, status_code=201)
async def create_vehicle_doc(
    payload:      VehicleDocumentCreate,
    db:           AsyncSession = Depends(get_db),
    current_user: User         = Depends(get_current_user),
):
    # Check duplicate vehicle number for this agent
    existing = await db.execute(
        select(VehicleDocument).where(
            and_(
                VehicleDocument.agent_id == current_user.id,
                VehicleDocument.vehicle_number == payload.vehicle_number,
            )
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail=f"Vehicle {payload.vehicle_number} already exists.")

    obj = VehicleDocument(
        agent_id=current_user.id,
        **payload.model_dump(),
    )
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    customer = await _get_customer(obj.customer_id, db)
    return VehicleDocumentResponse.from_orm_obj(obj, customer)


# ── Get one ───────────────────────────────────────────────────────────────
@router.get("/{doc_id}", response_model=VehicleDocumentResponse)
async def get_vehicle_doc(
    doc_id:       int,
    db:           AsyncSession = Depends(get_db),
    current_user: User         = Depends(get_current_user),
):
    result = await db.execute(
        select(VehicleDocument).where(
            and_(VehicleDocument.id == doc_id, VehicleDocument.agent_id == current_user.id)
        )
    )
    obj = result.scalar_one_or_none()
    if not obj:
        raise HTTPException(status_code=404, detail="Vehicle document not found.")
    customer = await _get_customer(obj.customer_id, db)
    return VehicleDocumentResponse.from_orm_obj(obj, customer)


# ── Update ────────────────────────────────────────────────────────────────
@router.put("/{doc_id}", response_model=VehicleDocumentResponse)
async def update_vehicle_doc(
    doc_id:       int,
    payload:      VehicleDocumentUpdate,
    db:           AsyncSession = Depends(get_db),
    current_user: User         = Depends(get_current_user),
):
    result = await db.execute(
        select(VehicleDocument).where(
            and_(VehicleDocument.id == doc_id, VehicleDocument.agent_id == current_user.id)
        )
    )
    obj = result.scalar_one_or_none()
    if not obj:
        raise HTTPException(status_code=404, detail="Vehicle document not found.")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(obj, field, value)

    await db.commit()
    await db.refresh(obj)
    customer = await _get_customer(obj.customer_id, db)
    return VehicleDocumentResponse.from_orm_obj(obj, customer)


# ── Delete ────────────────────────────────────────────────────────────────
@router.delete("/{doc_id}", status_code=204)
async def delete_vehicle_doc(
    doc_id:       int,
    db:           AsyncSession = Depends(get_db),
    current_user: User         = Depends(get_current_user),
):
    result = await db.execute(
        select(VehicleDocument).where(
            and_(VehicleDocument.id == doc_id, VehicleDocument.agent_id == current_user.id)
        )
    )
    obj = result.scalar_one_or_none()
    if not obj:
        raise HTTPException(status_code=404, detail="Vehicle document not found.")
    await db.delete(obj)
    await db.commit()


# ── Send WhatsApp Reminder ────────────────────────────────────────────────
@router.post("/{doc_id}/send-reminder")
async def send_whatsapp_reminder(
    doc_id:       int,
    db:           AsyncSession = Depends(get_db),
    current_user: User         = Depends(get_current_user),
):
    result = await db.execute(
        select(VehicleDocument).where(
            and_(VehicleDocument.id == doc_id, VehicleDocument.agent_id == current_user.id)
        )
    )
    obj = result.scalar_one_or_none()
    if not obj:
        raise HTTPException(status_code=404, detail="Vehicle document not found.")

    customer = await _get_customer(obj.customer_id, db)
    if not customer or not customer.mobile_number:
        raise HTTPException(status_code=400, detail="Customer or mobile number not linked to this vehicle.")

    # Build reminder message
    today = date.today()
    expiring_docs = []
    doc_map = {
        "Insurance": obj.insurance_expiry,
        "PUC":       obj.puc_expiry,
        "RC":        obj.rc_expiry,
        "Driving License": obj.license_expiry,
        "Fitness Certificate": obj.fitness_expiry,
    }
    for name, d in doc_map.items():
        if d is not None:
            days = (d - today).days
            if days < 0:
                expiring_docs.append(f"• {name}: EXPIRED {abs(days)} days ago")
            elif days <= 30:
                expiring_docs.append(f"• {name}: Expires in {days} days ({d.strftime('%d %b %Y')})")

    if not expiring_docs:
        return {"status": "no_action", "message": "No expiring or expired documents found."}

    doc_lines = "\n".join(expiring_docs)
    message = (
        f"Dear {customer.full_name},\n\n"
        f"🚗 Vehicle: *{obj.vehicle_number}* ({obj.manufacturer} {obj.vehicle_model})\n\n"
        f"⚠️ *Document Renewal Alert*\n{doc_lines}\n\n"
        f"Please renew your documents at the earliest to avoid legal issues.\n\n"
        f"— InsureBook Agent"
    )

    # Try WhatsApp API if credentials available
    wa_token    = os.getenv("WHATSAPP_TOKEN")
    wa_phone_id = os.getenv("WHATSAPP_PHONE_ID")

    if wa_token and wa_phone_id:
        mobile = customer.mobile_number.replace("+", "").replace(" ", "").replace("-", "")
        if not mobile.startswith("91"):
            mobile = "91" + mobile

        url = f"https://graph.facebook.com/v18.0/{wa_phone_id}/messages"
        headers = {"Authorization": f"Bearer {wa_token}", "Content-Type": "application/json"}
        payload_wa = {
            "messaging_product": "whatsapp",
            "to": mobile,
            "type": "text",
            "text": {"body": message},
        }
        async with httpx.AsyncClient() as client:
            resp = await client.post(url, json=payload_wa, headers=headers, timeout=10)

        if resp.status_code in (200, 201):
            obj.reminder_sent = True
            await db.commit()
            return {"status": "sent", "message": "WhatsApp reminder sent successfully."}
        else:
            raise HTTPException(status_code=502, detail=f"WhatsApp API error: {resp.text}")
    else:
        # Credentials not configured — return message content for manual sending
        obj.reminder_sent = True
        await db.commit()
        return {
            "status": "manual",
            "message": "WhatsApp credentials not configured. Copy and send manually.",
            "whatsapp_message": message,
            "mobile": customer.mobile_number,
        }
