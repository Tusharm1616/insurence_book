from sqlalchemy import Column, Integer, String, Date, Float, ForeignKey, Boolean, Text, JSON
from sqlalchemy.orm import relationship
from database import Base
import enum

class MotorInsuranceType(str, enum.Enum):
    THIRD_PARTY = "third_party"
    COMPREHENSIVE = "comprehensive"
    OWN_DAMAGE = "own_damage"
    ZERO_DEPRECIATION = "zero_depreciation"
    ENGINE_PROTECT = "engine_protect"

class VehicleType(str, enum.Enum):
    TWO_WHEELER = "2W"
    FOUR_WHEELER = "4W"
    COMMERCIAL_VEHICLE = "CV"

class MotorInsurancePolicy(Base):
    __tablename__ = "motor_insurance_policies"

    id = Column(Integer, primary_key=True, index=True)
    policy_id = Column(Integer, ForeignKey("policies.id", ondelete="CASCADE"))
    agent_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    customer_id = Column(Integer, ForeignKey("customers.id", ondelete="CASCADE"))
    
    # Insurance Type
    insurance_type = Column(String(50), nullable=False, default=MotorInsuranceType.COMPREHENSIVE)
    
    # Vehicle Details
    vehicle_type = Column(String(10), nullable=False)  # 2W, 4W, CV
    vehicle_make = Column(String(100), nullable=False)
    vehicle_model = Column(String(100), nullable=False)
    vehicle_variant = Column(String(100))
    manufacture_year = Column(Integer, nullable=False)
    registration_number = Column(String(20), unique=True, nullable=False)
    cubic_capacity = Column(Integer, nullable=False)  # CC
    fuel_type = Column(String(20))  # Petrol, Diesel, CNG, Electric
    
    # Insurance Details
    idv = Column(Float, nullable=False)  # Insured Declared Value
    ncb_percent = Column(Float, default=0.0)  # No Claim Bonus
    previous_policy_number = Column(String(100))
    previous_insurer = Column(String(100))
    policy_expiry_date = Column(Date)
    
    # Coverage Details (JSON for flexible storage)
    coverage_details = Column(JSON)  # Store specific coverage based on type
    
    # Add-ons
    zero_depreciation = Column(Boolean, default=False)
    engine_protection = Column(Boolean, default=False)
    return_to_invoice = Column(Boolean, default=False)
    roadside_assistance = Column(Boolean, default=False)
    consumable_cover = Column(Boolean, default=False)
    personal_accident_cover = Column(Boolean, default=True)
    passenger_cover = Column(Boolean, default=False)
    driver_cover = Column(Boolean, default=False)
    
    # Premium Details
    base_premium = Column(Float)
    third_party_premium = Column(Float)
    own_damage_premium = Column(Float)
    addons_premium = Column(Float)
    net_premium = Column(Float)
    gst_amount = Column(Float)
    final_premium = Column(Float)
    
    # Policy Dates
    issue_date = Column(Date, nullable=False)
    expiry_date = Column(Date, nullable=False)
    
    # Additional Benefits (from image)
    cashless_garage_network = Column(Boolean, default=True)
    fast_claim_settlement = Column(Boolean, default=True)
    roadside_assistance_24x7 = Column(Boolean, default=True)
    personal_accident_cover_24x7 = Column(Boolean, default=True)
    hassle_free_process = Column(Boolean, default=True)
    
    # Claim Details
    claim_history = Column(JSON)  # Store previous claims
    claim_free_years = Column(Integer, default=0)
    
    # Status
    is_active = Column(Boolean, default=True)
    is_renewed = Column(Boolean, default=False)
    
    # Additional Notes
    special_conditions = Column(Text)
    agent_notes = Column(Text)
    
    # Relationships
    policy = relationship("Policy", foreign_keys=[policy_id])
    agent = relationship("User", foreign_keys=[agent_id])
    customer = relationship("Customer", foreign_keys=[customer_id])
    
    def __repr__(self):
        return f"<MotorInsurancePolicy(id={self.id}, type={self.insurance_type}, reg_no={self.registration_number})>"

class MotorInsuranceQuote(Base):
    __tablename__ = "motor_insurance_quotes"
    
    id = Column(Integer, primary_key=True, index=True)
    agent_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    customer_id = Column(Integer, ForeignKey("customers.id", ondelete="CASCADE"))
    
    # Quote Details
    quote_number = Column(String(100), unique=True, nullable=False)
    insurance_type = Column(String(50), nullable=False)
    
    # Vehicle Details (same as policy but for quotes)
    vehicle_type = Column(String(10), nullable=False)
    vehicle_make = Column(String(100), nullable=False)
    vehicle_model = Column(String(100), nullable=False)
    manufacture_year = Column(Integer, nullable=False)
    registration_number = Column(String(20))
    cubic_capacity = Column(Integer, nullable=False)
    fuel_type = Column(String(20))
    
    # Premium Calculation
    idv = Column(Float, nullable=False)
    ncb_percent = Column(Float, default=0.0)
    base_premium = Column(Float)
    third_party_premium = Column(Float)
    own_damage_premium = Column(Float)
    addons_premium = Column(Float)
    net_premium = Column(Float)
    gst_amount = Column(Float)
    final_premium = Column(Float)
    
    # Add-ons Selected
    selected_addons = Column(JSON)
    
    # Quote Status
    status = Column(String(20), default="pending")  # pending, accepted, rejected, expired
    valid_until = Column(Date)
    
    # Timestamps
    created_at = Column(Date)
    updated_at = Column(Date)
    
    # Relationships
    agent = relationship("User", foreign_keys=[agent_id])
    customer = relationship("Customer", foreign_keys=[customer_id])
    
    def __repr__(self):
        return f"<MotorInsuranceQuote(id={self.id}, quote_no={self.quote_number}, type={self.insurance_type})>"
