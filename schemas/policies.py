from pydantic import BaseModel
from typing import Optional
from datetime import date

class PolicyBase(BaseModel):
    customer_id: int
    policy_number: str
    insurance_type: str
    insurer_name: str
    plan_name: str
    sum_assured: float
    premium_amount: float
    issue_date: date
    expiry_date: date
    renewal_date: Optional[date] = None
    status: str = "Active"

class PolicyCreate(PolicyBase):
    pass

class PolicyResponse(PolicyBase):
    id: int

    class Config:
        from_attributes = True
