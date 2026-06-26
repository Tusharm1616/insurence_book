from sqlalchemy import Column, String, Integer, ForeignKey, Text, DateTime, Date
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime


class Lead(Base):
    __tablename__ = "leads"

    id = Column(Integer, primary_key=True, index=True)
    agent_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(150), nullable=False)
    phone = Column(String(15))
    email = Column(String(100))
    insurance_type = Column(String(80))
    source = Column(String(50), default="Walk-in")
    status = Column(String(30), default="New")
    notes = Column(Text)
    follow_up_date = Column(DateTime, nullable=True)
    converted_customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    agent = relationship("User", foreign_keys=[agent_id])
