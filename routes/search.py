from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, or_

from database import get_db
from models.users import User
from models.customers import Customer
from models.policies import Policy
from utils.auth import get_current_user

router = APIRouter(prefix="/api", tags=["Search"])


@router.get("/search")
async def global_search(
    q: str = Query(..., min_length=1, max_length=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Global search across customers, policies, and leads.
    Searches customers by name/phone, policies by policy_number,
    and leads by name. Returns grouped results.
    """
    try:
        agent_id = current_user.id
        search_term = f"%{q.strip()}%"

        # Search customers by name or phone
        customers_query = (
            select(Customer)
            .where(
                Customer.agent_id == agent_id,
                or_(
                    Customer.full_name.ilike(search_term),
                    Customer.phone.ilike(search_term),
                )
            )
            .order_by(Customer.full_name)
            .limit(20)
        )
        customers_result = await db.execute(customers_query)
        customers = customers_result.scalars().all()

        # Search policies by policy_number, also by insurer/type/customer name
        policies_query = (
            select(Policy, Customer)
            .outerjoin(Customer, Policy.customer_id == Customer.id)
            .where(
                Policy.agent_id == agent_id,
                or_(
                    Policy.policy_number.ilike(search_term),
                    Policy.insurer_name.ilike(search_term),
                    Policy.policy_type.ilike(search_term),
                    Customer.full_name.ilike(search_term),
                )
            )
            .order_by(Policy.id.desc())
            .limit(20)
        )
        policies_result = await db.execute(policies_query)
        policies_data = policies_result.all()

        # Format customers
        customers_list = []
        for c in customers:
            customers_list.append({
                "id": str(c.id),
                "full_name": c.full_name or "",
                "phone": c.phone or "",
                "email": c.email or "",
                "city": c.city or "",
                "status": c.status or "active",
            })

        # Format policies
        policies_list = []
        for policy, customer in policies_data:
            policies_list.append({
                "id": str(policy.id),
                "policy_number": policy.policy_number or "",
                "policy_type": policy.policy_type or "",
                "insurer_name": policy.insurer_name or "",
                "premium_amount": float(policy.premium_amount) if policy.premium_amount else 0.0,
                "status": policy.status or "",
                "customer_name": customer.full_name if customer else "Unknown",
                "customer_id": str(customer.id) if customer else "",
            })

        # Leads — currently not stored in DB, return empty array
        # When leads are persisted to DB, this can be extended
        leads_list = []

        return {
            "customers": customers_list,
            "policies": policies_list,
            "leads": leads_list,
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Search failed: {str(e)}"
        )
