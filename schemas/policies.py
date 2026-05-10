from pydantic import BaseModel, Field
from typing import Optional
from datetime import date

class PolicyBase(BaseModel):
    customer_id: int
    policy_number: str
    policy_type: str  # Accept any string, not just enum values
    insurer_name: Optional[str] = None
    plan_name: Optional[str] = None
    sum_assured: Optional[float] = 0.0
    premium_amount: Optional[float] = 0.0
    issue_date: date
    expiry_date: date
    premium_due_date: Optional[date] = None
    status: str = "live"
    maturity_date: Optional[date] = None
    ncb_percent: Optional[float] = 0.0
    vehicle_reg_no: Optional[str] = None

class PolicyCreate(PolicyBase):
    pass

class PolicyResponse(PolicyBase):
    id: int
    agent_id: Optional[int] = None

    class Config:
        from_attributes = True
