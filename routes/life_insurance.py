from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import text, func, literal
from typing import List, Optional
from datetime import date, timedelta
from pydantic import BaseModel

from database import get_db
from models.users import User
from models.policies import Policy
from models.customers import Customer
from utils.auth import get_current_user

router = APIRouter(prefix="/api/life-insurance", tags=["Life Insurance"])

class LifeReportSummary(BaseModel):
    live: int
    premium_holiday: int
    premium_paidup: int
    upcoming_maturity: int
    matured: int
    lapsed: int

class LifePolicyItem(BaseModel):
    policy_id: int
    policy_number: str
    insurer_name: Optional[str] = None
    status: str
    premium_amount: Optional[float] = None
    premium_due_date: Optional[date] = None
    maturity_date: Optional[date] = None
    sum_assured: Optional[float] = None
    customer_full_name: str
    customer_phone_number: str

class LifePolicyListResponse(BaseModel):
    items: List[LifePolicyItem]
    total: int
    page: int
    limit: int

@router.get("/report-summary", response_model=LifeReportSummary)
async def get_report_summary(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    current_date = date.today()
    max_maturity = current_date + timedelta(days=90)
    
    # Conditional aggregation
    query = text("""
        SELECT
            COUNT(*) FILTER (WHERE status = 'live') as live_count,
            COUNT(*) FILTER (WHERE status = 'premium holiday') as holiday_count,
            COUNT(*) FILTER (WHERE status = 'paidup') as paidup_count,
            COUNT(*) FILTER (WHERE status = 'live' AND maturity_date >= :current_date AND maturity_date <= :max_maturity) as upcoming_maturity_count,
            COUNT(*) FILTER (WHERE status = 'matured') as matured_count,
            COUNT(*) FILTER (WHERE status = 'lapsed') as lapsed_count
        FROM policies
        WHERE agent_id = :agent_id AND policy_type ILIKE 'life%'
    """)
    
    result = await db.execute(query, {
        "agent_id": current_user.id,
        "current_date": current_date,
        "max_maturity": max_maturity
    })
    
    row = result.fetchone()
    
    return LifeReportSummary(
        live=row[0] or 0,
        premium_holiday=row[1] or 0,
        premium_paidup=row[2] or 0,
        upcoming_maturity=row[3] or 0,
        matured=row[4] or 0,
        lapsed=row[5] or 0
    )

@router.get("/policies", response_model=LifePolicyListResponse)
async def get_life_policies(
    filter: str = Query(..., description="live, lapsed, matured, paidup, premium holiday, upcoming maturity"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    valid_filters = ['live', 'lapsed', 'matured', 'paidup', 'premium holiday', 'upcoming maturity']
    if filter not in valid_filters:
        raise HTTPException(status_code=400, detail="Invalid filter")
        
    offset = (page - 1) * limit
    current_date = date.today()
    max_maturity = current_date + timedelta(days=90)
    
    # Build base conditions
    base_conditions = [
        Policy.agent_id == current_user.id,
        Policy.policy_type.ilike('life%'),
    ]

    # Filter-specific conditions
    if filter == 'upcoming maturity':
        base_conditions.append(Policy.status == 'live')
        base_conditions.append(Policy.maturity_date.between(current_date, max_maturity))
    else:
        base_conditions.append(Policy.status == filter)

    # Query data
    query = select(Policy, Customer).join(Customer, Policy.customer_id == Customer.id).where(*base_conditions)
    
    # Count total
    count_query = select(func.count(Policy.id)).join(Customer, Policy.customer_id == Customer.id).where(*base_conditions)
    count_result = await db.execute(count_query)
    total = count_result.scalar() or 0
    
    # Get paginated data (order by created_at desc is requested, but we don't have created_at. We'll use id desc)
    query = query.order_by(Policy.id.desc()).offset(offset).limit(limit)
    result = await db.execute(query)
    
    items = []
    for policy, customer in result.all():
        items.append(LifePolicyItem(
            policy_id=policy.id,
            policy_number=policy.policy_number,
            insurer_name=policy.insurer_name,
            status=policy.status,
            premium_amount=policy.premium_amount,
            premium_due_date=policy.premium_due_date,
            maturity_date=policy.maturity_date,
            sum_assured=policy.sum_assured,
            customer_full_name=customer.full_name,
            customer_phone_number=customer.mobile_number
        ))
        
    return LifePolicyListResponse(
        items=items,
        total=total,
        page=page,
        limit=limit
    )
