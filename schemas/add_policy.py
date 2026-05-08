from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any, Union
from datetime import date, datetime
from enum import Enum

class InsuranceCategory(str, Enum):
    LIFE = "Life Insurance"
    HEALTH = "Health Insurance"
    MOTOR = "Motor Insurance"
    TWO_WHEELER = "Two Wheeler Insurance"
    TRAVEL = "Travel Insurance"
    HOME = "Home Insurance"
    BUSINESS = "Business Insurance"
    SHOP_COMMERCIAL = "Shop/Commercial"
    ACCIDENT = "Accident Insurance"
    TERM = "Term Insurance"

class PolicySubType(str, Enum):
    # Life Insurance Subtypes
    TERM_LIFE = "Term Life"
    WHOLE_LIFE = "Whole Life"
    ENDOWMENT = "Endowment"
    MONEY_BACK = "Money Back"
    ULIP = "ULIP"
    
    # Health Insurance Subtypes
    INDIVIDUAL_HEALTH = "Individual Health"
    FAMILY_FLOATER = "Family Floater"
    SENIOR_CITIZEN = "Senior Citizen"
    CRITICAL_ILLNESS = "Critical Illness"
    PERSONAL_ACCIDENT = "Personal Accident"
    
    # Motor Insurance Subtypes
    THIRD_PARTY = "Third Party"
    COMPREHENSIVE = "Comprehensive"
    OWN_DAMAGE = "Own Damage"
    ZERO_DEPRECIATION = "Zero Depreciation"
    ENGINE_PROTECT = "Engine Protect"
    
    # Two Wheeler Subtypes
    TWO_WHEELER_THIRD = "Third Party"
    TWO_WHEELER_COMP = "Comprehensive"
    TWO_WHEELER_OD = "Own Damage"
    
    # Travel Insurance Subtypes
    DOMESTIC_TRAVEL = "Domestic Travel"
    INTERNATIONAL_TRAVEL = "International Travel"
    STUDENT_TRAVEL = "Student Travel"
    
    # Home Insurance Subtypes
    HOME_BUILDING = "Building Insurance"
    HOME_CONTENTS = "Contents Insurance"
    HOME_COMPREHENSIVE = "Comprehensive Home"
    
    # Business Insurance Subtypes
    BUSINESS_PROPERTY = "Business Property"
    BUSINESS_LIABILITY = "Business Liability"
    BUSINESS_MARINE = "Marine Insurance"
    
    # Shop/Commercial Subtypes
    SHOP_PROPERTY = "Shop Property"
    SHOP_LIABILITY = "Shop Liability"
    SHOP_FIRE = "Fire Insurance"
    
    # Accident Insurance Subtypes
    PERSONAL_ACCIDENT_INSURANCE = "Personal Accident"
    GROUP_ACCIDENT = "Group Accident"
    
    # Term Insurance Subtypes
    PURE_TERM = "Pure Term"
    RETURN_OF_PREMIUM = "Return of Premium"
    INCREASING_TERM = "Increasing Term"

class CustomerInfo(BaseModel):
    customer_id: int
    customer_name: str
    customer_email: Optional[str] = None
    customer_phone: str
    customer_address: str

class PolicyDetails(BaseModel):
    policy_number: Optional[str] = None
    insurer_name: str = Field(..., min_length=2, max_length=100)
    plan_name: str = Field(..., min_length=2, max_length=200)
    sum_assured: float = Field(..., gt=0)
    premium_amount: Optional[float] = Field(None, gt=0)
    issue_date: date
    expiry_date: date
    premium_due_date: Optional[date] = None
    maturity_date: Optional[date] = None
    status: str = "Active"
    special_conditions: Optional[str] = None
    agent_notes: Optional[str] = None

class LifeInsuranceDetails(BaseModel):
    policy_term: int = Field(..., ge=1, le=100)  # years
    sum_assured: float = Field(..., gt=0)
    premium_payment_term: str = Field("Regular", regex="^(Regular|Single|Limited)$")
    riders: List[str] = Field(default_factory=list)
    medical_required: bool = True
    nominee_name: Optional[str] = None
    nominee_relationship: Optional[str] = None
    nominee_age: Optional[int] = Field(None, ge=18, le=100)

