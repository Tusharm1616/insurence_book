from pydantic import BaseModel
from typing import List, Optional
from datetime import date

class ExpiringCountResponse(BaseModel):
    count: int
    filter_days: int

class ExpiringPolicyItem(BaseModel):
    policy_id: int
    policy_number: str
    policy_type: str
    insurer_name: Optional[str] = None
    premium_amount: Optional[float] = None
    expiry_date: Optional[date] = None
    days_remaining: int
    customer_full_name: str
    customer_phone_number: str

    class Config:
        from_attributes = True

class ExpiringListResponse(BaseModel):
    items: List[ExpiringPolicyItem]
    total: int
    page: int
    limit: int
