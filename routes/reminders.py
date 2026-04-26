from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List, Optional
from datetime import date, timedelta
from pydantic import BaseModel

from database import get_db
from models.users import User
from models.customers import Customer
from utils.auth import get_current_user

router = APIRouter(prefix="/api/reminders", tags=["Reminders"])

class ReminderItem(BaseModel):
    customer_id: int
    full_name: str
    phone: str
    event_date: date
    days_remaining: int
    turning_age: Optional[int] = None
    is_today: bool

    class Config:
        from_attributes = True

def get_days_until_next_anniversary(start_date: date, current_date: date):
    try:
        next_date = start_date.replace(year=current_date.year)
    except ValueError:
        # Leap year handling (Feb 29)
        next_date = start_date.replace(year=current_date.year, month=2, day=28)
        
    if next_date < current_date:
        try:
            next_date = next_date.replace(year=current_date.year + 1)
        except ValueError:
            next_date = next_date.replace(year=current_date.year + 1, month=2, day=28)
            
    days_remaining = (next_date - current_date).days
    turning_years = next_date.year - start_date.year
    
    return days_remaining, turning_years

@router.get("/birthdays", response_model=List[ReminderItem])
async def get_birthdays(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(Customer).where(Customer.agent_id == current_user.id, Customer.dob.isnot(None))
    )
    customers = result.scalars().all()
    
    current_date = date.today()
    reminders = []
    
    for c in customers:
        days, turning_age = get_days_until_next_anniversary(c.dob, current_date)
        if days <= 30:
            reminders.append(ReminderItem(
                customer_id=c.id,
                full_name=c.full_name,
                phone=c.mobile_number,
                event_date=c.dob,
                days_remaining=days,
                turning_age=turning_age,
                is_today=days == 0
            ))
            
    # Sort by days remaining
    reminders.sort(key=lambda x: x.days_remaining)
    return reminders

@router.get("/anniversaries", response_model=List[ReminderItem])
async def get_anniversaries(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(Customer).where(Customer.agent_id == current_user.id, Customer.anniversary_date.isnot(None))
    )
    customers = result.scalars().all()
    
    current_date = date.today()
    reminders = []
    
    for c in customers:
        days, turning_years = get_days_until_next_anniversary(c.anniversary_date, current_date)
        if days <= 30:
            reminders.append(ReminderItem(
                customer_id=c.id,
                full_name=c.full_name,
                phone=c.mobile_number,
                event_date=c.anniversary_date,
                days_remaining=days,
                turning_age=turning_years, # Usually anniversary year, can be ignored in UI
                is_today=days == 0
            ))
            
    # Sort by days remaining
    reminders.sort(key=lambda x: x.days_remaining)
    return reminders