class HealthInsuranceDetails(BaseModel):
    sum_insured: float = Field(..., gt=0)
    policy_term: int = Field(1, ge=1, le=5)  # years
    deductible: Optional[float] = Field(None, ge=0)
    room_rent_limit: Optional[str] = None
    pre_existing_diseases: bool = False
    waiting_period: Optional[int] = None  # days
    family_members: List[Dict[str, Any]] = Field(default_factory=list)

class MotorInsuranceDetails(BaseModel):
    vehicle_type: str = Field(..., regex="^(2W|4W|CV)$")
    vehicle_make: str = Field(..., min_length=2, max_length=50)
    vehicle_model: str = Field(..., min_length=2, max_length=50)
    manufacture_year: int = Field(..., ge=1990, le=datetime.now().year + 1)
    registration_number: str = Field(..., min_length=5, max_length=20)
    cubic_capacity: int = Field(..., ge=50, le=10000)
    fuel_type: Optional[str] = Field(None, max_length=20)
    idv: Optional[float] = Field(None, gt=0)
    ncb_percent: float = Field(0.0, ge=0, le=50)
    previous_insurer: Optional[str] = None
    previous_policy_number: Optional[str] = None

class TwoWheelerDetails(BaseModel):
    vehicle_type: str = Field(..., regex="^(Motorcycle|Scooter|Electric Scooter|Moped)$")
    vehicle_make: str = Field(..., min_length=2, max_length=50)
    vehicle_model: str = Field(..., min_length=2, max_length=50)
    manufacture_year: int = Field(..., ge=1990, le=datetime.now().year + 1)
    registration_number: str = Field(..., min_length=5, max_length=20)
    engine_capacity: int = Field(..., ge=50, le=2000)
    fuel_type: Optional[str] = Field(None, max_length=20)
    vehicle_value: float = Field(..., gt=0)
    coverage_type: str = Field(..., regex="^(third_party|comprehensive|own_damage)$")
    policy_period: str = Field("1 year", regex="^(1 year|3 years|5 years)$")

class TravelInsuranceDetails(BaseModel):
    travel_type: str = Field(..., regex="^(Domestic|International|Student)$")
    destination_countries: List[str] = Field(default_factory=list)
    travel_duration: int = Field(..., ge=1, le=365)  # days
    trip_start_date: date
    trip_end_date: date
    coverage_amount: float = Field(..., gt=0)
    medical_coverage: bool = True
    trip_cancellation: bool = False
    lost_baggage: bool = False

class HomeInsuranceDetails(BaseModel):
    property_type: str = Field(..., regex="^(Apartment|House|Villa|Commercial)$")
    property_age: int = Field(..., ge=0, le=100)
    building_sum_insured: float = Field(..., gt=0)
    contents_sum_insured: float = Field(..., gt=0)
    total_area: float = Field(..., gt=0)  # sq ft
    location: str = Field(..., min_length=5, max_length=200)
    construction_type: Optional[str] = None
    security_features: List[str] = Field(default_factory=list)

class BusinessInsuranceDetails(BaseModel):
    business_type: str = Field(..., min_length=2, max_length=100)
    business_turnover: Optional[float] = Field(None, ge=0)
    num_employees: Optional[int] = Field(None, ge=1)
    property_value: Optional[float] = Field(None, ge=0)
    liability_cover: Optional[float] = Field(None, ge=0)
    business_location: str = Field(..., min_length=5, max_length=200)
    risk_type: str = Field(..., min_length=2, max_length=100)

class ShopCommercialDetails(BaseModel):
    shop_type: str = Field(..., min_length=2, max_length=100)
    shop_area: float = Field(..., gt=0)  # sq ft
    property_value: float = Field(..., gt=0)
    stock_value: Optional[float] = Field(None, ge=0)
    business_type: str = Field(..., min_length=2, max_length=100)
    location: str = Field(..., min_length=5, max_length=200)
    fire_safety_measures: List[str] = Field(default_factory=list)

class AccidentInsuranceDetails(BaseModel):
    coverage_amount: float = Field(..., gt=0)
    policy_term: int = Field(1, ge=1, le=5)  # years
    accident_type_coverage: List[str] = Field(..., min_items=1)
    death_benefit: Optional[float] = None
    disability_benefit: Optional[float] = None
    medical_expenses: Optional[float] = None

