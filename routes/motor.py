import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import delete, update, func
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

from database import get_db
from models.users import User
from models.customers import Customer
from models.policies import Policy
from models.motor_insurance import MotorInsurancePolicy, MotorInsuranceQuote, MotorInsuranceType, VehicleType
from schemas.motor_insurance import (
    MotorInsurancePolicyCreate, MotorInsurancePolicyUpdate, MotorInsurancePolicyResponse,
    MotorInsuranceQuoteCreate, MotorInsuranceQuoteResponse, MotorInsuranceTypeResponse,
    MotorInsuranceDashboardResponse, MotorInsuranceListResponse,
    ThirdPartyInsuranceForm, ComprehensiveInsuranceForm, OwnDamageInsuranceForm,
    ZeroDepreciationInsuranceForm, EngineProtectInsuranceForm
)
from utils.auth import get_current_user

router = APIRouter(prefix="/api/motor", tags=["Motor Insurance"])

# Legacy schemas for backward compatibility
class MotorCalcRequest(BaseModel):
    vehicle_type: str # 2W, 4W, CV
    cubic_capacity: int
    manufacture_year: int
    idv: float
    ncb_percent: float # 0, 20, 25, 35, 45, 50
    add_ons: List[str] # zero_dep, engine_protect, rti

class MotorCalcResponse(BaseModel):
    base_od: float
    ncb_discount: float
    total_od: float
    total_tp: float
    add_ons_total: float
    net_premium: float
    gst: float
    final_premium: float

def calculate_premium_logic(req: MotorCalcRequest) -> MotorCalcResponse:
    # Simplified mock IRDAI logic
    current_year = datetime.now().year
    age = max(0, current_year - req.manufacture_year)
    
    # 1. Base OD Premium (~1.2% to 3% of IDV depending on age)
    od_rate = 0.03 if age <= 3 else 0.02
    base_od = req.idv * od_rate
    
    # 2. NCB Discount
    ncb_discount = base_od * (req.ncb_percent / 100.0)
    total_od = base_od - ncb_discount
    
    # 3. Third Party Premium (Fixed based on CC & Type)
    total_tp = 0
    if req.vehicle_type == '2W':
        if req.cubic_capacity <= 75: total_tp = 538
        elif req.cubic_capacity <= 150: total_tp = 714
        elif req.cubic_capacity <= 350: total_tp = 1366
        else: total_tp = 2804
    else: # 4W
        if req.cubic_capacity <= 1000: total_tp = 2094
        elif req.cubic_capacity <= 1500: total_tp = 3416
        else: total_tp = 7897
        
    # 4. Add-ons
    add_ons_total = 0
    if "zero_dep" in req.add_ons:
        add_ons_total += req.idv * 0.015 # 1.5% of IDV
    if "engine_protect" in req.add_ons:
        add_ons_total += req.idv * 0.005 # 0.5% of IDV
    if "rti" in req.add_ons:
        add_ons_total += req.idv * 0.01 # 1% of IDV
        
    # 5. Net and Final
    net_premium = total_od + total_tp + add_ons_total
    gst = net_premium * 0.18
    final_premium = net_premium + gst
    
    return MotorCalcResponse(
        base_od=round(base_od, 2),
        ncb_discount=round(ncb_discount, 2),
        total_od=round(total_od, 2),
        total_tp=round(total_tp, 2),
        add_ons_total=round(add_ons_total, 2),
        net_premium=round(net_premium, 2),
        gst=round(gst, 2),
        final_premium=round(final_premium, 2)
    )

