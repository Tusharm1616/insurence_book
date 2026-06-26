from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class LeadCreate(BaseModel):
    name: str
    phone: str
    email: Optional[str] = None
    insurance_type: str
    source: str = "Walk-in"
    status: str = "New"
    notes: Optional[str] = None
    follow_up_date: Optional[datetime] = None


class LeadUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    insurance_type: Optional[str] = None
    source: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None
    follow_up_date: Optional[datetime] = None


class LeadResponse(BaseModel):
    id: int
    agent_id: int
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    insurance_type: Optional[str] = None
    source: str
    status: str
    notes: Optional[str] = None
    follow_up_date: Optional[datetime] = None
    converted_customer_id: Optional[int] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class LeadConvertResponse(BaseModel):
    message: str
    customer_id: int
    lead_id: int
