from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, and_
from typing import Optional, Dict, Any
import uuid

from database import get_db
from models.users import User
from models.customers import Customer
from models.policies import Policy
from utils.auth import get_current_user

router = APIRouter(prefix="/api/customers", tags=["Customers"])

@router.get("/")
async def get_customers(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query("all", regex="^(all|active|inactive)$"),
    search: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get paginated list of customers with their latest policy info embedded.
    Supports filtering by status and searching by name/phone.
    """
    
    try:
        agent_id = current_user.id
        offset = (page - 1) * limit
        
        # Build base query
        query = select(Customer).where(Customer.agent_id == agent_id)
        
        # Apply status filter
        if status != "all":
            query = query.where(Customer.status == status)
        
        # Apply search filter
        if search:
            search_term = f"%{search}%"
            query = query.where(
                Customer.full_name.ilike(search_term) |
                Customer.phone.ilike(search_term) |
                Customer.email.ilike(search_term)
            )
        
        # Get total count
        count_query = select(func.count(Customer.id)).where(Customer.agent_id == agent_id)
        if status != "all":
            count_query = count_query.where(Customer.status == status)
        if search:
            search_term = f"%{search}%"
            count_query = count_query.where(
                Customer.full_name.ilike(search_term) |
                Customer.phone.ilike(search_term) |
                Customer.email.ilike(search_term)
            )
        
        count_result = await db.execute(count_query)
        total = count_result.scalar() or 0
        
        # Get paginated data
        query = query.order_by(Customer.created_at.desc()).offset(offset).limit(limit)
        result = await db.execute(query)
        customers = result.scalars().all()
        
        # Build response with latest policy info
        data = []
        for customer in customers:
            # Get latest policy for this customer
            latest_policy_query = select(Policy).where(
                Policy.customer_id == customer.id
            ).order_by(Policy.end_date.desc()).limit(1)
            
            latest_policy_result = await db.execute(latest_policy_query)
            latest_policy = latest_policy_result.scalars().first()
            
            # Get policy counts
            total_policies_query = select(func.count(Policy.id)).where(
                Policy.customer_id == customer.id
            )
            total_policies_result = await db.execute(total_policies_query)
            total_policies = total_policies_result.scalar() or 0
            
            active_policies_query = select(func.count(Policy.id)).where(
                Policy.customer_id == customer.id,
                Policy.status == 'active'
            )
            active_policies_result = await db.execute(active_policies_query)
            active_policies = active_policies_result.scalar() or 0
            
            customer_data = {
                "id": str(customer.id),
                "full_name": customer.full_name,
                "phone": customer.phone,
                "email": customer.email,
                "city": customer.city,
                "status": customer.status,
                "total_policies": total_policies,
                "active_policies": active_policies,
                "latest_policy_end_date": latest_policy.end_date.isoformat() if latest_policy else None
            }
            data.append(customer_data)
        
        pages = (total + limit - 1) // limit
        
        return {
            "total": total,
            "page": page,
            "pages": pages,
            "data": data
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch customers: {str(e)}"
        )

@router.get("/{customer_id}")
async def get_customer_detail(
    customer_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get full customer detail + all their policies.
    """
    
    try:
        agent_id = current_user.id
        
        # Get customer
        customer_query = select(Customer).where(
            Customer.id == int(customer_id),
            Customer.agent_id == agent_id
        )
        customer_result = await db.execute(customer_query)
        customer = customer_result.scalars().first()
        
        if not customer:
            raise HTTPException(
                status_code=404,
                detail="Customer not found"
            )
        
        # Get all policies for this customer
        policies_query = select(Policy).where(
            Policy.customer_id == customer.id
        ).order_by(Policy.created_at.desc())
        
        policies_result = await db.execute(policies_query)
        policies = policies_result.scalars().all()
        
        # Build policies data
        policies_data = []
        for policy in policies:
            policy_data = {
                "id": str(policy.id),
                "policy_number": policy.policy_number,
                "policy_type": policy.policy_type,
                "insurer_name": policy.insurer_name,
                "plan_name": policy.plan_name,
                "sum_insured": float(policy.sum_assured) if policy.sum_assured else 0.0,
                "premium_amount": float(policy.premium_amount) if policy.premium_amount else 0.0,
                "start_date": policy.start_date.isoformat() if policy.start_date else None,
                "end_date": policy.end_date.isoformat() if policy.end_date else None,
                "status": policy.status,
                "nominee_name": policy.nominee_name,
                "nominee_relation": policy.nominee_relation
            }
            policies_data.append(policy_data)
        
        return {
            "id": str(customer.id),
            "full_name": customer.full_name,
            "phone": customer.phone,
            "email": customer.email,
            "dob": customer.dob.isoformat() if customer.dob else None,
            "address": customer.address,
            "city": customer.city,
            "state": customer.state,
            "pincode": customer.pincode,
            "status": customer.status,
            "created_at": customer.created_at.isoformat() if customer.created_at else None,
            "policies": policies_data
        }
        
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="Invalid customer ID format"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch customer detail: {str(e)}"
        )

