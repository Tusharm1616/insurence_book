from sqlalchemy import Column, Integer, String, Date, Float, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    agent_id = Column(Integer, ForeignKey("users.id"))
    
    # Personal Details
    full_name = Column(String)
    mobile_number = Column(String)
    email = Column(String, nullable=True)
    state = Column(String)
    city = Column(String)
    address = Column(String)
    dob = Column(Date, nullable=True)
    anniversary_date = Column(Date, nullable=True)
    
    # Health/Personal Info
    gender = Column(String, nullable=True)
    height = Column(String, nullable=True)
    weight_kg = Column(Float, nullable=True)
    education = Column(String, nullable=True)
    marital_status = Column(String, nullable=True)
    
    # Business/Job
    business_job_type = Column(String, nullable=True)
    business_job_name = Column(String, nullable=True)
    duty_type = Column(String, nullable=True)
    annual_income = Column(Float, nullable=True)
    pan_no = Column(String, nullable=True)
    gst_no = Column(String, nullable=True)
    
    # Status
    is_active = Column(Integer, default=1) # 1 for active, 0 for inactive
    
    # Relationships
    user = relationship("User", back_populates="customer_profile", foreign_keys=[user_id])
    agent = relationship("User", back_populates="managed_customers", foreign_keys=[agent_id])
    policies = relationship("Policy", back_populates="customer")
