from sqlalchemy import Column, Integer, String, Date, Float, ForeignKey, Index, text
from sqlalchemy.orm import relationship
from database import Base

class Policy(Base):
    __tablename__ = "policies"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id", ondelete="CASCADE"))
    agent_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    
    policy_number = Column(String(100), unique=True, index=True, nullable=False)
    policy_type = Column(String(20), nullable=False) # Life, Health, Motor, etc.
    status = Column(String(30), nullable=False) # live, lapsed, matured, paidup, premium holiday, expired
    insurer_name = Column(String(100))
    plan_name = Column(String) # Existing field, keep it
    
    premium_amount = Column(Float)
    premium_due_date = Column(Date)
    
    issue_date = Column(Date) # Existing field
    expiry_date = Column(Date)
    maturity_date = Column(Date)
    
    sum_assured = Column(Float)
    ncb_percent = Column(Float, default=0.0)
    vehicle_reg_no = Column(String(20))
    
    # Relationships
    customer = relationship("Customer", back_populates="policies")
    agent = relationship("User", foreign_keys=[agent_id])

# Performance Indexes (SQLAlchemy syntax for partial indexes might be complex, 
# but we can create the basic ones here, and execute raw SQL for partials in main.py)
Index('ix_policies_agent_status', Policy.agent_id, Policy.status)
Index('ix_policies_agent_type', Policy.agent_id, Policy.policy_type)
