import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime, date, timedelta

from database import get_db
from models.users import User
from models.customers import Customer
from models.policies import Policy
from schemas.two_wheeler import (
    TwoWheelerPolicyCreate, TwoWheelerPolicyUpdate, TwoWheelerPolicyResponse,
    TwoWheelerQuoteCreate, TwoWheelerQuoteResponse, get_two_wheeler_policy_types
)
from utils.auth import get_current_user

router = APIRouter(prefix="/api/two-wheeler", tags=["Two Wheeler Insurance"])

# Two Wheeler Insurance Types Information
@router.get("/policy-types", response_model=List[dict])
async def get_two_wheeler_policy_types_info():
    """Get all available two wheeler insurance types with details"""
    return [policy.dict() for policy in get_two_wheeler_policy_types()]

# Two Wheeler Policy CRUD
@router.post("/policies", response_model=TwoWheelerPolicyResponse)
async def create_two_wheeler_policy(
    policy: TwoWheelerPolicyCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new two wheeler insurance policy"""
    
    # Generate policy number
    policy_number = f"TW{datetime.now().strftime('%Y%m%d')}{uuid.uuid4().hex[:6].upper()}"
    
    # Verify customer belongs to this agent
    result = await db.execute(select(Customer).where(Customer.id == policy.customer_id))
    customer = result.scalars().first()
    
    if not customer or customer.agent_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer not found or access denied"
        )
    
    # Calculate premium based on coverage type and vehicle details
    premium = calculate_two_wheeler_premium(policy)
    
    # Create main policy record
    main_policy = Policy(
        customer_id=policy.customer_id,
        agent_id=current_user.id,
        policy_number=policy_number,
        policy_type="Two Wheeler",
        status="Active",
        insurer_name="Two Wheeler Insurance Co",
        plan_name=f"{policy.coverage_type.title()} Coverage",
        premium_amount=policy.premium_amount or premium,
        premium_due_date=policy.issue_date,
        issue_date=policy.issue_date,
        expiry_date=policy.expiry_date,
        sum_assured=policy.idv or 0,
        ncb_percent=policy.ncb_percent,
        vehicle_reg_no=policy.vehicle_details.registration_number
    )
    db.add(main_policy)
    await db.flush()
    
    # Store two wheeler specific data (you could create a separate table for this)
    # For now, we'll store it in the main policy record using a JSON field approach
    two_wheeler_data = {
        "vehicle_details": policy.vehicle_details.dict(),
        "coverage_type": policy.coverage_type,
        "idv": policy.idv,
        "policy_period": policy.policy_period,
        "addons": policy.addons.dict(),
        "previous_policy_number": policy.previous_policy_number,
        "previous_insurer": policy.previous_insurer,
        "policy_expiry_date": policy.policy_expiry_date.isoformat() if policy.policy_expiry_date else None,
        "special_conditions": policy.special_conditions,
        "premium_breakdown": calculate_premium_breakdown(policy)
    }
    
    # Update main policy with two wheeler data (assuming we add a JSON field)
    # For now, we'll return the response with calculated data
    
    await db.commit()
    await db.refresh(main_policy)
    
    # Create response object
    response = TwoWheelerPolicyResponse(
        id=main_policy.id,
        customer_id=policy.customer_id,
        agent_id=current_user.id,
        policy_number=policy_number,
        vehicle_details=policy.vehicle_details,
        coverage_type=policy.coverage_type,
        idv=policy.idv,
        ncb_percent=policy.ncb_percent,
        policy_period=policy.policy_period,
        addons=policy.addons,
        previous_policy_number=policy.previous_policy_number,
        previous_insurer=policy.previous_insurer,
        policy_expiry_date=policy.policy_expiry_date,
        issue_date=policy.issue_date,
        expiry_date=policy.expiry_date,
        premium_amount=policy.premium_amount or premium,
        special_conditions=policy.special_conditions,
        is_active=True,
        created_at=main_policy.issue_date or datetime.now(),
        updated_at=datetime.now()
    )
    
    return response

@router.get("/policies", response_model=List[TwoWheelerPolicyResponse])
async def get_two_wheeler_policies(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    coverage_type: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get two wheeler insurance policies for the agent"""
    
    # Get policies for this agent with Two Wheeler type
    result = await db.execute(
        select(Policy).where(
            Policy.agent_id == current_user.id,
            Policy.policy_type == "Two Wheeler"
        ).offset(skip).limit(limit)
    )
    policies = result.scalars().all()
    
    # Convert to Two Wheeler Policy Response format
    # In a real implementation, you'd have a separate two_wheeler_policies table
    # For now, we'll create mock responses
    responses = []
    for policy in policies:
        response = TwoWheelerPolicyResponse(
            id=policy.id,
            customer_id=policy.customer_id,
            agent_id=policy.agent_id,
            policy_number=policy.policy_number,
            vehicle_details={
                "vehicle_type": "Motorcycle",  # Mock data
                "make": "Unknown",
                "model": "Unknown",
                "manufacture_year": 2020,
                "registration_number": policy.vehicle_reg_no or "Unknown",
                "engine_capacity": 150,
                "fuel_type": "Petrol",
                "vehicle_value": policy.sum_assured or 50000
            },
            coverage_type="comprehensive",  # Mock data
            idv=policy.sum_assured,
            ncb_percent=policy.ncb_percent or 0.0,
            policy_period="1 year",
            addons={
                "personal_accident_cover": True,
                "passenger_cover": False,
                "zero_depreciation": False,
                "engine_protection": False,
                "roadside_assistance": False,
                "return_to_invoice": False,
                "consumable_cover": False,
                "legal_liability": False
            },
            previous_policy_number=None,
            previous_insurer=None,
            policy_expiry_date=None,
            issue_date=policy.issue_date,
            expiry_date=policy.expiry_date,
            premium_amount=policy.premium_amount,
            special_conditions=None,
            is_active=policy.status == "Active",
            created_at=policy.issue_date or datetime.now(),
            updated_at=datetime.now()
        )
        responses.append(response)
    
    return responses

@router.get("/policies/{policy_id}", response_model=TwoWheelerPolicyResponse)
async def get_two_wheeler_policy(
    policy_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a specific two wheeler insurance policy"""
    
    result = await db.execute(
        select(Policy).where(
            Policy.id == policy_id,
            Policy.agent_id == current_user.id,
            Policy.policy_type == "Two Wheeler"
        )
    )
    policy = result.scalar_one_or_none()
    
    if not policy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Two wheeler insurance policy not found"
        )
    
    # Create response (mock data for vehicle details)
    response = TwoWheelerPolicyResponse(
        id=policy.id,
        customer_id=policy.customer_id,
        agent_id=policy.agent_id,
        policy_number=policy.policy_number,
        vehicle_details={
            "vehicle_type": "Motorcycle",
            "make": "Unknown",
            "model": "Unknown",
            "manufacture_year": 2020,
            "registration_number": policy.vehicle_reg_no or "Unknown",
            "engine_capacity": 150,
            "fuel_type": "Petrol",
            "vehicle_value": policy.sum_assured or 50000
        },
        coverage_type="comprehensive",
        idv=policy.sum_assured,
        ncb_percent=policy.ncb_percent or 0.0,
        policy_period="1 year",
        addons={
            "personal_accident_cover": True,
            "passenger_cover": False,
            "zero_depreciation": False,
            "engine_protection": False,
            "roadside_assistance": False,
            "return_to_invoice": False,
            "consumable_cover": False,
            "legal_liability": False
        },
        previous_policy_number=None,
        previous_insurer=None,
        policy_expiry_date=None,
        issue_date=policy.issue_date,
        expiry_date=policy.expiry_date,
        premium_amount=policy.premium_amount,
        special_conditions=None,
        is_active=policy.status == "Active",
        created_at=policy.issue_date or datetime.now(),
        updated_at=datetime.now()
    )
    
    return response

@router.put("/policies/{policy_id}", response_model=TwoWheelerPolicyResponse)
async def update_two_wheeler_policy(
    policy_id: int,
    policy_update: TwoWheelerPolicyUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update a two wheeler insurance policy"""
    
    result = await db.execute(
        select(Policy).where(
            Policy.id == policy_id,
            Policy.agent_id == current_user.id,
            Policy.policy_type == "Two Wheeler"
        )
    )
    policy = result.scalar_one_or_none()
    
    if not policy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Two wheeler insurance policy not found"
        )
    
    # Update main policy fields
    update_data = policy_update.dict(exclude_unset=True)
    
    if 'premium_amount' in update_data:
        policy.premium_amount = update_data['premium_amount']
    if 'expiry_date' in update_data:
        policy.expiry_date = update_data['expiry_date']
    if 'issue_date' in update_data:
        policy.issue_date = update_data['issue_date']
    if 'ncb_percent' in update_data:
        policy.ncb_percent = update_data['ncb_percent']
    if 'is_active' in update_data:
        policy.status = "Active" if update_data['is_active'] else "Inactive"
    
    await db.commit()
    await db.refresh(policy)
    
    # Return updated response
    return await get_two_wheeler_policy_response(policy, current_user.id, db)

@router.delete("/policies/{policy_id}")
async def delete_two_wheeler_policy(
    policy_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete a two wheeler insurance policy"""
    
    result = await db.execute(
        select(Policy).where(
            Policy.id == policy_id,
            Policy.agent_id == current_user.id,
            Policy.policy_type == "Two Wheeler"
        )
    )
    policy = result.scalar_one_or_none()
    
    if not policy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Two wheeler insurance policy not found"
        )
    
    await db.delete(policy)
    await db.commit()
    
    return {"message": "Two wheeler insurance policy deleted successfully"}

# Two Wheeler Quotes
@router.post("/quotes", response_model=TwoWheelerQuoteResponse)
async def create_two_wheeler_quote(
    quote: TwoWheelerQuoteCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a two wheeler insurance quote"""
    
    # Generate quote number
    quote_number = f"TQ{datetime.now().strftime('%Y%m%d')}{uuid.uuid4().hex[:6].upper()}"
    
    # Calculate premium
    premium = calculate_two_wheeler_premium(quote)
    premium_breakdown = calculate_premium_breakdown(quote)
    
    # Create response
    response = TwoWheelerQuoteResponse(
        id=0,  # Would be actual ID if stored in database
        quote_number=quote_number,
        customer_id=quote.customer_id,
        agent_id=current_user.id,
        vehicle_details=quote.vehicle_details,
        coverage_type=quote.coverage_type,
        idv=quote.idv,
        ncb_percent=quote.ncb_percent,
        policy_period=quote.policy_period,
        addons=quote.addons,
        premium_breakdown=premium_breakdown,
        final_premium=premium,
        status="pending",
        valid_until=quote.valid_until or date.today() + timedelta(days=30),
        created_at=datetime.now(),
        updated_at=datetime.now()
    )
    
    return response

@router.get("/quotes", response_model=List[TwoWheelerQuoteResponse])
async def get_two_wheeler_quotes(
    status: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get two wheeler insurance quotes for the agent"""
    
    # For now, return empty list as quotes aren't stored in database yet
    # In a real implementation, you'd have a two_wheeler_quotes table
    return []

# Premium calculation helpers
def calculate_two_wheeler_premium(policy_data) -> float:
    """Calculate premium for two wheeler insurance"""
    base_premium = 0
    
    # Base premium based on vehicle value and coverage type
    if policy_data.coverage_type == "third_party":
        # Fixed premium based on engine capacity
        cc = policy_data.vehicle_details.engine_capacity
        if cc <= 75:
            base_premium = 538
        elif cc <= 150:
            base_premium = 714
        elif cc <= 350:
            base_premium = 1366
        else:
            base_premium = 2804
    else:
        # Comprehensive/Own Damage - percentage of IDV
        if policy_data.idv:
            base_premium = policy_data.idv * 0.03  # 3% of IDV
    
    # Apply NCB discount
    if policy_data.ncb_percent > 0:
        base_premium *= (1 - policy_data.ncb_percent / 100)
    
    # Add addon premiums
    addon_premium = 0
    if policy_data.addons.zero_depreciation:
        addon_premium += (policy_data.idv or 50000) * 0.015
    if policy_data.addons.engine_protection:
        addon_premium += (policy_data.idv or 50000) * 0.005
    if policy_data.addons.roadside_assistance:
        addon_premium += 200
    if policy_data.addons.passenger_cover:
        addon_premium += 150
    
    total_premium = base_premium + addon_premium
    gst = total_premium * 0.18
    final_premium = total_premium + gst
    
    return round(final_premium, 2)

def calculate_premium_breakdown(policy_data) -> dict:
    """Calculate detailed premium breakdown"""
    base_premium = 0
    
    if policy_data.coverage_type == "third_party":
        cc = policy_data.vehicle_details.engine_capacity
        if cc <= 75:
            base_premium = 538
        elif cc <= 150:
            base_premium = 714
        elif cc <= 350:
            base_premium = 1366
        else:
            base_premium = 2804
    else:
        if policy_data.idv:
            base_premium = policy_data.idv * 0.03
    
    # NCB discount
    ncb_discount = 0
    if policy_data.ncb_percent > 0:
        ncb_discount = base_premium * (policy_data.ncb_percent / 100)
    
    # Addon premiums
    addon_premium = 0
    if policy_data.addons.zero_depreciation:
        addon_premium += (policy_data.idv or 50000) * 0.015
    if policy_data.addons.engine_protection:
        addon_premium += (policy_data.idv or 50000) * 0.005
    if policy_data.addons.roadside_assistance:
        addon_premium += 200
    if policy_data.addons.passenger_cover:
        addon_premium += 150
    
    net_premium = base_premium - ncb_discount + addon_premium
    gst = net_premium * 0.18
    final_premium = net_premium + gst
    
    return {
        "base_premium": round(base_premium, 2),
        "ncb_discount": round(ncb_discount, 2),
        "addon_premium": round(addon_premium, 2),
        "net_premium": round(net_premium, 2),
        "gst": round(gst, 2),
        "final_premium": round(final_premium, 2)
    }

async def get_two_wheeler_policy_response(policy, agent_id: int, db: AsyncSession) -> TwoWheelerPolicyResponse:
    """Helper function to create two wheeler policy response"""
    return TwoWheelerPolicyResponse(
        id=policy.id,
        customer_id=policy.customer_id,
        agent_id=agent_id,
        policy_number=policy.policy_number,
        vehicle_details={
            "vehicle_type": "Motorcycle",
            "make": "Unknown",
            "model": "Unknown",
            "manufacture_year": 2020,
            "registration_number": policy.vehicle_reg_no or "Unknown",
            "engine_capacity": 150,
            "fuel_type": "Petrol",
            "vehicle_value": policy.sum_assured or 50000
        },
        coverage_type="comprehensive",
        idv=policy.sum_assured,
        ncb_percent=policy.ncb_percent or 0.0,
        policy_period="1 year",
        addons={
            "personal_accident_cover": True,
            "passenger_cover": False,
            "zero_depreciation": False,
            "engine_protection": False,
            "roadside_assistance": False,
            "return_to_invoice": False,
            "consumable_cover": False,
            "legal_liability": False
        },
        previous_policy_number=None,
        previous_insurer=None,
        policy_expiry_date=None,
        issue_date=policy.issue_date,
        expiry_date=policy.expiry_date,
        premium_amount=policy.premium_amount,
        special_conditions=None,
        is_active=policy.status == "Active",
        created_at=policy.issue_date or datetime.now(),
        updated_at=datetime.now()
    )
