from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, and_, text
from typing import List, Dict
from datetime import date, timedelta

from database import get_db
from models.users import User
from models.policies import Policy
from models.customers import Customer
from schemas.dashboard import ExpiringCountResponse, ExpiringPolicyItem, ExpiringListResponse, ExpiredPolicyItem, ExpiredListResponse
from utils.auth import get_current_user

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])

@router.get("/stats")
async def get_dashboard_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    print(f"DEBUG: Reached get_dashboard_stats for user: {current_user.email or current_user.username}")
    """
    Get dashboard statistics for the current agent.
    Returns counts for all customers, policies, expired policies, 
    expiring policies, and active customers.
    """
    
    try:
        agent_id = current_user.id
        
        # All customers count
        all_customers_result = await db.execute(
            select(func.count(Customer.id)).where(Customer.agent_id == agent_id)
        )
        all_customers = all_customers_result.scalar() or 0
        
        # Active customers count
        active_customers_result = await db.execute(
            select(func.count(Customer.id)).where(
                Customer.agent_id == agent_id,
                Customer.status == 'active'
            )
        )
        active_customers = active_customers_result.scalar() or 0
        
        # All policies count
        all_policies_result = await db.execute(
            select(func.count(Policy.id)).where(Policy.agent_id == agent_id)
        )
        all_policies = all_policies_result.scalar() or 0
        
        # Expired policies count (database logic)
        expired_policies_result = await db.execute(
            select(func.count(Policy.id)).where(
                Policy.agent_id == agent_id,
                Policy.end_date < func.current_date(),
                Policy.status.in_(['active', 'expired'])
            )
        )
        expired_policies = expired_policies_result.scalar() or 0
        
        # Expiring within 1 month count
        expiring_1_month_result = await db.execute(
            select(func.count(Policy.id)).where(
                Policy.agent_id == agent_id,
                Policy.end_date.between(
                    func.current_date(),
                    func.current_date() + text("INTERVAL '30 days'")
                ),
                Policy.status == 'active'
            )
        )
        expiring_1_month = expiring_1_month_result.scalar() or 0
        
        # Expiring within 2 months count
        expiring_2_months_result = await db.execute(
            select(func.count(Policy.id)).where(
                Policy.agent_id == agent_id,
                Policy.end_date.between(
                    func.current_date(),
                    func.current_date() + text("INTERVAL '60 days'")
                ),
                Policy.status == 'active'
            )
        )
        expiring_2_months = expiring_2_months_result.scalar() or 0
        
        return {
            "all_customers": all_customers,
            "all_policies": all_policies,
            "expired_policies": expired_policies,
            "expiring_1_month": expiring_1_month,
            "expiring_2_months": expiring_2_months,
            "active_customers": active_customers,
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch dashboard stats: {str(e)}"
        )

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
            func.lower(Policy.status).in_(['live', 'active']),
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
            func.lower(Policy.status).in_(['live', 'active']),
            Policy.expiry_date > current_date,
            Policy.expiry_date <= max_date
        )
    )
    
    # Get total count
    count_query = select(func.count(Policy.id)).where(
        and_(
            Policy.agent_id == current_user.id,
            func.lower(Policy.status).in_(['live', 'active']),
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

@router.get("/expired-count")
async def get_expired_count(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    current_date = date.today()
    query = select(func.count(Policy.id)).where(
        and_(
            Policy.agent_id == current_user.id,
            Policy.expiry_date < current_date,
        )
    )
    result = await db.execute(query)
    count = result.scalar() or 0
    return {"count": count}

@router.get("/expired-list", response_model=ExpiredListResponse)
async def get_expired_list(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    current_date = date.today()
    offset = (page - 1) * limit

    query = select(Policy, Customer).join(Customer, Policy.customer_id == Customer.id).where(
        and_(
            Policy.agent_id == current_user.id,
            Policy.expiry_date < current_date,
        )
    )

    count_query = select(func.count(Policy.id)).where(
        and_(
            Policy.agent_id == current_user.id,
            Policy.expiry_date < current_date,
        )
    )
    count_result = await db.execute(count_query)
    total = count_result.scalar() or 0

    query = query.order_by(Policy.expiry_date.desc()).offset(offset).limit(limit)
    result = await db.execute(query)

    items = []
    for policy, customer in result.all():
        days_overdue = (current_date - policy.expiry_date).days if policy.expiry_date else 0
        items.append(ExpiredPolicyItem(
            policy_id=policy.id,
            policy_number=policy.policy_number,
            policy_type=policy.policy_type,
            insurer_name=policy.insurer_name,
            premium_amount=policy.premium_amount,
            expiry_date=policy.expiry_date,
            days_overdue=days_overdue,
            customer_full_name=customer.full_name,
            customer_phone_number=customer.mobile_number
        ))

    return ExpiredListResponse(
        items=items,
        total=total,
        page=page,
        limit=limit
    )
