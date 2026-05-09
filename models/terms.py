from sqlalchemy import Column, Integer, String, JSON, DateTime
from sqlalchemy.sql import func
from database import Base

class TermsConditions(Base):
    __tablename__ = "terms_conditions"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), default="Terms and Conditions")
    version = Column(String(50), default="1.0.0")
    content = Column(JSON, nullable=False) # Stores the 14 sections
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
