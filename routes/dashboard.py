from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, and_, text, case, literal, union_all, String
from typing import List, Dict
from datetime import date, timedelta
import uuid

from database import get_db
from models.users import User
from models.policies import Policy
from models.policy_v2 import PolicyV2
from models.customers import Customer
from schemas.dashboard import ExpiringCountResponse, ExpiringPolicyItem, ExpiringListResponse, ExpiredPolicyItem, ExpiredListResponse
from utils.auth import get_current_user

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])

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
        all_policies_v1 = (await db.execute(
            select(func.count(Policy.id)).where(Policy.agent_id == agent_id)
        )).scalar() or 0
        all_policies_v2 = (await db.execute(
            select(func.count(PolicyV2.id)).where(PolicyV2.agent_id == agent_id)
        )).scalar() or 0
        all_policies = all_policies_v1 + all_policies_v2

        # Expired Policies
        expired_result = await db.execute(
            text("""
                SELECT COUNT(*) FROM policies
                WHERE agent_id = :agent_id
                  AND COALESCE(end_date, expiry_date) < CURRENT_DATE
                  AND status IN ('active', 'expired', 'live')
            """),
            {"agent_id": agent_id}
        )
        expired_v2_result = await db.execute(
            text("""
                SELECT COUNT(*) FROM policies_v2
                WHERE agent_id = :agent_id
                  AND end_date < CURRENT_DATE
            """),
            {"agent_id": agent_id}
        )
        expired_policies = (expired_result.scalar() or 0) + (expired_v2_result.scalar() or 0)

        # Expiring in 1 month
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
        expiring_1m_v2_result = await db.execute(
            text("""
                SELECT COUNT(*) FROM policies_v2
                WHERE agent_id = :agent_id
                  AND end_date >= CURRENT_DATE
                  AND end_date <= CURRENT_DATE + INTERVAL '30 days'
                  AND is_active = true
            """),
            {"agent_id": agent_id}
        )
        expiring_1_month = (expiring_1m_result.scalar() or 0) + (expiring_1m_v2_result.scalar() or 0)

        # Expiring in 2 months
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
        expiring_2m_v2_result = await db.execute(
            text("""
                SELECT COUNT(*) FROM policies_v2
                WHERE agent_id = :agent_id
                  AND end_date >= CURRENT_DATE
                  AND end_date <= CURRENT_DATE + INTERVAL '60 days'
                  AND is_active = true
            """),
            {"agent_id": agent_id}
        )
        expiring_2_months = (expiring_2m_result.scalar() or 0) + (expiring_2m_v2_result.scalar() or 0)

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
    v1_res = await db.execute(
        text("""
            SELECT COUNT(*) FROM policies
            WHERE agent_id = :agent_id
              AND COALESCE(end_date, expiry_date) >= CURRENT_DATE
              AND COALESCE(end_date, expiry_date) <= CURRENT_DATE + CAST(:days || ' days' AS INTERVAL)
              AND LOWER(status) IN ('active', 'live')
        """),
        {"agent_id": current_user.id, "days": days}
    )
    v2_res = await db.execute(
        text("""
            SELECT COUNT(*) FROM policies_v2
            WHERE agent_id = :agent_id
              AND end_date >= CURRENT_DATE
              AND end_date <= CURRENT_DATE + CAST(:days || ' days' AS INTERVAL)
              AND is_active = true
        """),
        {"agent_id": current_user.id, "days": days}
    )
    count = (v1_res.scalar() or 0) + (v2_res.scalar() or 0)
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

    # Build union of Policy and PolicyV2
    stmt1 = select(
        Policy.id.cast(String).label("id"),
        Policy.policy_number.label("policy_number"),
        Policy.policy_type.label("policy_type"),
        Policy.insurer_name.label("insurer_name"),
        Policy.premium_amount.label("premium_amount"),
        func.coalesce(Policy.end_date, Policy.expiry_date).label("end_date"),
        Policy.status.label("status"),
        Policy.agent_id.label("agent_id"),
        Policy.customer_id.label("customer_id")
    ).where(
        Policy.agent_id == current_user.id,
        func.lower(Policy.status).in_(['live', 'active']),
        func.coalesce(Policy.end_date, Policy.expiry_date) >= current_date,
        func.coalesce(Policy.end_date, Policy.expiry_date) <= max_date
    )

    stmt2 = select(
        PolicyV2.id.cast(String).label("id"),
        PolicyV2.policy_number.label("policy_number"),
        PolicyV2.insurance_type.label("policy_type"),
        PolicyV2.insurance_company.label("insurer_name"),
        PolicyV2.final_amount.label("premium_amount"),
        PolicyV2.end_date.label("end_date"),
        literal("active").label("status"),
        PolicyV2.agent_id.label("agent_id"),
        PolicyV2.customer_id.label("customer_id")
    ).where(
        PolicyV2.agent_id == current_user.id,
        PolicyV2.is_active == True,
        PolicyV2.end_date >= current_date,
        PolicyV2.end_date <= max_date
    )

    union_subq = union_all(stmt1, stmt2).subquery("u")

    total = (await db.execute(select(func.count()).select_from(union_subq))).scalar() or 0

    query = select(union_subq, Customer).outerjoin(
        Customer, union_subq.c.customer_id == Customer.id
    ).order_by(union_subq.c.end_date.asc()).offset(offset).limit(limit)

    result = await db.execute(query)

    items = []
    for row in result.all():
        policy = row[0:9]
        customer = row[9]
        p_id, p_no, p_type, p_ins, p_prem, p_end, p_stat, p_agent, p_cust = policy
        
        days_remaining = (p_end - current_date).days if p_end else 0
        items.append(ExpiringPolicyItem(
            policy_id=p_id,
            policy_number=p_no or "",
            policy_type=p_type or "",
            insurer_name=p_ins,
            premium_amount=float(p_prem) if p_prem else 0.0,
            expiry_date=p_end,
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
    v1_res = await db.execute(
        text("""
            SELECT COUNT(*) FROM policies
            WHERE agent_id = :agent_id
              AND COALESCE(end_date, expiry_date) < CURRENT_DATE
        """),
        {"agent_id": current_user.id}
    )
    v2_res = await db.execute(
        text("""
            SELECT COUNT(*) FROM policies_v2
            WHERE agent_id = :agent_id
              AND end_date < CURRENT_DATE
        """),
        {"agent_id": current_user.id}
    )
    return {"count": (v1_res.scalar() or 0) + (v2_res.scalar() or 0)}


@router.get("/expired-list", response_model=ExpiredListResponse)
async def get_expired_list(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    current_date = date.today()
    offset = (page - 1) * limit

    stmt1 = select(
        Policy.id.cast(String).label("id"),
        Policy.policy_number.label("policy_number"),
        Policy.policy_type.label("policy_type"),
        Policy.insurer_name.label("insurer_name"),
        Policy.premium_amount.label("premium_amount"),
        func.coalesce(Policy.end_date, Policy.expiry_date).label("end_date"),
        Policy.agent_id.label("agent_id"),
        Policy.customer_id.label("customer_id")
    ).where(
        Policy.agent_id == current_user.id,
        func.coalesce(Policy.end_date, Policy.expiry_date) < current_date
    )

    stmt2 = select(
        PolicyV2.id.cast(String).label("id"),
        PolicyV2.policy_number.label("policy_number"),
        PolicyV2.insurance_type.label("policy_type"),
        PolicyV2.insurance_company.label("insurer_name"),
        PolicyV2.final_amount.label("premium_amount"),
        PolicyV2.end_date.label("end_date"),
        PolicyV2.agent_id.label("agent_id"),
        PolicyV2.customer_id.label("customer_id")
    ).where(
        PolicyV2.agent_id == current_user.id,
        PolicyV2.end_date < current_date
    )

    union_subq = union_all(stmt1, stmt2).subquery("u")

    total = (await db.execute(select(func.count()).select_from(union_subq))).scalar() or 0

    query = select(union_subq, Customer).outerjoin(
        Customer, union_subq.c.customer_id == Customer.id
    ).order_by(union_subq.c.end_date.desc()).offset(offset).limit(limit)

    result = await db.execute(query)

    items = []
    for row in result.all():
        policy = row[0:8]
        customer = row[8]
        p_id, p_no, p_type, p_ins, p_prem, p_end, p_agent, p_cust = policy
        
        days_overdue = (current_date - p_end).days if p_end else 0
        items.append(ExpiredPolicyItem(
            policy_id=p_id,
            policy_number=p_no or "",
            policy_type=p_type or "",
            insurer_name=p_ins,
            premium_amount=float(p_prem) if p_prem else 0.0,
            expiry_date=p_end,
            days_overdue=days_overdue,
            customer_full_name=customer.full_name if customer else "Unknown",
            customer_phone_number=customer.phone if customer else ""
        ))

    return ExpiredListResponse(items=items, total=total, page=page, limit=limit)
