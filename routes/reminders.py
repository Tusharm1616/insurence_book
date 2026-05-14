from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import delete, update
from typing import List, Optional
from datetime import date, timedelta
from pydantic import BaseModel

from database import get_db
from models.users import User
from models.customers import Customer
from models.reminders import Reminder, ReminderType
from schemas.reminders import ReminderCreate, ReminderUpdate, ReminderResponse, ReminderCard, ReminderDashboardResponse
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
    try:
        # Use raw SQL to avoid SQLAlchemy column-not-found errors
        from sqlalchemy import text
        result = await db.execute(
            text("""
                SELECT id, full_name, phone, dob
                FROM customers
                WHERE agent_id = :agent_id
                  AND dob IS NOT NULL
            """),
            {"agent_id": current_user.id}
        )
        rows = result.fetchall()
        
        current_date = date.today()
        reminders = []
        
        for row in rows:
            try:
                cid, full_name, phone, dob = row
                if dob is None:
                    continue
                days, turning_age = get_days_until_next_anniversary(dob, current_date)
                reminders.append(ReminderItem(
                    customer_id=cid,
                    full_name=full_name or "Unknown",
                    phone=phone or "",
                    event_date=dob,
                    days_remaining=days,
                    turning_age=turning_age,
                    is_today=days == 0
                ))
            except Exception:
                continue
                
        reminders.sort(key=lambda x: x.days_remaining)
        return reminders
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch birthdays: {str(e)}")

@router.get("/anniversaries", response_model=List[ReminderItem])
async def get_anniversaries(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        from sqlalchemy import text
        # Check if anniversary_date column exists first
        col_check = await db.execute(
            text("""
                SELECT column_name FROM information_schema.columns
                WHERE table_name='customers' AND column_name='anniversary_date'
            """)
        )
        if not col_check.fetchone():
            # Column doesn't exist yet — add it and return empty
            await db.execute(text(
                "ALTER TABLE customers ADD COLUMN IF NOT EXISTS anniversary_date DATE"
            ))
            await db.commit()
            return []

        result = await db.execute(
            text("""
                SELECT id, full_name, phone, anniversary_date
                FROM customers
                WHERE agent_id = :agent_id
                  AND anniversary_date IS NOT NULL
            """),
            {"agent_id": current_user.id}
        )
        rows = result.fetchall()
        
        current_date = date.today()
        reminders = []
        
        for row in rows:
            try:
                cid, full_name, phone, ann_date = row
                if ann_date is None:
                    continue
                days, turning_years = get_days_until_next_anniversary(ann_date, current_date)
                reminders.append(ReminderItem(
                    customer_id=cid,
                    full_name=full_name or "Unknown",
                    phone=phone or "",
                    event_date=ann_date,
                    days_remaining=days,
                    turning_age=turning_years,
                    is_today=days == 0
                ))
            except Exception:
                continue
                
        reminders.sort(key=lambda x: x.days_remaining)
        return reminders
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch anniversaries: {str(e)}")

# Dedicated Reminder CRUD operations
@router.post("/", response_model=ReminderResponse)
async def create_reminder(
    reminder: ReminderCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_reminder = Reminder(
        agent_id=current_user.id,
        **reminder.dict()
    )
    db.add(db_reminder)
    await db.commit()
    await db.refresh(db_reminder)
    return db_reminder

@router.get("/", response_model=List[ReminderResponse])
async def get_reminders(
    skip: int = 0,
    limit: int = 100,
    reminder_type: Optional[ReminderType] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(Reminder).where(Reminder.agent_id == current_user.id, Reminder.is_active == True)
    
    if reminder_type:
        query = query.where(Reminder.reminder_type == reminder_type)
    
    query = query.offset(skip).limit(limit)
    result = await db.execute(query)
    reminders = result.scalars().all()
    return reminders

@router.get("/{reminder_id}", response_model=ReminderResponse)
async def get_reminder(
    reminder_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(Reminder).where(Reminder.id == reminder_id, Reminder.agent_id == current_user.id)
    )
    reminder = result.scalar_one_or_none()
    
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reminder not found"
        )
    return reminder

@router.put("/{reminder_id}", response_model=ReminderResponse)
async def update_reminder(
    reminder_id: int,
    reminder_update: ReminderUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(Reminder).where(Reminder.id == reminder_id, Reminder.agent_id == current_user.id)
    )
    reminder = result.scalar_one_or_none()
    
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reminder not found"
        )
    
    update_data = reminder_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(reminder, field, value)
    
    await db.commit()
    await db.refresh(reminder)
    return reminder

@router.delete("/{reminder_id}")
async def delete_reminder(
    reminder_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(Reminder).where(Reminder.id == reminder_id, Reminder.agent_id == current_user.id)
    )
    reminder = result.scalar_one_or_none()
    
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reminder not found"
        )
    
    await db.delete(reminder)
    await db.commit()
    return {"message": "Reminder deleted successfully"}

