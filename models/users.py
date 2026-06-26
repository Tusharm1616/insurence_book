from sqlalchemy import Column, String, Enum, ForeignKey, Integer, Text
from sqlalchemy.orm import relationship
import enum
from database import Base

class UserRole(str, enum.Enum):
    AGENT = "agent"
    CUSTOMER = "customer"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True) # Mobile or ID
    email = Column(String, unique=True, index=True, nullable=True)
    full_name = Column(String)
    hashed_password = Column(String)
    role = Column(String, default=UserRole.AGENT)
    phone = Column(String, nullable=True)
    license_no = Column(String, nullable=True)

    # Bank details
    upi_id = Column(String, nullable=True)
    bank_name = Column(String, nullable=True)
    account_number = Column(String, nullable=True)
    ifsc_code = Column(String, nullable=True)
    branch_name = Column(String, nullable=True)
    qr_code_url = Column(Text, nullable=True)
    
    # Relationships
    managed_customers = relationship("Customer", back_populates="agent", foreign_keys="[Customer.agent_id]")
