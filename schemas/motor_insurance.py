from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any
from datetime import date, datetime
from models.motor_insurance import MotorInsuranceType, VehicleType

# Base schemas
class VehicleDetails(BaseModel):
    vehicle_type: VehicleType
    vehicle_make: str = Field(..., min_length=2, max_length=100)
    vehicle_model: str = Field(..., min_length=2, max_length=100)
    vehicle_variant: Optional[str] = Field(None, max_length=100)
    manufacture_year: int = Field(..., ge=1900, le=datetime.now().year + 1)
    registration_number: str = Field(..., min_length=5, max_length=20)
    cubic_capacity: int = Field(..., ge=50, le=10000)  # CC
    fuel_type: Optional[str] = Field(None, max_length=20)

class CoverageDetails(BaseModel):
    third_party_liability: Optional[Dict[str, Any]] = None
    own_damage: Optional[Dict[str, Any]] = None
    personal_accident: Optional[Dict[str, Any]] = None
    passenger_cover: Optional[Dict[str, Any]] = None
    driver_cover: Optional[Dict[str, Any]] = None
    additional_benefits: Optional[Dict[str, Any]] = None

class AddOns(BaseModel):
    zero_depreciation: bool = False
    engine_protection: bool = False
    return_to_invoice: bool = False
    roadside_assistance: bool = False
    consumable_cover: bool = False
    personal_accident_cover: bool = True
    passenger_cover: bool = False
    driver_cover: bool = False

class PremiumBreakdown(BaseModel):
    base_premium: Optional[float] = None
    third_party_premium: Optional[float] = None
    own_damage_premium: Optional[float] = None
    addons_premium: Optional[float] = None
    net_premium: Optional[float] = None
    gst_amount: Optional[float] = None
    final_premium: Optional[float] = None

# Create schemas
class MotorInsurancePolicyCreate(BaseModel):
    insurance_type: MotorInsuranceType = MotorInsuranceType.COMPREHENSIVE
    vehicle: VehicleDetails
    idv: float = Field(..., gt=0)
    ncb_percent: float = Field(0.0, ge=0, le=50)
    previous_policy_number: Optional[str] = Field(None, max_length=100)
    previous_insurer: Optional[str] = Field(None, max_length=100)
    policy_expiry_date: Optional[date] = None
    coverage_details: Optional[CoverageDetails] = None
    addons: AddOns = AddOns()
    issue_date: date
    expiry_date: date
    claim_free_years: int = Field(0, ge=0)
    special_conditions: Optional[str] = None
    agent_notes: Optional[str] = None

    @validator('expiry_date')
    def expiry_must_be_after_issue(cls, v, values):
        if 'issue_date' in values and v <= values['issue_date']:
            raise ValueError('Expiry date must be after issue date')
        return v

    @validator('ncb_percent')
    def validate_ncb(cls, v, values):
        if 'insurance_type' in values and values['insurance_type'] == MotorInsuranceType.THIRD_PARTY and v > 0:
            raise ValueError('NCB not applicable for Third Party insurance')
        return v

class MotorInsurancePolicyUpdate(BaseModel):
    insurance_type: Optional[MotorInsuranceType] = None
    vehicle: Optional[VehicleDetails] = None
    idv: Optional[float] = Field(None, gt=0)
    ncb_percent: Optional[float] = Field(None, ge=0, le=50)
    previous_policy_number: Optional[str] = Field(None, max_length=100)
    previous_insurer: Optional[str] = Field(None, max_length=100)
    policy_expiry_date: Optional[date] = None
    coverage_details: Optional[CoverageDetails] = None
    addons: Optional[AddOns] = None
    issue_date: Optional[date] = None
    expiry_date: Optional[date] = None
    claim_free_years: Optional[int] = Field(None, ge=0)
    special_conditions: Optional[str] = None
    agent_notes: Optional[str] = None
    is_active: Optional[bool] = None

class MotorInsurancePolicyResponse(BaseModel):
    id: int
    policy_id: Optional[int] = None
    agent_id: int
    customer_id: int
    insurance_type: MotorInsuranceType
    vehicle: VehicleDetails
    idv: float
    ncb_percent: float
    previous_policy_number: Optional[str] = None
    previous_insurer: Optional[str] = None
    policy_expiry_date: Optional[date] = None
    coverage_details: Optional[Dict[str, Any]] = None
    addons: AddOns
    premium: PremiumBreakdown
    issue_date: date
    expiry_date: date
    claim_free_years: int
    special_conditions: Optional[str] = None
    agent_notes: Optional[str] = None
    is_active: bool
    is_renewed: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Quote schemas
