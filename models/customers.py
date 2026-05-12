from sqlalchemy import Column, String, Date, ForeignKey, Text, Integer
from sqlalchemy.orm import relationship
from database import Base

class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    agent_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    
    # Personal Details
    full_name = Column(String(150), nullable=False)
    phone = Column(String(15))
    email = Column(String(100))
    dob = Column(Date)
    address = Column(Text)
    city = Column(String(80))
    state = Column(String(80))
    pincode = Column(String(10))
    status = Column(String(20), default='active')  # 'active' | 'inactive'
    
    # Timestamps
    created_at = Column(Date, server_default='now()')
    updated_at = Column(Date, server_default='now()')
    
    # Relationships
    agent = relationship("User", back_populates="managed_customers", foreign_keys=[agent_id])
    policies = relationship("Policy", back_populates="customer")
