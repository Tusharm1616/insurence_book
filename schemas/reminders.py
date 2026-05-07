from pydantic import BaseModel
from typing import Optional
from datetime import date
from models.reminders import ReminderType

class ReminderBase(BaseModel):
    title: str
    reminder_type: ReminderType = ReminderType.BIRTHDAY
    person_name: str
    phone_number: Optional[str] = None
    reminder_date: date
    notes: Optional[str] = None
    is_active: bool = True
    notify_whatsapp: bool = True
    notify_call: bool = False
    days_before: int = 0
    customer_id: Optional[int] = None

class ReminderCreate(ReminderBase):
    pass

class ReminderUpdate(BaseModel):
    title: Optional[str] = None
    reminder_type: Optional[ReminderType] = None
    person_name: Optional[str] = None
    phone_number: Optional[str] = None
    reminder_date: Optional[date] = None
    notes: Optional[str] = None
    is_active: Optional[bool] = None
    notify_whatsapp: Optional[bool] = None
    notify_call: Optional[bool] = None
    days_before: Optional[int] = None
    customer_id: Optional[int] = None

class ReminderResponse(ReminderBase):
    id: int
    agent_id: int
    
    class Config:
        from_attributes = True

class ReminderListResponse(BaseModel):
    reminders: list[ReminderResponse]
    total: int

# Special schemas for the UI requirements
class ReminderCard(BaseModel):
    id: int
    person_name: str
    phone_number: Optional[str]
    reminder_date: date
    reminder_type: ReminderType
    title: str
    days_until: int  # Days until the event
    is_today: bool   # Whether the event is today
    
    class Config:
        from_attributes = True

class ReminderDashboardResponse(BaseModel):
    today_birthdays: list[ReminderCard]
    upcoming_birthdays: list[ReminderCard]
    today_anniversaries: list[ReminderCard]
    upcoming_anniversaries: list[ReminderCard]