class MotorInsuranceQuoteCreate(BaseModel):
    insurance_type: MotorInsuranceType = MotorInsuranceType.COMPREHENSIVE
    vehicle: VehicleDetails
    idv: float = Field(..., gt=0)
    ncb_percent: float = Field(0.0, ge=0, le=50)
    addons: AddOns = AddOns()
    valid_until: Optional[date] = None

class MotorInsuranceQuoteResponse(BaseModel):
    id: int
    quote_number: str
    agent_id: int
    customer_id: Optional[int] = None
    insurance_type: MotorInsuranceType
    vehicle: VehicleDetails
    idv: float
    ncb_percent: float
    premium: PremiumBreakdown
    addons: AddOns
    status: str
    valid_until: Optional[date] = None
    created_at: date
    updated_at: date

    class Config:
        from_attributes = True

# Type-specific schemas for detailed forms
class ThirdPartyInsuranceForm(BaseModel):
    """Third Party Insurance - Mandatory as per Motor Vehicles Act"""
    vehicle: VehicleDetails
    policy_period: str = Field(..., description="1 year, 3 years, 5 years")
    third_party_liability_limit: float = Field(..., description="Coverage limit in lakhs")
    personal_accident_cover: bool = True
    legal_compliance: bool = True

class ComprehensiveInsuranceForm(BaseModel):
    """Comprehensive Insurance - Own vehicle + Third Party Liability"""
    vehicle: VehicleDetails
    idv: float = Field(..., gt=0)
    ncb_percent: float = Field(0.0, ge=0, le=50)
    policy_period: str = Field(..., description="1 year, 3 years, 5 years")
    third_party_liability_limit: float = Field(..., description="Coverage limit in lakhs")
    own_damage_coverage: Dict[str, Any] = Field(..., description="OD coverage details")
    personal_accident_cover: bool = True
    addons: AddOns = AddOns()

class OwnDamageInsuranceForm(BaseModel):
    """Own Damage Insurance - Damage to own vehicle only"""
    vehicle: VehicleDetails
    idv: float = Field(..., gt=0)
    ncb_percent: float = Field(0.0, ge=0, le=50)
    policy_period: str = Field(..., description="1 year, 3 years, 5 years")
    coverage_types: List[str] = Field(..., description=["accident", "theft", "fire", "natural_calamities"])
    deductible: Optional[float] = Field(None, description="Voluntary deductible")
    addons: AddOns = AddOns()

class ZeroDepreciationInsuranceForm(BaseModel):
    """Zero Depreciation Insurance - No deduction on parts replacement"""
    vehicle: VehicleDetails
    idv: float = Field(..., gt=0)
    ncb_percent: float = Field(0.0, ge=0, le=50)
    policy_period: str = Field(..., description="1 year, 3 years, 5 years")
    coverage_percentage: float = Field(100.0, ge=50, le=100, description="Coverage percentage")
    age_limit: Optional[int] = Field(None, description="Vehicle age limit in years")
    claim_limit: Optional[int] = Field(None, description="Number of claims allowed")
    addons: AddOns = AddOns()

class EngineProtectInsuranceForm(BaseModel):
    """Engine Protect Insurance - High cost protection for engine"""
    vehicle: VehicleDetails
    idv: float = Field(..., gt=0)
    policy_period: str = Field(..., description="1 year, 3 years, 5 years")
    engine_coverage: Dict[str, Any] = Field(..., description="Engine components covered")
    coverage_limit: float = Field(..., description="Coverage limit in rupees")
    deductible: Optional[float] = Field(None, description="Voluntary deductible")
    conditions: List[str] = Field(..., description="Coverage conditions")

# Response schemas for agent app
class MotorInsuranceTypeResponse(BaseModel):
    type: MotorInsuranceType
    name: str
    description: str
    benefits: List[str]
    mandatory: bool
    suitable_for: List[str]
    form_schema: Dict[str, Any]

class MotorInsuranceDashboardResponse(BaseModel):
    total_policies: int
    active_policies: int
    expired_policies: int
    pending_quotes: int
    policies_by_type: Dict[str, int]
    recent_policies: List[MotorInsurancePolicyResponse]
    upcoming_renewals: List[MotorInsurancePolicyResponse]
    total_premium_collected: float

class MotorInsuranceListResponse(BaseModel):
    policies: List[MotorInsurancePolicyResponse]
    total: int
    page: int
    size: int