# Motor Insurance Types Information
@router.get("/insurance-types", response_model=List[MotorInsuranceTypeResponse])
async def get_motor_insurance_types():
    """Get all available motor insurance types with details"""
    types = [
        MotorInsuranceTypeResponse(
            type=MotorInsuranceType.THIRD_PARTY,
            name="Third Party Insurance",
            description="Covers damage/injury to third party, mandatory as per Motor Vehicles Act",
            benefits=["Legal Compliance", "Basic Liability Coverage", "Low Cost"],
            mandatory=True,
            suitable_for=["All vehicle owners", "Budget-conscious customers", "Old vehicles"],
            form_schema={"type": "third_party", "fields": ["vehicle_details", "policy_period", "liability_limit"]}
        ),
        MotorInsuranceTypeResponse(
            type=MotorInsuranceType.COMPREHENSIVE,
            name="Comprehensive Insurance",
            description="Covers own vehicle damage and third-party liability, including accidents, theft, fire, and natural calamities",
            benefits=["Complete Protection", "Own Damage Cover", "Third Party Liability", "Theft & Fire Cover"],
            mandatory=False,
            suitable_for=["New vehicles", "High-value vehicles", "Complete peace of mind"],
            form_schema={"type": "comprehensive", "fields": ["vehicle_details", "idv", "ncb", "addons"]}
        ),
        MotorInsuranceTypeResponse(
            type=MotorInsuranceType.OWN_DAMAGE,
            name="Own Damage Insurance",
            description="Covers damage to one's own vehicle due to accidents, natural calamities, fire, and theft",
            benefits=["Vehicle Protection", "Accident Cover", "Natural Calamities", "Fire & Theft"],
            mandatory=False,
            suitable_for=["Existing third-party policy holders", "Want additional protection"],
            form_schema={"type": "own_damage", "fields": ["vehicle_details", "idv", "coverage_types"]}
        ),
        MotorInsuranceTypeResponse(
            type=MotorInsuranceType.ZERO_DEPRECIATION,
            name="Zero Depreciation Insurance",
            description="No deduction on parts replacement, maximum claim settlement",
            benefits=["Full Claim Amount", "No Depreciation Deduction", "Quick Settlement"],
            mandatory=False,
            suitable_for=["New vehicles", "Premium vehicles", "Worry-free claims"],
            form_schema={"type": "zero_depreciation", "fields": ["vehicle_details", "idv", "coverage_percentage"]}
        ),
        MotorInsuranceTypeResponse(
            type=MotorInsuranceType.ENGINE_PROTECT,
            name="Engine Protect Insurance",
            description="Covers repair/replacement of engine components, high cost protection for the vehicle",
            benefits=["Engine Protection", "High Cost Coverage", "Component Replacement"],
            mandatory=False,
            suitable_for=["High-end vehicles", "Harsh driving conditions", "Engine protection needed"],
            form_schema={"type": "engine_protect", "fields": ["vehicle_details", "engine_coverage", "coverage_limit"]}
        )
    ]
    return types

