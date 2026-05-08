from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any
from datetime import date, datetime
from enum import Enum

class TwoWheelerType(str, Enum):
    MOTORCYCLE = "Motorcycle"
    SCOOTER = "Scooter"
    ELECTRIC_SCOOTER = "Electric Scooter"
    MOPED = "Moped"

class TwoWheelerCoverageType(str, Enum):
    THIRD_PARTY = "third_party"
    COMPREHENSIVE = "comprehensive"
    OWN_DAMAGE = "own_damage"

class TwoWheelerVehicleDetails(BaseModel):
    vehicle_type: TwoWheelerType
    make: str = Field(..., min_length=2, max_length=50)
    model: str = Field(..., min_length=2, max_length=50)
    variant: Optional[str] = Field(None, max_length=50)
    manufacture_year: int = Field(..., ge=1990, le=datetime.now().year + 1)
    registration_number: str = Field(..., min_length=5, max_length=20)
    engine_capacity: int = Field(..., ge=50, le=2000)  # CC
    fuel_type: Optional[str] = Field(None, max_length=20)
    vehicle_value: float = Field(..., gt=0)  # Market value for IDV

class TwoWheelerAddOns(BaseModel):
    personal_accident_cover: bool = True
    passenger_cover: bool = False
    zero_depreciation: bool = False
    engine_protection: bool = False
    roadside_assistance: bool = False
    return_to_invoice: bool = False
    consumable_cover: bool = False
    legal_liability: bool = False

class TwoWheelerPolicyCreate(BaseModel):
    customer_id: int
    vehicle_details: TwoWheelerVehicleDetails
    coverage_type: TwoWheelerCoverageType
    idv: Optional[float] = Field(None, gt=0)  # Insured Declared Value
    ncb_percent: float = Field(0.0, ge=0, le=50)
    policy_period: str = Field("1 year", pattern="^(1 year|3 years|5 years)$")
    addons: TwoWheelerAddOns = TwoWheelerAddOns()
    previous_policy_number: Optional[str] = Field(None, max_length=50)
    previous_insurer: Optional[str] = Field(None, max_length=100)
    policy_expiry_date: Optional[date] = None
    issue_date: date
    expiry_date: date
    premium_amount: Optional[float] = Field(None, gt=0)
    special_conditions: Optional[str] = None

    @validator('expiry_date')
    def expiry_must_be_after_issue(cls, v, values):
        if 'issue_date' in values and v <= values['issue_date']:
            raise ValueError('Expiry date must be after issue date')
        return v

    @validator('idv')
    def validate_idv(cls, v, values):
        if v is None and 'coverage_type' in values:
            coverage_type = values['coverage_type']
            if coverage_type in [TwoWheelerCoverageType.COMPREHENSIVE, TwoWheelerCoverageType.OWN_DAMAGE]:
                raise ValueError('IDV is required for Comprehensive and Own Damage coverage')
        return v

    @validator('ncb_percent')
    def validate_ncb(cls, v, values):
        if v > 0 and 'coverage_type' in values:
            coverage_type = values['coverage_type']
            if coverage_type == TwoWheelerCoverageType.THIRD_PARTY:
                raise ValueError('NCB not applicable for Third Party insurance')
        return v

class TwoWheelerPolicyUpdate(BaseModel):
    vehicle_details: Optional[TwoWheelerVehicleDetails] = None
    coverage_type: Optional[TwoWheelerCoverageType] = None
    idv: Optional[float] = Field(None, gt=0)
    ncb_percent: Optional[float] = Field(None, ge=0, le=50)
    policy_period: Optional[str] = Field(None, pattern="^(1 year|3 years|5 years)$")
    addons: Optional[TwoWheelerAddOns] = None
    previous_policy_number: Optional[str] = Field(None, max_length=50)
    previous_insurer: Optional[str] = Field(None, max_length=100)
    policy_expiry_date: Optional[date] = None
    issue_date: Optional[date] = None
    expiry_date: Optional[date] = None
    premium_amount: Optional[float] = Field(None, gt=0)
    special_conditions: Optional[str] = None
    is_active: Optional[bool] = None

