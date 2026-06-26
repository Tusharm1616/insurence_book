import uuid
from sqlalchemy import (
    Column, String, Date, ForeignKey, Text, Integer,
    Boolean, Numeric, TIMESTAMP
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class PolicyV2(Base):
    __tablename__ = "policies_v2"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    customer_id = Column(Integer, ForeignKey("customers.id", ondelete="CASCADE"))
    agent_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))

    policy_number = Column(String(60), unique=True, nullable=False, index=True)
    insurance_company = Column(String(150), nullable=True)
    insurance_type = Column(String(50), nullable=False, default="Other")
    # Values: Life, Motor, Health, Travel, Other

    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)

    # Financials
    total_amount = Column(Numeric(10, 2), nullable=True)
    discount_amount = Column(Numeric(10, 2), default=0)
    final_amount = Column(Numeric(10, 2), nullable=True)

    # Payment
    payment_mode = Column(String(20), nullable=True)  # Cash/Online/Cheque/EMI
    payment_date = Column(Date, nullable=True)

    # Inspection
    inspection_date = Column(Date, nullable=True)
    inspection_status = Column(String(20), default="NA")  # Pending/Passed/Failed/NA

    # Claims
    claim_status = Column(String(20), default="No Claim")  # No Claim/Claimed/Pending
    claim_amount = Column(Numeric(10, 2), default=0)
    claim_notes = Column(Text, nullable=True)

    # Referral & Commission
    ref_by = Column(String(150), nullable=True)
    commission_percent = Column(Numeric(5, 2), default=0)
    commission_amount = Column(Numeric(10, 2), default=0)

    # Documents
    policy_pdf_url = Column(String(500), nullable=True)
    last_year_policy_pdf_url = Column(String(500), nullable=True)

    # Status
    is_active = Column(Boolean, default=True)

    # Timestamps
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

    # Relationships
    customer = relationship("Customer", backref="policies_v2")
    agent = relationship("User", foreign_keys=[agent_id])
