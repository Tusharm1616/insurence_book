from sqlalchemy import Column, Integer, String, Enum, ForeignKey
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
    
    # Relationships
    managed_customers = relationship("Customer", back_populates="agent", foreign_keys="[Customer.agent_id]")
    customer_profile = relationship("Customer", back_populates="user", foreign_keys="[Customer.user_id]", uselist=False)
