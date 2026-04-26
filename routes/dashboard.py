from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, and_
from typing import List
from datetime import date, timedelta

from database import get_db
from models.users import User
from models.policies import Policy
from models.customers import Customer
from schemas.dashboard import ExpiringCountResponse, ExpiringPolicyItem, ExpiringListResponse
from utils.auth import get_current_user

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])

@router.get("/expiring-count", response_model=ExpiringCountResponse)
async def get_expiring_count(
    days: int = Query(30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    current_date = date.today()
    max_date = current_date + timedelta(days=days)
    
    query = select(func.count(Policy.id)).where(
        and_(
            Policy.agent_id == current_user.id,
            Policy.status == 'live',
            Policy.expiry_date > current_date,
            Policy.expiry_date <= max_date
        )
    )
    result = await db.execute(query)
    count = result.scalar() or 0
    
    return ExpiringCountResponse(count=count, filter_days=days)

@router.get("/expiring-list", response_model=ExpiringListResponse)
async def get_expiring_list(
    days: int = Query(30, ge=1, le=365),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    current_date = date.today()
    max_date = current_date + timedelta(days=days)
    offset = (page - 1) * limit
    
    # Base query for data
    query = select(Policy, Customer).join(Customer, Policy.customer_id == Customer.id).where(
        and_(
            Policy.agent_id == current_user.id,
            Policy.status == 'live',
            Policy.expiry_date > current_date,
            Policy.expiry_date <= max_date
        )
    )
    
    # Get total count
    count_query = select(func.count(Policy.id)).where(
        and_(
            Policy.agent_id == current_user.id,
            Policy.status == 'live',
            Policy.expiry_date > current_date,
            Policy.expiry_date <= max_date
        )
    )
    count_result = await db.execute(count_query)
    total = count_result.scalar() or 0
    
    # Get paginated data
    query = query.order_by(Policy.expiry_date.asc()).offset(offset).limit(limit)
    result = await db.execute(query)
    
    items = []
    for policy, customer in result.all():
        days_remaining = (policy.expiry_date - current_date).days if policy.expiry_date else 0
        items.append(ExpiringPolicyItem(
            policy_id=policy.id,
            policy_number=policy.policy_number,
            policy_type=policy.policy_type,
            insurer_name=policy.insurer_name,
            premium_amount=policy.premium_amount,
            expiry_date=policy.expiry_date,
            days_remaining=days_remaining,
            customer_full_name=customer.full_name,
            customer_phone_number=customer.mobile_number
        ))
        
    return ExpiringListResponse(
        items=items,
        total=total,
        page=page,
        limit=limit
    )