class TwoWheelerPolicyResponse(BaseModel):
    id: int
    customer_id: int
    agent_id: int
    policy_number: str
    vehicle_details: TwoWheelerVehicleDetails
    coverage_type: TwoWheelerCoverageType
    idv: Optional[float] = None
    ncb_percent: float
    policy_period: str
    addons: TwoWheelerAddOns
    previous_policy_number: Optional[str] = None
    previous_insurer: Optional[str] = None
    policy_expiry_date: Optional[date] = None
    issue_date: date
    expiry_date: date
    premium_amount: float
    special_conditions: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class TwoWheelerQuoteCreate(BaseModel):
    customer_id: int
    vehicle_details: TwoWheelerVehicleDetails
    coverage_type: TwoWheelerCoverageType
    idv: Optional[float] = Field(None, gt=0)
    ncb_percent: float = Field(0.0, ge=0, le=50)
    policy_period: str = Field("1 year", pattern="^(1 year|3 years|5 years)$")
    addons: TwoWheelerAddOns = TwoWheelerAddOns()
    valid_until: Optional[date] = None

class TwoWheelerQuoteResponse(BaseModel):
    id: int
    quote_number: str
    customer_id: int
    agent_id: int
    vehicle_details: TwoWheelerVehicleDetails
    coverage_type: TwoWheelerCoverageType
    idv: Optional[float] = None
    ncb_percent: float
    policy_period: str
    addons: TwoWheelerAddOns
    premium_breakdown: Dict[str, float]
    final_premium: float
    status: str
    valid_until: Optional[date] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class TwoWheelerPolicyInfo(BaseModel):
    """Information about Two Wheeler Insurance policy types"""
    coverage_type: TwoWheelerCoverageType
    name: str
    description: str
    benefits: List[str]
    mandatory: bool
    suitable_for: List[str]
    required_fields: List[str]
    premium_calculation: str

# Two Wheeler Insurance Types Information
def get_two_wheeler_policy_types() -> List[TwoWheelerPolicyInfo]:
    return [
        TwoWheelerPolicyInfo(
            coverage_type=TwoWheelerCoverageType.THIRD_PARTY,
            name="Third Party Insurance",
            description="Mandatory coverage for damage/injury to third party as per Motor Vehicles Act",
            benefits=["Legal Compliance", "Basic Liability Coverage", "Low Cost Premium"],
            mandatory=True,
            suitable_for=["All two-wheeler owners", "Budget-conscious customers", "Old vehicles"],
            required_fields=["vehicle_details", "policy_period"],
            premium_calculation="Fixed based on engine capacity"
        ),
        TwoWheelerPolicyInfo(
            coverage_type=TwoWheelerCoverageType.COMPREHENSIVE,
            name="Comprehensive Insurance",
            description="Complete protection including own damage and third party liability",
            benefits=["Own Damage Cover", "Third Party Liability", "Theft Protection", "Natural Calamities"],
            mandatory=False,
            suitable_for=["New two-wheelers", "High-value vehicles", "Complete peace of mind"],
            required_fields=["vehicle_details", "idv", "policy_period", "addons"],
            premium_calculation="Based on IDV, age, and engine capacity"
        ),
        TwoWheelerPolicyInfo(
            coverage_type=TwoWheelerCoverageType.OWN_DAMAGE,
            name="Own Damage Insurance",
            description="Covers damage to your own two-wheeler only",
            benefits=["Vehicle Protection", "Accident Cover", "Fire & Theft Cover"],
            mandatory=False,
            suitable_for=["Existing third-party policy holders", "Want additional protection"],
            required_fields=["vehicle_details", "idv", "policy_period"],
            premium_calculation="Based on IDV and vehicle age"
        )
    ]