@router.post("/")
async def create_customer(
    customer_data: Dict[str, Any],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new customer.
    """
    from datetime import date as _date

    def _parse_date(val) -> _date | None:
        """Convert string 'YYYY-MM-DD' or datetime.date to date, or return None."""
        if val is None:
            return None
        if isinstance(val, _date):
            return val
        try:
            return _date.fromisoformat(str(val)[:10])
        except (ValueError, TypeError):
            return None

    try:
        agent_id = current_user.id

        new_customer = Customer(
            agent_id=agent_id,
            full_name=customer_data.get("full_name"),
            phone=customer_data.get("phone"),
            email=customer_data.get("email"),
            dob=_parse_date(customer_data.get("dob")),
            address=customer_data.get("address"),
            city=customer_data.get("city"),
            state=customer_data.get("state"),
            pincode=customer_data.get("pincode"),
            status=customer_data.get("status", "active")
        )

        db.add(new_customer)
        await db.commit()
        await db.refresh(new_customer)

        return {
            "id": str(new_customer.id),
            "full_name": new_customer.full_name,
            "phone": new_customer.phone,
            "email": new_customer.email,
            "city": new_customer.city,
            "status": new_customer.status,
            "created_at": new_customer.created_at.isoformat() if new_customer.created_at else None
        }

    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create customer: {str(e)}"
        )

        return {
            "id": str(new_customer.id),
            "full_name": new_customer.full_name,
            "phone": new_customer.phone,
            "email": new_customer.email,
            "city": new_customer.city,
            "status": new_customer.status,
            "created_at": new_customer.created_at.isoformat() if new_customer.created_at else None
        }

    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create customer: {str(e)}"
        )

@router.put("/{customer_id}")
async def update_customer(
    customer_id: str,
    customer_data: Dict[str, Any],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update an existing customer.
    """
    from datetime import date as _date

    def _parse_date(val):
        if val is None:
            return None
        if isinstance(val, _date):
            return val
        try:
            return _date.fromisoformat(str(val)[:10])
        except (ValueError, TypeError):
            return None

    DATE_FIELDS = {"dob", "anniversary_date"}

    try:
        agent_id = current_user.id

        customer_query = select(Customer).where(
            Customer.id == int(customer_id),
            Customer.agent_id == agent_id
        )
        customer_result = await db.execute(customer_query)
        customer = customer_result.scalars().first()

        if not customer:
            raise HTTPException(status_code=404, detail="Customer not found")

        for field, value in customer_data.items():
            if hasattr(customer, field) and value is not None:
                if field in DATE_FIELDS:
                    value = _parse_date(value)
                setattr(customer, field, value)

        await db.commit()
        await db.refresh(customer)
        
        return {
            "id": str(customer.id),
            "full_name": customer.full_name,
            "phone": customer.phone,
            "email": customer.email,
            "city": customer.city,
            "status": customer.status,
            "updated_at": customer.updated_at.isoformat() if customer.updated_at else None
        }
        
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="Invalid customer ID format"
        )
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update customer: {str(e)}"
        )