class TermInsuranceDetails(BaseModel):
    policy_term: int = Field(..., ge=5, le=40)  # years
    sum_assured: float = Field(..., gt=0)
    premium_payment_term: str = Field("Regular", regex="^(Regular|Single|Limited)$")
    return_of_premium: bool = False
    increasing_cover: bool = False
    critical_illness_rider: bool = False
    waiver_of_premium: bool = False

class AddPolicyRequest(BaseModel):
    customer: CustomerInfo
    insurance_category: InsuranceCategory
    policy_subtype: PolicySubType
    policy_details: PolicyDetails
    
    # Insurance type specific details
    life_insurance: Optional[LifeInsuranceDetails] = None
    health_insurance: Optional[HealthInsuranceDetails] = None
    motor_insurance: Optional[MotorInsuranceDetails] = None
    two_wheeler_insurance: Optional[TwoWheelerDetails] = None
    travel_insurance: Optional[TravelInsuranceDetails] = None
    home_insurance: Optional[HomeInsuranceDetails] = None
    business_insurance: Optional[BusinessInsuranceDetails] = None
    shop_commercial_insurance: Optional[ShopCommercialDetails] = None
    accident_insurance: Optional[AccidentInsuranceDetails] = None
    term_insurance: Optional[TermInsuranceDetails] = None

    @validator('expiry_date', pre=True, always=True)
    def validate_dates(cls, v, values):
        if 'policy_details' in values and 'issue_date' in values['policy_details']:
            issue_date = values['policy_details']['issue_date']
            if v <= issue_date:
                raise ValueError('Expiry date must be after issue date')
        return v

    @validator('*', pre=True)
    def validate_insurance_type_details(cls, v, values):
        insurance_category = values.get('insurance_category')
        
        # Define required fields for each insurance type
        required_fields = {
            InsuranceCategory.LIFE: ['life_insurance'],
            InsuranceCategory.HEALTH: ['health_insurance'],
            InsuranceCategory.MOTOR: ['motor_insurance'],
            InsuranceCategory.TWO_WHEELER: ['two_wheeler_insurance'],
            InsuranceCategory.TRAVEL: ['travel_insurance'],
            InsuranceCategory.HOME: ['home_insurance'],
            InsuranceCategory.BUSINESS: ['business_insurance'],
            InsuranceCategory.SHOP_COMMERCIAL: ['shop_commercial_insurance'],
            InsuranceCategory.ACCIDENT: ['accident_insurance'],
            InsuranceCategory.TERM: ['term_insurance']
        }
        
        if insurance_category and insurance_category in required_fields:
            required_field = required_fields[insurance_category][0]
            if not values.get(required_field):
                raise ValueError(f'{required_field} details are required for {insurance_category.value}')
        
        return v

class AddPolicyResponse(BaseModel):
    success: bool
    message: str
    policy_id: Optional[int] = None
    policy_number: Optional[str] = None
    premium_amount: Optional[float] = None
    coverage_details: Optional[Dict[str, Any]] = None

class PolicyTypeInfo(BaseModel):
    category: InsuranceCategory
    subtypes: List[PolicySubType]
    description: str
    required_fields: List[str]
    optional_fields: List[str]

class AvailablePolicyTypesResponse(BaseModel):
    policy_types: List[PolicyTypeInfo]
    total_categories: int

