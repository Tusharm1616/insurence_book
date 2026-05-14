from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, and_, text, case
from typing import List, Dict
from datetime import date, timedelta

from database import get_db
from models.users import User
from models.policies import Policy
from models.customers import Customer
from schemas.dashboard import ExpiringCountResponse, ExpiringPolicyItem, ExpiringListResponse, ExpiredPolicyItem, ExpiredListResponse
from utils.auth import get_current_user

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])

# ── Helper: effective expiry date = end_date if set, else expiry_date ─────────
# Policies may have been saved with either column name depending on which
# endpoint created them. We COALESCE both so counts are always accurate.
def _eff_expiry(Policy):
    """SQLAlchemy expression: COALESCE(end_date, expiry_date)"""
    return case(
        (Policy.end_date.isnot(None), Policy.end_date),
        else_=Policy.expiry_date
    )


@router.get("/stats")
async def get_dashboard_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        agent_id = current_user.id

        # All customers
        all_customers = (await db.execute(
            select(func.count(Customer.id)).where(Customer.agent_id == agent_id)
        )).scalar() or 0

        # Active customers
        active_customers = (await db.execute(
            select(func.count(Customer.id)).where(
                Customer.agent_id == agent_id,
                Customer.status == 'active'
            )
        )).scalar() or 0

        # All policies
        all_policies = (await db.execute(
            select(func.count(Policy.id)).where(Policy.agent_id == agent_id)
        )).scalar() or 0

        # Use raw SQL for the date-based counts so COALESCE works cleanly
        expired_result = await db.execute(
            text("""
                SELECT COUNT(*) FROM policies
                WHERE agent_id = :agent_id
                  AND COALESCE(end_date, expiry_date) < CURRENT_DATE
                  AND status IN ('active', 'expired', 'live')
            """),
            {"agent_id": agent_id}
        )
        expired_policies = expired_result.scalar() or 0

        expiring_1m_result = await db.execute(
            text("""
                SELECT COUNT(*) FROM policies
                WHERE agent_id = :agent_id
                  AND COALESCE(end_date, expiry_date) >= CURRENT_DATE
                  AND COALESCE(end_date, expiry_date) <= CURRENT_DATE + INTERVAL '30 days'
                  AND LOWER(status) IN ('active', 'live')
            """),
            {"agent_id": agent_id}
        )
        expiring_1_month = expiring_1m_result.scalar() or 0

        expiring_2m_result = await db.execute(
            text("""
                SELECT COUNT(*) FROM policies
                WHERE agent_id = :agent_id
                  AND COALESCE(end_date, expiry_date) >= CURRENT_DATE
                  AND COALESCE(end_date, expiry_date) <= CURRENT_DATE + INTERVAL '60 days'
                  AND LOWER(status) IN ('active', 'live')
            """),
            {"agent_id": agent_id}
        )
        expiring_2_months = expiring_2m_result.scalar() or 0

        return {
            "all_customers": all_customers,
            "all_policies": all_policies,
            "expired_policies": expired_policies,
            "expiring_1_month": expiring_1_month,
            "expiring_2_months": expiring_2_months,
            "active_customers": active_customers,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch dashboard stats: {str(e)}")


@router.get("/expiring-count", response_model=ExpiringCountResponse)
async def get_expiring_count(
    days: int = Query(30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        text("""
            SELECT COUNT(*) FROM policies
            WHERE agent_id = :agent_id
              AND COALESCE(end_date, expiry_date) >= CURRENT_DATE
              AND COALESCE(end_date, expiry_date) <= CURRENT_DATE + CAST(:days || ' days' AS INTERVAL)
              AND LOWER(status) IN ('active', 'live')
        """),
        {"agent_id": current_user.id, "days": days}
    )
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

    # Use LEFT JOIN so policies without a customer still appear
    base = and_(
        Policy.agent_id == current_user.id,
        func.lower(Policy.status).in_(['live', 'active']),
        func.coalesce(Policy.end_date, Policy.expiry_date) >= current_date,
        func.coalesce(Policy.end_date, Policy.expiry_date) <= max_date,
    )

    total = (await db.execute(
        select(func.count(Policy.id)).where(base)
    )).scalar() or 0

    result = await db.execute(
        select(Policy, Customer)
        .outerjoin(Customer, Policy.customer_id == Customer.id)
        .where(base)
        .order_by(func.coalesce(Policy.end_date, Policy.expiry_date).asc())
        .offset(offset).limit(limit)
    )

    items = []
    for policy, customer in result.all():
        eff_date = policy.end_date or policy.expiry_date
        days_remaining = (eff_date - current_date).days if eff_date else 0
        items.append(ExpiringPolicyItem(
            policy_id=policy.id,
            policy_number=policy.policy_number or "",
            policy_type=policy.policy_type or "",
            insurer_name=policy.insurer_name,
            premium_amount=policy.premium_amount,
            expiry_date=eff_date,
            days_remaining=days_remaining,
            customer_full_name=customer.full_name if customer else "Unknown",
            customer_phone_number=customer.phone if customer else ""
        ))

    return ExpiringListResponse(items=items, total=total, page=page, limit=limit)


@router.get("/expired-count")
async def get_expired_count(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        text("""
            SELECT COUNT(*) FROM policies
            WHERE agent_id = :agent_id
              AND COALESCE(end_date, expiry_date) < CURRENT_DATE
        """),
        {"agent_id": current_user.id}
    )
    return {"count": result.scalar() or 0}


@router.get("/expired-list", response_model=ExpiredListResponse)
async def get_expired_list(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    current_date = date.today()
    offset = (page - 1) * limit

    base = and_(
        Policy.agent_id == current_user.id,
        func.coalesce(Policy.end_date, Policy.expiry_date) < current_date,
    )

    total = (await db.execute(
        select(func.count(Policy.id)).where(base)
    )).scalar() or 0

    result = await db.execute(
        select(Policy, Customer)
        .outerjoin(Customer, Policy.customer_id == Customer.id)
        .where(base)
        .order_by(func.coalesce(Policy.end_date, Policy.expiry_date).desc())
        .offset(offset).limit(limit)
    )

    items = []
    for policy, customer in result.all():
        eff_date = policy.end_date or policy.expiry_date
        days_overdue = (current_date - eff_date).days if eff_date else 0
        items.append(ExpiredPolicyItem(
            policy_id=policy.id,
            policy_number=policy.policy_number or "",
            policy_type=policy.policy_type or "",
            insurer_name=policy.insurer_name,
            premium_amount=policy.premium_amount,
            expiry_date=eff_date,
            days_overdue=days_overdue,
            customer_full_name=customer.full_name if customer else "Unknown",
            customer_phone_number=customer.phone if customer else ""
        ))

    return ExpiredListResponse(items=items, total=total, page=page, limit=limit)
