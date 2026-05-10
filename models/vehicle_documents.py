from sqlalchemy import Column, Integer, String, Date, Boolean, DateTime, ForeignKey, Text, Float
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime


class VehicleDocument(Base):
    __tablename__ = "vehicle_documents"

    id = Column(Integer, primary_key=True, index=True)

    # Agent who owns this record
    agent_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)

    # Optional customer link
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True, index=True)

    # Vehicle Info
    vehicle_number   = Column(String(20), nullable=False)
    vehicle_type     = Column(String(50), nullable=False)   # Car, Bike, Truck, Bus, Other
    vehicle_model    = Column(String(100), nullable=False)
    manufacturer     = Column(String(100), nullable=False)
    fuel_type        = Column(String(30), nullable=False)   # Petrol, Diesel, CNG, Electric, Hybrid
    registration_year = Column(Integer, nullable=True)

    # Document Expiry Dates
    insurance_expiry = Column(Date, nullable=True)
    puc_expiry       = Column(Date, nullable=True)
    rc_expiry        = Column(Date, nullable=True)
    license_expiry   = Column(Date, nullable=True)
    fitness_expiry   = Column(Date, nullable=True)

    # Reminder tracking
    reminder_sent = Column(Boolean, default=False)
    notes         = Column(Text, nullable=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    agent    = relationship("User", foreign_keys=[agent_id])
    customer = relationship("Customer", foreign_keys=[customer_id])