# Dashboard endpoint for the UI
@router.get("/dashboard/summary", response_model=ReminderDashboardResponse)
async def get_reminders_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    current_date = date.today()
    today = current_date
    next_week = current_date + timedelta(days=7)
    
    # Get customer birthdays
    customer_result = await db.execute(
        select(Customer).where(
            Customer.agent_id == current_user.id,
            Customer.dob.isnot(None)
        )
    )
    customers = customer_result.scalars().all()
    
    today_birthdays = []
    upcoming_birthdays = []
    
    for customer in customers:
        days, turning_age = get_days_until_next_anniversary(customer.dob, current_date)
        reminder_date = customer.dob.replace(year=current_date.year)
        if reminder_date < current_date:
            reminder_date = reminder_date.replace(year=current_date.year + 1)
        
        card = ReminderCard(
            id=customer.id,
            person_name=customer.full_name,
            phone_number=customer.phone,
            reminder_date=reminder_date,
            reminder_type=ReminderType.BIRTHDAY,
            title="Birthday",
            days_until=days,
            is_today=days == 0
        )
        
        if days == 0:
            today_birthdays.append(card)
        elif 1 <= days <= 7:
            upcoming_birthdays.append(card)
    
    # Get customer anniversaries
    today_anniversaries = []
    upcoming_anniversaries = []
    
    for customer in customers:
        if customer.anniversary_date:
            days, turning_years = get_days_until_next_anniversary(customer.anniversary_date, current_date)
            reminder_date = customer.anniversary_date.replace(year=current_date.year)
            if reminder_date < current_date:
                reminder_date = reminder_date.replace(year=current_date.year + 1)
            
            card = ReminderCard(
                id=customer.id,
                person_name=customer.full_name,
                phone_number=customer.phone,
                reminder_date=reminder_date,
                reminder_type=ReminderType.ANNIVERSARY,
                title="Anniversary",
                days_until=days,
                is_today=days == 0
            )
            
            if days == 0:
                today_anniversaries.append(card)
            elif 1 <= days <= 7:
                upcoming_anniversaries.append(card)
    
    # Get dedicated reminders
    dedicated_result = await db.execute(
        select(Reminder).where(
            Reminder.agent_id == current_user.id,
            Reminder.is_active == True,
            Reminder.reminder_date.between(today, next_week)
        )
    )
    dedicated_reminders = dedicated_result.scalars().all()
    
    for reminder in dedicated_reminders:
        days = (reminder.reminder_date - current_date).days
        card = ReminderCard(
            id=reminder.id,
            person_name=reminder.person_name,
            phone_number=reminder.phone_number,
            reminder_date=reminder.reminder_date,
            reminder_type=reminder.reminder_type,
            title=reminder.title,
            days_until=days,
            is_today=days == 0
        )
        
        if reminder.reminder_type == ReminderType.BIRTHDAY:
            if days == 0:
                today_birthdays.append(card)
            elif 1 <= days <= 7:
                upcoming_birthdays.append(card)
        elif reminder.reminder_type == ReminderType.ANNIVERSARY:
            if days == 0:
                today_anniversaries.append(card)
            elif 1 <= days <= 7:
                upcoming_anniversaries.append(card)
    
    # Sort all lists by days_until
    today_birthdays.sort(key=lambda x: x.person_name)
    upcoming_birthdays.sort(key=lambda x: x.days_until)
    today_anniversaries.sort(key=lambda x: x.person_name)
    upcoming_anniversaries.sort(key=lambda x: x.days_until)
    
    return ReminderDashboardResponse(
        today_birthdays=today_birthdays,
        upcoming_birthdays=upcoming_birthdays,
        today_anniversaries=today_anniversaries,
        upcoming_anniversaries=upcoming_anniversaries
    )