def get_available_policy_types() -> AvailablePolicyTypesResponse:
    """Get all available policy types with their subtypes and required fields"""
    
    policy_types = [
        PolicyTypeInfo(
            category=InsuranceCategory.LIFE,
            subtypes=[
                PolicySubType.TERM_LIFE,
                PolicySubType.WHOLE_LIFE,
                PolicySubType.ENDOWMENT,
                PolicySubType.MONEY_BACK,
                PolicySubType.ULIP
            ],
            description="Life insurance provides financial protection to your family",
            required_fields=["policy_term", "sum_assured", "nominee_name"],
            optional_fields=["riders", "medical_required"]
        ),
        PolicyTypeInfo(
            category=InsuranceCategory.HEALTH,
            subtypes=[
                PolicySubType.INDIVIDUAL_HEALTH,
                PolicySubType.FAMILY_FLOATER,
                PolicySubType.SENIOR_CITIZEN,
                PolicySubType.CRITICAL_ILLNESS,
                PolicySubType.PERSONAL_ACCIDENT
            ],
            description="Health insurance covers medical expenses",
            required_fields=["sum_insured", "policy_term"],
            optional_fields=["deductible", "family_members"]
        ),
        PolicyTypeInfo(
            category=InsuranceCategory.MOTOR,
            subtypes=[
                PolicySubType.THIRD_PARTY,
                PolicySubType.COMPREHENSIVE,
                PolicySubType.OWN_DAMAGE,
                PolicySubType.ZERO_DEPRECIATION,
                PolicySubType.ENGINE_PROTECT
            ],
            description="Motor insurance for vehicles",
            required_fields=["vehicle_type", "vehicle_make", "registration_number"],
            optional_fields=["idv", "ncb_percent", "previous_insurer"]
        ),
        PolicyTypeInfo(
            category=InsuranceCategory.TWO_WHEELER,
            subtypes=[
                PolicySubType.TWO_WHEELER_THIRD,
                PolicySubType.TWO_WHEELER_COMP,
                PolicySubType.TWO_WHEELER_OD
            ],
            description="Two wheeler insurance for motorcycles and scooters",
            required_fields=["vehicle_type", "vehicle_make", "registration_number", "coverage_type"],
            optional_fields=["engine_capacity", "policy_period", "vehicle_value"]
        ),
        PolicyTypeInfo(
            category=InsuranceCategory.TRAVEL,
            subtypes=[
                PolicySubType.DOMESTIC_TRAVEL,
                PolicySubType.INTERNATIONAL_TRAVEL,
                PolicySubType.STUDENT_TRAVEL
            ],
            description="Travel insurance for domestic and international trips",
            required_fields=["travel_type", "travel_duration", "coverage_amount"],
            optional_fields=["destination_countries", "trip_cancellation"]
        ),
        PolicyTypeInfo(
            category=InsuranceCategory.HOME,
            subtypes=[
                PolicySubType.HOME_BUILDING,
                PolicySubType.HOME_CONTENTS,
                PolicySubType.HOME_COMPREHENSIVE
            ],
            description="Home insurance for property and contents",
            required_fields=["property_type", "building_sum_insured", "location"],
            optional_fields=["contents_sum_insured", "security_features"]
        ),
        PolicyTypeInfo(
            category=InsuranceCategory.BUSINESS,
            subtypes=[
                PolicySubType.BUSINESS_PROPERTY,
                PolicySubType.BUSINESS_LIABILITY,
                PolicySubType.BUSINESS_MARINE
            ],
            description="Business insurance for commercial risks",
            required_fields=["business_type", "business_location"],
            optional_fields=["business_turnover", "num_employees", "property_value"]
        ),
        PolicyTypeInfo(
            category=InsuranceCategory.SHOP_COMMERCIAL,
            subtypes=[
                PolicySubType.SHOP_PROPERTY,
                PolicySubType.SHOP_LIABILITY,
                PolicySubType.SHOP_FIRE
            ],
            description="Shop and commercial insurance",
            required_fields=["shop_type", "shop_area", "location"],
            optional_fields=["stock_value", "fire_safety_measures"]
        ),
        PolicyTypeInfo(
            category=InsuranceCategory.ACCIDENT,
            subtypes=[
                PolicySubType.PERSONAL_ACCIDENT_INSURANCE,
                PolicySubType.GROUP_ACCIDENT
            ],
            description="Accident insurance for personal and group coverage",
            required_fields=["coverage_amount", "accident_type_coverage"],
            optional_fields=["death_benefit", "disability_benefit"]
        ),
        PolicyTypeInfo(
            category=InsuranceCategory.TERM,
            subtypes=[
                PolicySubType.PURE_TERM,
                PolicySubType.RETURN_OF_PREMIUM,
                PolicySubType.INCREASING_TERM
            ],
            description="Term insurance for pure protection",
            required_fields=["policy_term", "sum_assured"],
            optional_fields=["return_of_premium", "increasing_cover"]
        )
    ]
    
    return AvailablePolicyTypesResponse(
        policy_types=policy_types,
        total_categories=len(policy_types)
    )
