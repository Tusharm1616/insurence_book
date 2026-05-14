import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime, date

from database import get_db
from models.users import User, UserRole
from models.customers import Customer
from models.policies import Policy
from schemas.add_policy import (
    AddPolicyRequest, AddPolicyResponse, get_available_policy_types,
    InsuranceCategory, PolicySubType
)
from utils.auth import get_current_user

router = APIRouter(prefix="/api/add-policy", tags=["Add Policy"])

@router.get("/policy-types", response_model=dict)
async def get_policy_types():
    """Get all available policy types with their subtypes and required fields"""
    return get_available_policy_types().dict()

@router.get("/customers", response_model=List[dict])
async def get_agent_customers(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all customers for the current agent"""
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Only agents can access customers")
    
    result = await db.execute(
        select(Customer).where(Customer.agent_id == current_user.id)
    )
    customers = result.scalars().all()
    
    return [
        {
            "id": customer.id,
            "name": customer.full_name,
            "email": customer.email,
            "phone": customer.phone,
            "address": customer.address,
            "state": customer.state,
            "city": customer.city
        }
        for customer in customers
    ]

@router.post("/", response_model=AddPolicyResponse)
async def add_policy(
    policy_request: AddPolicyRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Add a new policy with comprehensive validation"""
    
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Only agents can create policies")
    
    # Verify customer belongs to this agent
    result = await db.execute(
        select(Customer).where(Customer.id == policy_request.customer.customer_id)
    )
    customer = result.scalars().first()
    
    if not customer or customer.agent_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer not found or access denied"
        )
    
    # Generate policy number based on insurance category
    category_code = {
        InsuranceCategory.LIFE: "LI",
        InsuranceCategory.HEALTH: "HL",
        InsuranceCategory.MOTOR: "MI",
        InsuranceCategory.TWO_WHEELER: "TW",
        InsuranceCategory.TRAVEL: "TR",
        InsuranceCategory.HOME: "HM",
        InsuranceCategory.BUSINESS: "BS",
        InsuranceCategory.SHOP_COMMERCIAL: "SC",
        InsuranceCategory.ACCIDENT: "AC",
        InsuranceCategory.TERM: "TM"
    }
    
    code = category_code.get(policy_request.insurance_category, "PL")
    policy_number = f"{code}{datetime.now().strftime('%Y%m%d')}{uuid.uuid4().hex[:6].upper()}"
    
    # Calculate premium based on insurance type
    premium = calculate_premium_by_type(policy_request)
    
    # Create main policy record
    new_policy = Policy(
        customer_id=policy_request.customer.customer_id,
        agent_id=current_user.id,
        policy_number=policy_number,
        policy_type=policy_request.insurance_category.value,
        status=policy_request.policy_details.status,
        insurer_name=policy_request.policy_details.insurer_name,
        plan_name=policy_request.policy_details.plan_name,
        premium_amount=policy_request.policy_details.premium_amount or premium,
        premium_due_date=policy_request.policy_details.premium_due_date,
        issue_date=policy_request.policy_details.issue_date,
        expiry_date=policy_request.policy_details.expiry_date,
        start_date=policy_request.policy_details.issue_date,
        end_date=policy_request.policy_details.expiry_date,
        maturity_date=policy_request.policy_details.maturity_date,
        sum_assured=policy_request.policy_details.sum_assured,
        ncb_percent=get_ncb_percent(policy_request),
        vehicle_reg_no=get_vehicle_reg_no(policy_request)
    )
    
    db.add(new_policy)
    await db.commit()
    await db.refresh(new_policy)
    
    # Prepare coverage details
    coverage_details = prepare_coverage_details(policy_request)
    
    return AddPolicyResponse(
        success=True,
        message=f"Policy created successfully for {policy_request.insurance_category.value}",
        policy_id=new_policy.id,
        policy_number=policy_number,
        premium_amount=policy_request.policy_details.premium_amount or premium,
        coverage_details=coverage_details
    )

