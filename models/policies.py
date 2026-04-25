from sqlalchemy import Column, Integer, String, Date, Float, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class Policy(Base):
    __tablename__ = "policies"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id"))
    
    policy_number = Column(String, unique=True, index=True)
    insurance_type = Column(String) # Life, Health, Motor, etc.
    insurer_name = Column(String)
    plan_name = Column(String)
    
    sum_assured = Column(Float)
    premium_amount = Column(Float)
    
    issue_date = Column(Date)
    expiry_date = Column(Date)
    renewal_date = Column(Date, nullable=True)
    
    status = Column(String, default="Active") # Active, Expired, Lapsed
    
    # Relationships
    customer = relationship("Customer", back_populates="policies")
