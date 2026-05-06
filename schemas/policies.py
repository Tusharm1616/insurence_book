from pydantic import BaseModel
from typing import Optional
from datetime import date

class PolicyBase(BaseModel):
    customer_id: int
    policy_number: str
    policy_type: str
    insurer_name: str
    plan_name: str
    sum_assured: float
    premium_amount: float
    issue_date: date
    expiry_date: date
    premium_due_date: Optional[date] = None
    status: str = "Active"
    maturity_date: Optional[date] = None
    ncb_percent: Optional[float] = 0.0
    vehicle_reg_no: Optional[str] = None

class PolicyCreate(PolicyBase):
    pass

class PolicyResponse(PolicyBase):
    id: int
    agent_id: int

    class Config:
        from_attributes = True
