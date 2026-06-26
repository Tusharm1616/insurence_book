"""Reports & Analytics endpoints for InsureBook."""

import logging
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from datetime import date, datetime
from typing import Optional

from database import get_db
from models.users import User
from utils.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/reports", tags=["Reports"])


async def _has_policies_v2(db: AsyncSession) -> bool:
    """Check if policies_v2 table exists and is usable."""
    try:
        await db.execute(text("SELECT 1 FROM policies_v2 LIMIT 0"))
        return True
    except Exception:
        await db.rollback()
        return False


@router.get("/life-insurance")
async def get_life_insurance_report(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Life Insurance Report summary for the current agent.
    Returns: total_policies, total_premium, active_policies, expired_policies, claims_filed
    """
    try:
        agent_id = current_user.id

        query = text("""
            SELECT
                COUNT(*) as total_policies,
                COALESCE(SUM(premium_amount), 0) as total_premium,
                COUNT(*) FILTER (
                    WHERE LOWER(status) IN ('active', 'live')
                ) as active_policies,
                COUNT(*) FILTER (
                    WHERE LOWER(status) NOT IN ('active', 'live')
                ) as expired_policies,
                COUNT(*) FILTER (
                    WHERE LOWER(status) = 'claimed'
                ) as claims_filed
            FROM policies
            WHERE agent_id = :agent_id
        """)

        result = await db.execute(query, {"agent_id": agent_id})
        row = result.fetchone()

        return {
            "total_policies": row[0] or 0,
            "total_premium": float(row[1] or 0),
            "active_policies": row[2] or 0,
            "expired_policies": row[3] or 0,
            "claims_filed": row[4] or 0,
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch life insurance report: {str(e)}"
        )


@router.get("/dashboard")
async def get_reports_dashboard(
    month: str = Query(..., description="Month in YYYY-MM format"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Returns comprehensive dashboard data for a given month.
    Tries policies_v2 table first, falls back to policies table.
    """
    try:
        agent_id = current_user.id

        # Validate month format
        try:
            target_date = datetime.strptime(month, "%Y-%m")
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid month format. Use YYYY-MM")

        year = int(month.split("-")[0])
        month_num = int(month.split("-")[1])

        use_v2 = await _has_policies_v2(db)

        if use_v2:
            summary_query = text("""
                SELECT
                    COALESCE(SUM(final_amount), 0) as total_business,
                    COALESCE(SUM(commission_amount), 0) as total_income,
                    COUNT(*) as policies_sold,
                    COUNT(*) FILTER (WHERE LOWER(COALESCE(inspection_status, 'NA')) != 'na' OR payment_date IS NOT NULL) as sale_complete,
                    COUNT(*) FILTER (WHERE payment_date IS NULL AND LOWER(COALESCE(inspection_status, 'NA')) = 'na') as sale_pending
                FROM policies_v2
                WHERE agent_id = :agent_id
                  AND EXTRACT(YEAR FROM created_at) = :year
                  AND EXTRACT(MONTH FROM created_at) = :month
            """)
        else:
            summary_query = text("""
                SELECT
                    COALESCE(SUM(premium_amount), 0) as total_business,
                    0 as total_income,
                    COUNT(*) as policies_sold,
                    COUNT(*) FILTER (WHERE LOWER(status) = 'active') as sale_complete,
                    COUNT(*) FILTER (WHERE LOWER(status) != 'active') as sale_pending
                FROM policies
                WHERE agent_id = :agent_id
                  AND EXTRACT(YEAR FROM COALESCE(issue_date, start_date)) = :year
                  AND EXTRACT(MONTH FROM COALESCE(issue_date, start_date)) = :month
            """)

        result = await db.execute(summary_query, {
            "agent_id": agent_id,
            "year": year,
            "month": month_num,
        })
        row = result.fetchone()

        total_business = float(row[0]) if row and row[0] else 0.0
        total_income = float(row[1]) if row and row[1] else 0.0
        policies_sold = row[2] if row else 0
        sale_complete = row[3] if row else 0
        sale_pending = row[4] if row else 0

        # ── Leads data ───────────────────────────────────────────────────
        try:
            leads_query = text("""
                SELECT
                    COUNT(*) as leads_total,
                    COUNT(*) FILTER (WHERE id IN (
                        SELECT DISTINCT customer_id FROM policies
                        WHERE agent_id = :agent_id
                          AND EXTRACT(YEAR FROM COALESCE(issue_date, start_date)) = :year
                          AND EXTRACT(MONTH FROM COALESCE(issue_date, start_date)) = :month
                    )) as leads_converted
                FROM customers
                WHERE agent_id = :agent_id
                  AND EXTRACT(YEAR FROM created_at) = :year
                  AND EXTRACT(MONTH FROM created_at) = :month
            """)
            leads_result = await db.execute(leads_query, {
                "agent_id": agent_id,
                "year": year,
                "month": month_num,
            })
            leads_row = leads_result.fetchone()
            leads_total = leads_row[0] if leads_row else 0
            leads_converted = leads_row[1] if leads_row else 0
        except Exception:
            await db.rollback()
            leads_total = 0
            leads_converted = 0

        # ── Business by insurance type ───────────────────────────────────
        if use_v2:
            by_type_query = text("""
                SELECT
                    COALESCE(insurance_type, 'Other') as type,
                    COUNT(*) as count,
                    COALESCE(SUM(final_amount), 0) as amount
                FROM policies_v2
                WHERE agent_id = :agent_id
                  AND EXTRACT(YEAR FROM created_at) = :year
                  AND EXTRACT(MONTH FROM created_at) = :month
                GROUP BY insurance_type
                ORDER BY amount DESC
            """)
        else:
            by_type_query = text("""
                SELECT
                    COALESCE(policy_type, 'Other') as type,
                    COUNT(*) as count,
                    COALESCE(SUM(premium_amount), 0) as amount
                FROM policies
                WHERE agent_id = :agent_id
                  AND EXTRACT(YEAR FROM COALESCE(issue_date, start_date)) = :year
                  AND EXTRACT(MONTH FROM COALESCE(issue_date, start_date)) = :month
                GROUP BY policy_type
                ORDER BY amount DESC
            """)

        by_type_result = await db.execute(by_type_query, {
            "agent_id": agent_id,
            "year": year,
            "month": month_num,
        })
        by_insurance_type = [
            {"type": r[0] or "Other", "count": r[1], "amount": float(r[2])}
            for r in by_type_result.fetchall()
        ]

        # ── Monthly trend (last 6 months) ────────────────────────────────
        from dateutil.relativedelta import relativedelta
        end_dt = date(year, month_num, 1)
        start_dt = end_dt - relativedelta(months=5)

        if use_v2:
            trend_query = text("""
                SELECT
                    TO_CHAR(created_at, 'YYYY-MM') as month,
                    COALESCE(SUM(final_amount), 0) as business,
                    COALESCE(SUM(commission_amount), 0) as income
                FROM policies_v2
                WHERE agent_id = :agent_id
                  AND created_at >= :start_date
                  AND created_at < :end_date + INTERVAL '1 month'
                GROUP BY TO_CHAR(created_at, 'YYYY-MM')
                ORDER BY month ASC
            """)
        else:
            trend_query = text("""
                SELECT
                    TO_CHAR(COALESCE(issue_date, start_date), 'YYYY-MM') as month,
                    COALESCE(SUM(premium_amount), 0) as business,
                    0 as income
                FROM policies
                WHERE agent_id = :agent_id
                  AND COALESCE(issue_date, start_date) >= :start_date
                  AND COALESCE(issue_date, start_date) < :end_date + INTERVAL '1 month'
                GROUP BY TO_CHAR(COALESCE(issue_date, start_date), 'YYYY-MM')
                ORDER BY month ASC
            """)

        trend_result = await db.execute(trend_query, {
            "agent_id": agent_id,
            "start_date": start_dt,
            "end_date": end_dt,
        })
        monthly_trend = [
            {"month": r[0], "business": float(r[1]), "income": float(r[2])}
            for r in trend_result.fetchall()
        ]

        return {
            "total_business": total_business,
            "total_income": total_income,
            "policies_sold": policies_sold,
            "leads_total": leads_total,
            "leads_converted": leads_converted,
            "sale_complete": sale_complete,
            "sale_pending": sale_pending,
            "by_insurance_type": by_insurance_type,
            "monthly_trend": monthly_trend,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Reports dashboard error: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch reports dashboard: {str(e)}"
        )


@router.get("/policies")
async def get_reports_policies(
    month: str = Query(..., description="Month in YYYY-MM format"),
    type: Optional[str] = Query(None, description="Insurance type filter"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Returns filtered list of policies for a given month.
    Falls back to policies table if policies_v2 is unavailable.
    """
    try:
        agent_id = current_user.id

        try:
            datetime.strptime(month, "%Y-%m")
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid month format. Use YYYY-MM")

        year = int(month.split("-")[0])
        month_num = int(month.split("-")[1])

        use_v2 = await _has_policies_v2(db)
        params = {"agent_id": agent_id, "year": year, "month": month_num}

        if use_v2:
            type_filter = ""
            if type:
                type_filter = "AND LOWER(p.insurance_type) = LOWER(:insurance_type)"
                params["insurance_type"] = type

            query = text(f"""
                SELECT
                    p.id,
                    p.policy_number,
                    COALESCE(c.full_name, 'Unknown') as customer_name,
                    c.phone as customer_phone,
                    p.insurance_type,
                    p.insurance_company,
                    COALESCE(p.final_amount, 0) as amount,
                    COALESCE(p.commission_amount, 0) as commission,
                    COALESCE(p.commission_percent, 0) as commission_percent,
                    p.payment_mode,
                    p.created_at
                FROM policies_v2 p
                LEFT JOIN customers c ON p.customer_id = c.id
                WHERE p.agent_id = :agent_id
                  AND EXTRACT(YEAR FROM p.created_at) = :year
                  AND EXTRACT(MONTH FROM p.created_at) = :month
                  {type_filter}
                ORDER BY p.created_at DESC
            """)

            result = await db.execute(query, params)
            policies = [
                {
                    "id": str(r[0]),
                    "policy_number": r[1],
                    "customer_name": r[2],
                    "customer_phone": r[3],
                    "insurance_type": r[4] or "Other",
                    "insurance_company": r[5],
                    "amount": float(r[6]),
                    "commission": float(r[7]),
                    "commission_percent": float(r[8]),
                    "payment_mode": r[9],
                    "created_at": r[10].isoformat() if r[10] else None,
                }
                for r in result.fetchall()
            ]
        else:
            type_filter = ""
            if type:
                type_filter = "AND LOWER(p.policy_type) = LOWER(:insurance_type)"
                params["insurance_type"] = type

            query = text(f"""
                SELECT
                    p.id,
                    p.policy_number,
                    COALESCE(c.full_name, 'Unknown') as customer_name,
                    c.phone as customer_phone,
                    p.policy_type,
                    p.insurer_name,
                    COALESCE(p.premium_amount, 0) as amount,
                    0 as commission,
                    0 as commission_percent,
                    '' as payment_mode,
                    COALESCE(p.issue_date, p.start_date) as created_at
                FROM policies p
                LEFT JOIN customers c ON p.customer_id = c.id
                WHERE p.agent_id = :agent_id
                  AND EXTRACT(YEAR FROM COALESCE(p.issue_date, p.start_date)) = :year
                  AND EXTRACT(MONTH FROM COALESCE(p.issue_date, p.start_date)) = :month
                  {type_filter}
                ORDER BY COALESCE(p.issue_date, p.start_date) DESC
            """)

            result = await db.execute(query, params)
            policies = [
                {
                    "id": str(r[0]),
                    "policy_number": r[1],
                    "customer_name": r[2],
                    "customer_phone": r[3],
                    "insurance_type": r[4] or "Other",
                    "insurance_company": r[5] or "",
                    "amount": float(r[6]),
                    "commission": float(r[7]),
                    "commission_percent": float(r[8]),
                    "payment_mode": r[9] or "",
                    "created_at": r[10].isoformat() if r[10] else None,
                }
                for r in result.fetchall()
            ]

        return {"policies": policies, "count": len(policies)}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Reports policies error: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch report policies: {str(e)}"
        )


@router.get("/income")
async def get_reports_income(
    year: int = Query(..., description="Year in YYYY format"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Returns monthly breakdown of commission income for the year.
    """
    try:
        agent_id = current_user.id
        use_v2 = await _has_policies_v2(db)

        if use_v2:
            query = text("""
                SELECT
                    EXTRACT(MONTH FROM created_at)::int as month_num,
                    TO_CHAR(created_at, 'YYYY-MM') as month,
                    COALESCE(SUM(commission_amount), 0) as income,
                    COUNT(*) as policies_count
                FROM policies_v2
                WHERE agent_id = :agent_id
                  AND EXTRACT(YEAR FROM created_at) = :year
                GROUP BY EXTRACT(MONTH FROM created_at), TO_CHAR(created_at, 'YYYY-MM')
                ORDER BY month_num ASC
            """)
        else:
            query = text("""
                SELECT
                    EXTRACT(MONTH FROM COALESCE(issue_date, start_date))::int as month_num,
                    TO_CHAR(COALESCE(issue_date, start_date), 'YYYY-MM') as month,
                    0 as income,
                    COUNT(*) as policies_count
                FROM policies
                WHERE agent_id = :agent_id
                  AND EXTRACT(YEAR FROM COALESCE(issue_date, start_date)) = :year
                GROUP BY EXTRACT(MONTH FROM COALESCE(issue_date, start_date)),
                         TO_CHAR(COALESCE(issue_date, start_date), 'YYYY-MM')
                ORDER BY month_num ASC
            """)

        result = await db.execute(query, {"agent_id": agent_id, "year": year})
        monthly_income = [
            {
                "month_num": r[0],
                "month": r[1],
                "income": float(r[2]),
                "policies_count": r[3],
            }
            for r in result.fetchall()
        ]

        total_income = sum(m["income"] for m in monthly_income)

        return {
            "year": year,
            "total_income": total_income,
            "monthly_breakdown": monthly_income,
        }

    except Exception as e:
        logger.error(f"Reports income error: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch income report: {str(e)}"
        )