# Motor Insurance Policy CRUD
@router.post("/policies", response_model=MotorInsurancePolicyResponse)
async def create_motor_policy(
    policy: MotorInsurancePolicyCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new motor insurance policy"""
    
    # Generate policy number
    policy_number = f"MI{datetime.now().strftime('%Y%m%d')}{uuid.uuid4().hex[:6].upper()}"
    
    # Calculate premium based on insurance type
    calc_req = MotorCalcRequest(
        vehicle_type=policy.vehicle.vehicle_type,
        cubic_capacity=policy.vehicle.cubic_capacity,
        manufacture_year=policy.vehicle.manufacture_year,
        idv=policy.idv,
        ncb_percent=policy.ncb_percent,
        add_ons=[addon for addon, enabled in policy.addons.dict().items() if enabled]
    )
    premium_calc = calculate_premium_logic(calc_req)
    
    # Create main policy record
    main_policy = Policy(
        customer_id=policy.customer_id,
        agent_id=current_user.id,
        policy_number=policy_number,
        policy_type="Motor",
        status="live",
        insurer_name="General Insurance",
        plan_name=f"{policy.insurance_type.title()} Insurance",
        premium_amount=premium_calc.final_premium,
        premium_due_date=policy.issue_date,
        issue_date=policy.issue_date,
        expiry_date=policy.expiry_date,
        sum_assured=policy.idv,
        ncb_percent=policy.ncb_percent,
        vehicle_reg_no=policy.vehicle.registration_number
    )
    db.add(main_policy)
    await db.flush()
    
    # Create motor insurance policy record
    motor_policy = MotorInsurancePolicy(
        policy_id=main_policy.id,
        agent_id=current_user.id,
        customer_id=policy.customer_id,
        insurance_type=policy.insurance_type,
        vehicle_type=policy.vehicle.vehicle_type,
        vehicle_make=policy.vehicle.vehicle_make,
        vehicle_model=policy.vehicle.vehicle_model,
        vehicle_variant=policy.vehicle.vehicle_variant,
        manufacture_year=policy.vehicle.manufacture_year,
        registration_number=policy.vehicle.registration_number,
        cubic_capacity=policy.vehicle.cubic_capacity,
        fuel_type=policy.vehicle.fuel_type,
        idv=policy.idv,
        ncb_percent=policy.ncb_percent,
        previous_policy_number=policy.previous_policy_number,
        previous_insurer=policy.previous_insurer,
        policy_expiry_date=policy.policy_expiry_date,
        coverage_details=policy.coverage_details.dict() if policy.coverage_details else None,
        zero_depreciation=policy.addons.zero_depreciation,
        engine_protection=policy.addons.engine_protection,
        return_to_invoice=policy.addons.return_to_invoice,
        roadside_assistance=policy.addons.roadside_assistance,
        consumable_cover=policy.addons.consumable_cover,
        personal_accident_cover=policy.addons.personal_accident_cover,
        passenger_cover=policy.addons.passenger_cover,
        driver_cover=policy.addons.driver_cover,
        base_premium=premium_calc.base_od,
        third_party_premium=premium_calc.total_tp,
        own_damage_premium=premium_calc.total_od,
        addons_premium=premium_calc.add_ons_total,
        net_premium=premium_calc.net_premium,
        gst_amount=premium_calc.gst,
        final_premium=premium_calc.final_premium,
        issue_date=policy.issue_date,
        expiry_date=policy.expiry_date,
        claim_free_years=policy.claim_free_years,
        special_conditions=policy.special_conditions,
        agent_notes=policy.agent_notes
    )
    db.add(motor_policy)
    await db.commit()
    await db.refresh(motor_policy)
    
    return motor_policy

@router.get("/policies", response_model=MotorInsuranceListResponse)
async def get_motor_policies(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    insurance_type: Optional[MotorInsuranceType] = Query(None),
    status: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get motor insurance policies for the agent"""
    
    query = select(MotorInsurancePolicy).where(MotorInsurancePolicy.agent_id == current_user.id)
    
    if insurance_type:
        query = query.where(MotorInsurancePolicy.insurance_type == insurance_type)
    
    if status:
        query = query.where(MotorInsurancePolicy.is_active == (status.lower() == "active"))
    
    # Get total count
    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar()
    
    # Get paginated results
    query = query.offset(skip).limit(limit)
    result = await db.execute(query)
    policies = result.scalars().all()
    
    return MotorInsuranceListResponse(
        policies=policies,
        total=total,
        page=skip // limit + 1,
        size=limit
    )

@router.get("/policies/{policy_id}", response_model=MotorInsurancePolicyResponse)
async def get_motor_policy(
    policy_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a specific motor insurance policy"""
    
    result = await db.execute(
        select(MotorInsurancePolicy).where(
            MotorInsurancePolicy.id == policy_id,
            MotorInsurancePolicy.agent_id == current_user.id
        )
    )
    policy = result.scalar_one_or_none()
    
    if not policy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motor insurance policy not found"
        )
    
    return policy

@router.put("/policies/{policy_id}", response_model=MotorInsurancePolicyResponse)
async def update_motor_policy(
    policy_id: int,
    policy_update: MotorInsurancePolicyUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update a motor insurance policy"""
    
    result = await db.execute(
        select(MotorInsurancePolicy).where(
            MotorInsurancePolicy.id == policy_id,
            MotorInsurancePolicy.agent_id == current_user.id
        )
    )
    policy = result.scalar_one_or_none()
    
    if not policy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motor insurance policy not found"
        )
    
    update_data = policy_update.dict(exclude_unset=True)
    
    # Handle vehicle details update
    if "vehicle" in update_data:
        vehicle_data = update_data.pop("vehicle")
        for field, value in vehicle_data.items():
            setattr(policy, field, value)
    
    # Handle addons update
    if "addons" in update_data:
        addons_data = update_data.pop("addons")
        for field, value in addons_data.items():
            setattr(policy, field, value)
    
    # Update other fields
    for field, value in update_data.items():
        setattr(policy, field, value)
    
    await db.commit()
    await db.refresh(policy)
    
    return policy

@router.delete("/policies/{policy_id}")
async def delete_motor_policy(
    policy_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete a motor insurance policy"""
    
    result = await db.execute(
        select(MotorInsurancePolicy).where(
            MotorInsurancePolicy.id == policy_id,
            MotorInsurancePolicy.agent_id == current_user.id
        )
    )
    policy = result.scalar_one_or_none()
    
    if not policy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motor insurance policy not found"
        )
    
    await db.delete(policy)
    await db.commit()
    
    return {"message": "Motor insurance policy deleted successfully"}

# Motor Insurance Quotes
@router.post("/quotes", response_model=MotorInsuranceQuoteResponse)
async def create_motor_quote(
    quote: MotorInsuranceQuoteCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a motor insurance quote"""
    
    # Generate quote number
    quote_number = f"MQ{datetime.now().strftime('%Y%m%d')}{uuid.uuid4().hex[:6].upper()}"
    
    # Calculate premium
    calc_req = MotorCalcRequest(
        vehicle_type=quote.vehicle.vehicle_type,
        cubic_capacity=quote.vehicle.cubic_capacity,
        manufacture_year=quote.vehicle.manufacture_year,
        idv=quote.idv,
        ncb_percent=quote.ncb_percent,
        add_ons=[addon for addon, enabled in quote.addons.dict().items() if enabled]
    )
    premium_calc = calculate_premium_logic(calc_req)
    
    motor_quote = MotorInsuranceQuote(
        agent_id=current_user.id,
        customer_id=quote.customer_id,
        quote_number=quote_number,
        insurance_type=quote.insurance_type,
        vehicle_type=quote.vehicle.vehicle_type,
        vehicle_make=quote.vehicle.vehicle_make,
        vehicle_model=quote.vehicle.vehicle_model,
        manufacture_year=quote.vehicle.manufacture_year,
        registration_number=quote.vehicle.registration_number,
        cubic_capacity=quote.vehicle.cubic_capacity,
        fuel_type=quote.vehicle.fuel_type,
        idv=quote.idv,
        ncb_percent=quote.ncb_percent,
        base_premium=premium_calc.base_od,
        third_party_premium=premium_calc.total_tp,
        own_damage_premium=premium_calc.total_od,
        addons_premium=premium_calc.add_ons_total,
        net_premium=premium_calc.net_premium,
        gst_amount=premium_calc.gst,
        final_premium=premium_calc.final_premium,
        selected_addons=quote.addons.dict(),
        valid_until=quote.valid_until or date.today() + timedelta(days=30)
    )
    db.add(motor_quote)
    await db.commit()
    await db.refresh(motor_quote)
    
    return motor_quote

@router.get("/quotes", response_model=List[MotorInsuranceQuoteResponse])
async def get_motor_quotes(
    status: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get motor insurance quotes for the agent"""
    
    query = select(MotorInsuranceQuote).where(MotorInsuranceQuote.agent_id == current_user.id)
    
    if status:
        query = query.where(MotorInsuranceQuote.status == status)
    
    result = await db.execute(query)
    quotes = result.scalars().all()
    
    return quotes

# Dashboard
@router.get("/dashboard", response_model=MotorInsuranceDashboardResponse)
async def get_motor_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get motor insurance dashboard for agent"""
    
    # Get total policies
    total_result = await db.execute(
        select(func.count()).select_from(MotorInsurancePolicy).where(
            MotorInsurancePolicy.agent_id == current_user.id
        )
    )
    total_policies = total_result.scalar() or 0
    
    # Get active policies
    active_result = await db.execute(
        select(func.count()).select_from(MotorInsurancePolicy).where(
            MotorInsurancePolicy.agent_id == current_user.id,
            MotorInsurancePolicy.is_active == True,
            MotorInsurancePolicy.expiry_date >= date.today()
        )
    )
    active_policies = active_result.scalar() or 0
    
    # Get expired policies
    expired_result = await db.execute(
        select(func.count()).select_from(MotorInsurancePolicy).where(
            MotorInsurancePolicy.agent_id == current_user.id,
            MotorInsurancePolicy.expiry_date < date.today()
        )
    )
    expired_policies = expired_result.scalar() or 0
    
    # Get pending quotes
    pending_result = await db.execute(
        select(func.count()).select_from(MotorInsuranceQuote).where(
            MotorInsuranceQuote.agent_id == current_user.id,
            MotorInsuranceQuote.status == "pending"
        )
    )
    pending_quotes = pending_result.scalar() or 0
    
    # Get policies by type
    type_result = await db.execute(
        select(MotorInsurancePolicy.insurance_type, func.count()).where(
            MotorInsurancePolicy.agent_id == current_user.id
        ).group_by(MotorInsurancePolicy.insurance_type)
    )
    policies_by_type = {row[0]: row[1] for row in type_result.all()}
    
    # Get recent policies
    recent_result = await db.execute(
        select(MotorInsurancePolicy).where(
            MotorInsurancePolicy.agent_id == current_user.id
        ).order_by(MotorInsurancePolicy.created_at.desc()).limit(5)
    )
    recent_policies = recent_result.scalars().all()
    
    # Get upcoming renewals (next 30 days)
    renewal_date = date.today() + timedelta(days=30)
    renewal_result = await db.execute(
        select(MotorInsurancePolicy).where(
            MotorInsurancePolicy.agent_id == current_user.id,
            MotorInsurancePolicy.is_active == True,
            MotorInsurancePolicy.expiry_date.between(date.today(), renewal_date)
        ).order_by(MotorInsurancePolicy.expiry_date.asc())
    )
    upcoming_renewals = renewal_result.scalars().all()
    
    # Get total premium collected
    premium_result = await db.execute(
        select(func.sum(MotorInsurancePolicy.final_premium)).where(
            MotorInsurancePolicy.agent_id == current_user.id,
            MotorInsurancePolicy.is_active == True
        )
    )
    total_premium_collected = premium_result.scalar() or 0.0
    
    return MotorInsuranceDashboardResponse(
        total_policies=total_policies,
        active_policies=active_policies,
        expired_policies=expired_policies,
        pending_quotes=pending_quotes,
        policies_by_type=policies_by_type,
        recent_policies=recent_policies,
        upcoming_renewals=upcoming_renewals,
        total_premium_collected=total_premium_collected
    )

# Type-specific form endpoints
@router.post("/forms/third-party", response_model=MotorInsuranceQuoteResponse)
async def create_third_party_quote(
    form: ThirdPartyInsuranceForm,
    customer_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create third party insurance quote"""
    
    quote_data = MotorInsuranceQuoteCreate(
        insurance_type=MotorInsuranceType.THIRD_PARTY,
        vehicle=form.vehicle,
        idv=0,  # No IDV for third party
        ncb_percent=0,
        valid_until=date.today() + timedelta(days=30)
    )
    
    return await create_motor_quote(quote_data, db, current_user)

@router.post("/forms/comprehensive", response_model=MotorInsuranceQuoteResponse)
async def create_comprehensive_quote(
    form: ComprehensiveInsuranceForm,
    customer_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create comprehensive insurance quote"""
    
    quote_data = MotorInsuranceQuoteCreate(
        insurance_type=MotorInsuranceType.COMPREHENSIVE,
        vehicle=form.vehicle,
        idv=form.idv,
        ncb_percent=form.ncb_percent,
        addons=form.addons,
        valid_until=date.today() + timedelta(days=30)
    )
    
    return await create_motor_quote(quote_data, db, current_user)


# --- NEW MOTOR CALCULATOR ENDPOINTS ---
import tempfile
from reportlab.pdfgen import canvas
from reportlab.platypus import Spacer

class MotorCalcPremiumRequest(BaseModel):
    vehicle_type: str
    fuel_type: str
    year_of_manufacture: int
    cc_category: str = ""
    idv: float
    ncb_percent: float
    addons: List[str] = []
    customer_name: str = ""
    vehicle_reg_no: str = ""

@router.post("/calculate-premium")
async def api_calculate_premium(
    req: MotorCalcPremiumRequest,
    current_user: User = Depends(get_current_user)
):
    # IRDAI TP Rates
    tp_premium = 0
    if req.vehicle_type == "Two Wheeler":
        if "Less than 75cc" in req.cc_category: tp_premium = 538
        elif "75cc to 150cc" in req.cc_category: tp_premium = 714
        elif "150cc to 350cc" in req.cc_category: tp_premium = 1366
        else: tp_premium = 2804
    elif req.vehicle_type == "Four Wheeler":
        if "Less than 1000cc" in req.cc_category: tp_premium = 2094
        elif "1000cc to 1500cc" in req.cc_category: tp_premium = 3416
        else: tp_premium = 7897
    else:
        tp_premium = 5000 # Commercial Vehicle
        
    current_year = 2026
    age = max(0, current_year - req.year_of_manufacture)
    
    depreciation_rate = 0.0
    if age == 1: depreciation_rate = 0.05
    elif age == 2: depreciation_rate = 0.10
    elif age == 3: depreciation_rate = 0.15
    elif age == 4: depreciation_rate = 0.25
    elif age == 5: depreciation_rate = 0.35
    elif age == 6: depreciation_rate = 0.40
    elif age == 7: depreciation_rate = 0.45
    elif age >= 8: depreciation_rate = 0.50
    
    base_od_rate = 0.026 if req.vehicle_type == "Two Wheeler" else 0.022
    od_before_ncb = req.idv * base_od_rate * (1 - depreciation_rate)
    ncb_discount = od_before_ncb * (req.ncb_percent / 100)
    od_premium = od_before_ncb - ncb_discount
    
    addons_breakdown = {}
    if "Zero Depreciation" in req.addons: addons_breakdown["Zero Depreciation"] = req.idv * 0.005
    if "Engine Protection Cover" in req.addons: addons_breakdown["Engine Protection Cover"] = 800
    if "Roadside Assistance" in req.addons: addons_breakdown["Roadside Assistance"] = 499
    if "Personal Accident Cover" in req.addons: addons_breakdown["Personal Accident Cover"] = 750
    if "Return to Invoice" in req.addons: addons_breakdown["Return to Invoice"] = req.idv * 0.003
    
    addons_total = sum(addons_breakdown.values())
    subtotal = od_premium + tp_premium + addons_total
    gst = subtotal * 0.18
    total_premium = subtotal + gst
    
    import time
    quote_ref = f"QT{int(time.time() * 1000)}"
    
    return {
        "od_before_ncb": round(od_before_ncb, 2),
        "ncb_discount": round(ncb_discount, 2),
        "od_premium": round(od_premium, 2),
        "tp_premium": round(tp_premium, 2),
        "addon_breakdown": {k: round(v, 2) for k, v in addons_breakdown.items()},
        "addons_total": round(addons_total, 2),
        "subtotal": round(subtotal, 2),
        "gst": round(gst, 2),
        "total_premium": round(total_premium, 2),
        "idv": round(req.idv, 2),
        "vehicle_age": age,
        "ncb_percent": req.ncb_percent,
        "vehicle_type": req.vehicle_type,
        "quote_reference": quote_ref
    }

class QuotePdfRequest(BaseModel):
    vehicle_type: str
    fuel_type: str
    year_of_manufacture: int
    cc_category: str = ""
    idv: float
    ncb_percent: float
    addons: List[str] = []
    customer_name: str = ""
    vehicle_reg_no: str = ""
    # Calculation Results
    od_before_ncb: float
    ncb_discount: float
    od_premium: float
    tp_premium: float
    addon_breakdown: dict
    addons_total: float
    subtotal: float
    gst: float
    total_premium: float
    quote_reference: str

@router.post("/generate-quote-pdf")
async def api_generate_quote_pdf(
    req: QuotePdfRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    import json
    from sqlalchemy import text
    
    # Save to history
    query = text("""
        INSERT INTO motor_quote_history 
        (agent_id, customer_name, vehicle_type, vehicle_reg_no, year_of_manufacture,
         cc_category, fuel_type, idv, ncb_percent, addons, od_premium, tp_premium,
         addons_total, gst, total_premium)
        VALUES 
        (:agent_id, :customer_name, :vehicle_type, :vehicle_reg_no, :year_of_manufacture,
         :cc_category, :fuel_type, :idv, :ncb_percent, :addons, :od_premium, :tp_premium,
         :addons_total, :gst, :total_premium)
    """)
    await db.execute(query, {
        "agent_id": current_user.id,
        "customer_name": req.customer_name,
        "vehicle_type": req.vehicle_type,
        "vehicle_reg_no": req.vehicle_reg_no,
        "year_of_manufacture": req.year_of_manufacture,
        "cc_category": req.cc_category,
        "fuel_type": req.fuel_type,
        "idv": req.idv,
        "ncb_percent": req.ncb_percent,
        "addons": json.dumps(req.addons),
        "od_premium": req.od_premium,
        "tp_premium": req.tp_premium,
        "addons_total": req.addons_total,
        "gst": req.gst,
        "total_premium": req.total_premium
    })
    await db.commit()
    
    # ReportLab PDF Generation
    filename = f"motor_quote_{req.quote_reference}.pdf"
    filepath = os.path.join(tempfile.gettempdir(), filename)
    
    doc = SimpleDocTemplate(filepath, pagesize=A4, rightMargin=30, leftMargin=30, topMargin=30, bottomMargin=30)
    elements = []
    styles = getSampleStyleSheet()

    # ── Custom styles for header ──────────────────────────────────────────
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.lib.enums import TA_LEFT, TA_RIGHT

    left_style = ParagraphStyle(
        'HeaderLeft',
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=16,
        textColor=colors.white,
        alignment=TA_LEFT,
    )
    right_style = ParagraphStyle(
        'HeaderRight',
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=16,
        textColor=colors.white,
        alignment=TA_RIGHT,
    )

    agent_name  = (current_user.full_name or "Agent").strip()
    agent_phone = (current_user.phone or "").strip()
    agent_lic   = (current_user.license_no or "").strip()

    left_para = Paragraph(
        f"<b><font size=16>{agent_name} Agency</font></b><br/>"
        f"<font size=11>{agent_name}</font><br/>"
        + (f"<font size=10>Ph: {agent_phone}</font><br/>" if agent_phone else "")
        + (f"<font size=9>License: {agent_lic}</font>" if agent_lic else ""),
        left_style,
    )
    right_para = Paragraph(
        f"<b><font size=18>MOTOR INSURANCE</font></b><br/>"
        f"<b><font size=14>PREMIUM QUOTE</font></b><br/>"
        f"<font size=9>Ref: {req.quote_reference}</font>",
        right_style,
    )

    # Use full usable width (A4 = 595pt, margins 30+30 = 535pt usable)
    header_data = [[left_para, right_para]]
    t = Table(header_data, colWidths=[267, 268])
    t.setStyle(TableStyle([
        ('BACKGROUND',  (0, 0), (-1, -1), colors.HexColor('#4CAF50')),
        ('VALIGN',      (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING',  (0, 0), (-1, -1), 14),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 14),
        ('LEFTPADDING', (0, 0), (0, -1), 14),
        ('RIGHTPADDING', (1, 0), (1, -1), 14),
        ('ROWBACKGROUNDS', (0, 0), (-1, -1), [colors.HexColor('#4CAF50')]),
    ]))
    elements.append(t)
    elements.append(Spacer(1, 20))
    
    # Vehicle Details
    elements.append(Paragraph("<b>Vehicle Details</b>", styles['Heading3']))
    v_data = [
        ["Vehicle Type", req.vehicle_type],
        ["Fuel Type", req.fuel_type],
        ["Year of Manufacture", str(req.year_of_manufacture)],
        ["IDV", f"Rs. {req.idv:,.2f}"],
        ["NCB Percentage", f"{req.ncb_percent}%"],
        ["Registration Number", req.vehicle_reg_no],
        ["Customer Name", req.customer_name],
    ]
    tv = Table(v_data, colWidths=[200, 300])
    tv.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F5F5F5')),
        ('GRID', (0,0), (-1,-1), 1, colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
    ]))
    elements.append(tv)
    elements.append(Spacer(1, 20))
    
    # Premium Breakdown
    elements.append(Paragraph("<b>Premium Breakdown</b>", styles['Heading3']))
    p_data = [
        ["Component", "Amount"],
        ["Own Damage Before NCB", f"Rs. {req.od_before_ncb:,.2f}"],
        ["NCB Discount", f"- Rs. {req.ncb_discount:,.2f}"],
        ["Own Damage Premium", f"Rs. {req.od_premium:,.2f}"],
        ["Third Party Premium", f"Rs. {req.tp_premium:,.2f}"]
    ]
    for k, v in req.addon_breakdown.items():
        p_data.append([k, f"Rs. {v:,.2f}"])
        
    p_data.append(["Subtotal", f"Rs. {req.subtotal:,.2f}"])
    p_data.append(["GST 18%", f"Rs. {req.gst:,.2f}"])
    p_data.append(["Total Premium", f"Rs. {req.total_premium:,.2f}"])
    
    tp = Table(p_data, colWidths=[350, 150])
    tp.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 0.5, colors.lightgrey),
        ('PADDING', (0,0), (-1,-1), 8),
        ('BACKGROUND', (0,-1), (-1,-1), colors.HexColor('#E8F5E9')),
        ('FONTNAME', (0,-1), (-1,-1), 'Helvetica-Bold'),
        ('TEXTCOLOR', (1,2), (1,2), colors.red), # NCB Discount red
    ]))
    elements.append(tp)
    elements.append(Spacer(1, 10))
    elements.append(Paragraph(f"<font color=gray size=12>IDV Covered: Rs. {req.idv:,.2f}</font>", styles['Normal']))
    
    doc.build(elements)
    
    return FileResponse(
        path=filepath, 
        filename=filename,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@router.get("/quote-history")
async def api_quote_history(
    limit: int = 5,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from sqlalchemy import text
    query = text("""
        SELECT * FROM motor_quote_history 
        WHERE agent_id = :agent_id
        ORDER BY created_at DESC
        LIMIT :limit
    """)
    result = await db.execute(query, {"agent_id": current_user.id, "limit": limit})
    rows = result.fetchall()
    
    history = []
    for r in rows:
        history.append({
            "id": r.id,
            "customer_name": r.customer_name,
            "vehicle_type": r.vehicle_type,
            "vehicle_reg_no": r.vehicle_reg_no,
            "total_premium": float(r.total_premium),
            "created_at": r.created_at.isoformat() if r.created_at else None
        })
    return history