@router.get("/validate/{customer_id}")
async def validate_customer_for_policy(
    customer_id: int,
    insurance_category: InsuranceCategory = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Validate if customer is eligible for specific insurance category"""
    
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Only agents can validate customers")
    
    result = await db.execute(
        select(Customer).where(
            Customer.id == customer_id,
            Customer.agent_id == current_user.id
        )
    )
    customer = result.scalars().first()
    
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer not found or access denied"
        )
    
    # Validate based on insurance category
    validation_result = validate_customer_eligibility(customer, insurance_category)
    
    return {
        "eligible": validation_result["eligible"],
        "customer": {
            "id": customer.id,
            "name": customer.full_name,
            "age": customer.age if hasattr(customer, 'age') else None,
            "existing_policies": validation_result["existing_policies"]
        },
        "requirements": validation_result["requirements"],
        "restrictions": validation_result["restrictions"]
    }

@router.get("/premium-calculator")
async def calculate_premium(
    insurance_category: InsuranceCategory = Query(...),
    policy_subtype: PolicySubType = Query(...),
    sum_assured: float = Query(..., gt=0),
    policy_term: Optional[int] = Query(None, ge=1),
    age: Optional[int] = Query(None, ge=18, le=100),
    vehicle_type: Optional[str] = Query(None),
    engine_capacity: Optional[int] = Query(None, ge=50)
):
    """Calculate premium for different insurance types"""
    
    try:
        premium = calculate_premium_by_params(
            insurance_category, policy_subtype, sum_assured, policy_term,
            age, vehicle_type, engine_capacity
        )
        
        return {
            "success": True,
            "premium_amount": premium["premium"],
            "breakdown": premium["breakdown"],
            "gst": premium["gst"],
            "final_premium": premium["final_premium"]
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

@router.get("/recent-policies")
async def get_recent_policies(
    limit: int = Query(10, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get recent policies created by the agent"""
    
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Only agents can access policies")
    
    result = await db.execute(
        select(Policy)
        .where(Policy.agent_id == current_user.id)
        .order_by(Policy.id.desc())
        .limit(limit)
    )
    policies = result.scalars().all()
    
    return [
        {
            "id": policy.id,
            "policy_number": policy.policy_number,
            "policy_type": policy.policy_type,
            "premium_amount": float(policy.premium_amount) if policy.premium_amount else 0.0,
            "issue_date": policy.issue_date.isoformat() if policy.issue_date else None,
            "expiry_date": policy.expiry_date.isoformat() if policy.expiry_date else None,
            "status": policy.status
        }
        for policy in policies
    ]

# Helper functions
def calculate_premium_by_type(policy_request: AddPolicyRequest) -> float:
    """Calculate premium based on insurance type"""
    
    category = policy_request.insurance_category
    sum_assured = policy_request.policy_details.sum_assured
    
    # Basic premium calculation (can be enhanced with actual formulas)
    if category in [InsuranceCategory.LIFE, InsuranceCategory.TERM]:
        # Life/Term insurance: 1-2% of sum assured based on age and term
        base_premium = sum_assured * 0.015
        
    elif category == InsuranceCategory.HEALTH:
        # Health insurance: 3-5% of sum insured
        base_premium = sum_assured * 0.04
        
    elif category in [InsuranceCategory.MOTOR, InsuranceCategory.TWO_WHEELER]:
        # Motor/Two Wheeler: based on vehicle type and IDV
        if policy_request.motor_insurance:
            cc = policy_request.motor_insurance.cubic_capacity
        elif policy_request.two_wheeler_insurance:
            cc = policy_request.two_wheeler_insurance.engine_capacity
        else:
            cc = 1500  # default
            
        if cc <= 75:
            base_premium = 538
        elif cc <= 150:
            base_premium = 714
        elif cc <= 350:
            base_premium = 1366
        else:
            base_premium = 2804
            
    elif category == InsuranceCategory.TRAVEL:
        # Travel insurance: based on duration and destination
        if policy_request.travel_insurance:
            duration = policy_request.travel_insurance.travel_duration
            base_premium = duration * 50  # 50 per day
        else:
            base_premium = 5000  # default
            
    elif category in [InsuranceCategory.HOME, InsuranceCategory.BUSINESS, InsuranceCategory.SHOP_COMMERCIAL]:
        # Property insurance: 0.5-1% of sum insured
        base_premium = sum_assured * 0.008
        
    elif category == InsuranceCategory.ACCIDENT:
        # Accident insurance: 0.2-0.5% of coverage amount
        base_premium = sum_assured * 0.003
        
    else:
        base_premium = sum_assured * 0.02  # default 2%
    
    # Apply NCB if applicable
    ncb_percent = get_ncb_percent(policy_request)
    if ncb_percent > 0:
        base_premium *= (1 - ncb_percent / 100)
    
    # Add GST
    gst = base_premium * 0.18
    final_premium = base_premium + gst
    
    return round(final_premium, 2)

def calculate_premium_by_params(
    insurance_category: InsuranceCategory,
    policy_subtype: PolicySubType,
    sum_assured: float,
    policy_term: Optional[int],
    age: Optional[int],
    vehicle_type: Optional[str],
    engine_capacity: Optional[int]
) -> dict:
    """Calculate premium by parameters for calculator"""
    
    # Basic premium calculation
    if insurance_category in [InsuranceCategory.LIFE, InsuranceCategory.TERM]:
        base_premium = sum_assured * 0.015
        if age and age > 50:
            base_premium *= 1.2  # 20% extra for age > 50
        
    elif insurance_category == InsuranceCategory.HEALTH:
        base_premium = sum_assured * 0.04
        
    elif insurance_category in [InsuranceCategory.MOTOR, InsuranceCategory.TWO_WHEELER]:
        if engine_capacity:
            if engine_capacity <= 75:
                base_premium = 538
            elif engine_capacity <= 150:
                base_premium = 714
            elif engine_capacity <= 350:
                base_premium = 1366
            else:
                base_premium = 2804
        else:
            base_premium = 2000
            
    elif insurance_category == InsuranceCategory.TRAVEL:
        base_premium = 5000  # Will be calculated based on duration
        
    else:
        base_premium = sum_assured * 0.02
    
    # GST calculation
    gst = base_premium * 0.18
    final_premium = base_premium + gst
    
    return {
        "premium": round(base_premium, 2),
        "gst": round(gst, 2),
        "final_premium": round(final_premium, 2),
        "breakdown": {
            "base_premium": round(base_premium, 2),
            "gst_percentage": "18%",
            "total": round(final_premium, 2)
        }
    }

def get_ncb_percent(policy_request: AddPolicyRequest) -> float:
    """Get NCB percentage from policy request"""
    
    if policy_request.motor_insurance:
        return policy_request.motor_insurance.ncb_percent
    elif policy_request.two_wheeler_insurance:
        return 0.0  # NCB not typically applicable for two wheelers
    
    return 0.0

def get_vehicle_reg_no(policy_request: AddPolicyRequest) -> Optional[str]:
    """Get vehicle registration number from policy request"""
    
    if policy_request.motor_insurance:
        return policy_request.motor_insurance.registration_number
    elif policy_request.two_wheeler_insurance:
        return policy_request.two_wheeler_insurance.registration_number
    
    return None

def prepare_coverage_details(policy_request: AddPolicyRequest) -> dict:
    """Prepare coverage details for response"""
    
    details = {
        "insurance_category": policy_request.insurance_category.value,
        "policy_subtype": policy_request.policy_subtype.value,
        "insurer_name": policy_request.policy_details.insurer_name,
        "plan_name": policy_request.policy_details.plan_name,
        "sum_assured": policy_request.policy_details.sum_assured
    }
    
    # Add type-specific details
    if policy_request.life_insurance:
        details.update({
            "policy_term": policy_request.life_insurance.policy_term,
            "nominee_name": policy_request.life_insurance.nominee_name,
            "riders": policy_request.life_insurance.riders
        })
    
    elif policy_request.health_insurance:
        details.update({
            "sum_insured": policy_request.health_insurance.sum_insured,
            "policy_term": policy_request.health_insurance.policy_term,
            "family_members": policy_request.health_insurance.family_members
        })
    
    elif policy_request.motor_insurance:
        details.update({
            "vehicle_type": policy_request.motor_insurance.vehicle_type,
            "vehicle_make": policy_request.motor_insurance.vehicle_make,
            "vehicle_model": policy_request.motor_insurance.vehicle_model,
            "registration_number": policy_request.motor_insurance.registration_number,
            "cubic_capacity": policy_request.motor_insurance.cubic_capacity
        })
    
    elif policy_request.two_wheeler_insurance:
        details.update({
            "vehicle_type": policy_request.two_wheeler_insurance.vehicle_type,
            "vehicle_make": policy_request.two_wheeler_insurance.vehicle_make,
            "vehicle_model": policy_request.two_wheeler_insurance.vehicle_model,
            "registration_number": policy_request.two_wheeler_insurance.registration_number,
            "engine_capacity": policy_request.two_wheeler_insurance.engine_capacity,
            "coverage_type": policy_request.two_wheeler_insurance.coverage_type
        })
    
    return details

def validate_customer_eligibility(customer: Customer, insurance_category: InsuranceCategory) -> dict:
    """Validate customer eligibility for insurance category"""
    
    # This would typically check age, existing policies, medical conditions, etc.
    # For now, returning basic validation
    
    requirements = []
    restrictions = []
    
    if insurance_category in [InsuranceCategory.LIFE, InsuranceCategory.TERM]:
        requirements.append("Age between 18-65 years")
        requirements.append("Medical checkup may be required")
        
    elif insurance_category == InsuranceCategory.HEALTH:
        requirements.append("Age between 18-65 years")
        requirements.append("Medical history required")
        
    elif insurance_category in [InsuranceCategory.MOTOR, InsuranceCategory.TWO_WHEELER]:
        requirements.append("Valid driving license")
        requirements.append("Vehicle registration documents")
        
    elif insurance_category == InsuranceCategory.TRAVEL:
        requirements.append("Valid passport for international travel")
        requirements.append("Travel itinerary")
    
    return {
        "eligible": True,  # Simplified for demo
        "existing_policies": 0,  # Would query actual policies
        "requirements": requirements,
        "restrictions": restrictions
    }
