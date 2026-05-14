from sqlalchemy import Column, String, Date, ForeignKey, Text, Index, Integer, Float
from sqlalchemy.dialects.postgresql import NUMERIC
from sqlalchemy.orm import relationship
from database import Base


class Policy(Base):
    __tablename__ = "policies"

    id = Column(Integer, primary_key=True, index=True)
    agent_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    customer_id = Column(Integer, ForeignKey("customers.id", ondelete="CASCADE"))

    policy_number = Column(String(60), unique=True, nullable=False, index=True)
    policy_type = Column(String(60), nullable=False)
    insurer_name = Column(String(120))
    plan_name = Column(String(120))

    # ── Financial columns — use DB names exactly ──────────────────────────
    # The live DB has sum_assured (NOT sum_insured)
    sum_assured = Column(NUMERIC(14, 2))
    premium_amount = Column(NUMERIC(12, 2))
    payment_mode = Column(String(20))

    # ── Date columns ──────────────────────────────────────────────────────
    # The live DB has issue_date / expiry_date / premium_due_date / maturity_date
    issue_date = Column(Date)
    expiry_date = Column(Date)
    premium_due_date = Column(Date)
    maturity_date = Column(Date)

    # start_date / end_date added by migration — keep both for compatibility
    start_date = Column(Date)
    end_date = Column(Date)

    status = Column(String(20), default='active')

    # ── Extra columns ─────────────────────────────────────────────────────
    ncb_percent = Column(Float, default=0.0)
    vehicle_reg_no = Column(String(20))

    nominee_name = Column(String(120))
    nominee_relation = Column(String(60))
    notes = Column(Text)

    # Timestamps
    created_at = Column(Date, server_default='now()')
    updated_at = Column(Date, server_default='now()')

    # Relationships
    customer = relationship("Customer", back_populates="policies")
    agent = relationship("User", foreign_keys=[agent_id])


# Performance Indexes
Index('ix_policies_agent_status', Policy.agent_id, Policy.status)
Index('ix_policies_agent_type', Policy.agent_id, Policy.policy_type)
Index('ix_policies_customer_id', Policy.customer_id)
