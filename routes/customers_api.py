from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, delete, update
from typing import Optional, Dict, Any
from datetime import date as _date

from database import get_db
from models.users import User
from models.customers import Customer
from models.policies import Policy
from models.policy_v2 import PolicyV2
from models.customer_document import CustomerDocument
from models.motor_insurance import MotorInsurancePolicy, MotorInsuranceQuote
from models.vehicle_documents import VehicleDocument
from models.reminders import Reminder
from models.leads import Lead
from utils.auth import get_current_user

router = APIRouter(prefix="/api/customers", tags=["Customers"])


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


def _safe_date(obj, field: str) -> str | None:
    """Safely get a date field that may not exist in the DB yet."""
    val = getattr(obj, field, None)
    return val.isoformat() if val else None


# ── GET list ──────────────────────────────────────────────────────────────────
@router.get("/")
async def get_customers(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query("all", regex="^(all|active|inactive)$"),
    search: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        agent_id = current_user.id
        offset = (page - 1) * limit

        query = select(Customer).where(Customer.agent_id == agent_id)
        if status != "all":
            query = query.where(Customer.status == status)
        if search:
            term = f"%{search}%"
            query = query.where(
                Customer.full_name.ilike(term) |
                Customer.phone.ilike(term) |
                Customer.email.ilike(term)
            )

        count_query = select(func.count(Customer.id)).where(Customer.agent_id == agent_id)
        if status != "all":
            count_query = count_query.where(Customer.status == status)
        if search:
            term = f"%{search}%"
            count_query = count_query.where(
                Customer.full_name.ilike(term) |
                Customer.phone.ilike(term) |
                Customer.email.ilike(term)
            )

        total = (await db.execute(count_query)).scalar() or 0

        # Order by id — created_at may not exist in DB yet
        query = query.order_by(Customer.id.desc()).offset(offset).limit(limit)
        customers = (await db.execute(query)).scalars().all()

        # Get all customer IDs for batch policy queries
        customer_ids = [c.id for c in customers]

        # Batch fetch policy counts in one query each (much faster than N+1)
        total_pol_map: dict = {}
        active_pol_map: dict = {}
        latest_end_map: dict = {}

        if customer_ids:
            # Total policies per customer
            total_pol_result = await db.execute(
                select(Policy.customer_id, func.count(Policy.id))
                .where(Policy.customer_id.in_(customer_ids))
                .group_by(Policy.customer_id)
            )
            for cid, cnt in total_pol_result.all():
                total_pol_map[cid] = total_pol_map.get(cid, 0) + cnt
                
            total_pol_v2_result = await db.execute(
                select(PolicyV2.customer_id, func.count(PolicyV2.id))
                .where(PolicyV2.customer_id.in_(customer_ids))
                .group_by(PolicyV2.customer_id)
            )
            for cid, cnt in total_pol_v2_result.all():
                total_pol_map[cid] = total_pol_map.get(cid, 0) + cnt

            # Active policies per customer
            active_pol_result = await db.execute(
                select(Policy.customer_id, func.count(Policy.id))
                .where(
                    Policy.customer_id.in_(customer_ids),
                    Policy.status.in_(['active', 'live'])
                )
                .group_by(Policy.customer_id)
            )
            for cid, cnt in active_pol_result.all():
                active_pol_map[cid] = active_pol_map.get(cid, 0) + cnt
                
            active_pol_v2_result = await db.execute(
                select(PolicyV2.customer_id, func.count(PolicyV2.id))
                .where(
                    PolicyV2.customer_id.in_(customer_ids),
                    PolicyV2.is_active == True
                )
                .group_by(PolicyV2.customer_id)
            )
            for cid, cnt in active_pol_v2_result.all():
                active_pol_map[cid] = active_pol_map.get(cid, 0) + cnt

            # Latest policy end date per customer (use COALESCE for end_date/expiry_date)
            from sqlalchemy import case
            latest_result = await db.execute(
                select(
                    Policy.customer_id,
                    func.max(
                        case(
                            (Policy.end_date.isnot(None), Policy.end_date),
                            else_=Policy.expiry_date
                        )
                    ).label("latest_end")
                )
                .where(Policy.customer_id.in_(customer_ids))
                .group_by(Policy.customer_id)
            )
            for cid, latest_end in latest_result.all():
                latest_end_map[cid] = latest_end
                
            latest_v2_result = await db.execute(
                select(
                    PolicyV2.customer_id,
                    func.max(PolicyV2.end_date).label("latest_end")
                )
                .where(PolicyV2.customer_id.in_(customer_ids))
                .group_by(PolicyV2.customer_id)
            )
            for cid, latest_end in latest_v2_result.all():
                current_latest = latest_end_map.get(cid)
                if current_latest is None:
                    latest_end_map[cid] = latest_end
                elif latest_end is not None and latest_end > current_latest:
                    latest_end_map[cid] = latest_end

        data = []
        for c in customers:
            latest_end = latest_end_map.get(c.id)
            data.append({
                "id": str(c.id),
                "full_name": c.full_name or "",
                "phone": c.phone or "",
                "email": c.email or "",
                "city": c.city or "",
                "status": c.status or "active",
                "total_policies": total_pol_map.get(c.id, 0),
                "active_policies": active_pol_map.get(c.id, 0),
                "latest_policy_end_date": latest_end.isoformat() if latest_end else None,
            })

        return {"total": total, "page": page, "pages": (total + limit - 1) // limit, "data": data}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch customers: {str(e)}")


# ── GET detail ────────────────────────────────────────────────────────────────
@router.get("/{customer_id}")
async def get_customer_detail(
    customer_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        customer = (await db.execute(
            select(Customer).where(
                Customer.id == customer_id,
                Customer.agent_id == current_user.id
            )
        )).scalars().first()

        if not customer:
            raise HTTPException(status_code=404, detail="Customer not found")

        policies_v1 = (await db.execute(
            select(Policy).where(Policy.customer_id == customer.id).order_by(Policy.id.desc())
        )).scalars().all()
        
        policies_v2 = (await db.execute(
            select(PolicyV2).where(PolicyV2.customer_id == customer.id).order_by(PolicyV2.id.desc())
        )).scalars().all()

        policies_data = [{
            "id": str(p.id),
            "policy_number": p.policy_number or "",
            "policy_type": p.policy_type or "",
            "insurer_name": p.insurer_name or "",
            "plan_name": p.plan_name or "",
            "sum_insured": float(p.sum_assured) if p.sum_assured else 0.0,
            "premium_amount": float(p.premium_amount) if p.premium_amount else 0.0,
            "start_date": (p.start_date or p.issue_date).isoformat() if (p.start_date or p.issue_date) else None,
            "end_date": (p.end_date or p.expiry_date).isoformat() if (p.end_date or p.expiry_date) else None,
            "issue_date": p.issue_date.isoformat() if p.issue_date else None,
            "expiry_date": p.expiry_date.isoformat() if p.expiry_date else None,
            "status": p.status or "active",
            "nominee_name": p.nominee_name or "",
            "nominee_relation": p.nominee_relation or "",
        } for p in policies_v1]
        
        for p in policies_v2:
            policies_data.append({
                "id": str(p.id),
                "policy_number": p.policy_number or "",
                "policy_type": p.insurance_type or "",
                "insurer_name": p.insurance_company or "",
                "plan_name": "", 
                "sum_insured": float(p.total_amount) if p.total_amount else 0.0,
                "premium_amount": float(p.final_amount) if p.final_amount else 0.0,
                "start_date": p.start_date.isoformat() if p.start_date else None,
                "end_date": p.end_date.isoformat() if p.end_date else None,
                "issue_date": p.created_at.date().isoformat() if p.created_at else None,
                "expiry_date": p.end_date.isoformat() if p.end_date else None,
                "status": "active" if p.is_active else "inactive",
                "nominee_name": "",
                "nominee_relation": "",
            })
            
        policies_data.sort(
            key=lambda x: x["start_date"] or x["issue_date"] or "", 
            reverse=True
        )

        return {
            "id": str(customer.id),
            "full_name": customer.full_name,
            "phone": customer.phone,
            "email": customer.email,
            "dob": customer.dob.isoformat() if customer.dob else None,
            "anniversary_date": customer.anniversary_date.isoformat() if customer.anniversary_date else None,
            "address": customer.address,
            "city": customer.city,
            "state": customer.state,
            "pincode": customer.pincode,
            "ref_by": customer.ref_by or "",
            "status": customer.status,
            "created_at": _safe_date(customer, "created_at"),
            "policies": policies_data,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch customer detail: {str(e)}")


# ── POST create ───────────────────────────────────────────────────────────────
@router.post("/")
async def create_customer(
    customer_data: Dict[str, Any],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        full_name = customer_data.get("full_name", "").strip()
        if not full_name:
            raise HTTPException(status_code=400, detail="Customer full name is required")

        # Check for existing customer with the same name
        existing_customer = (await db.execute(
            select(Customer).where(
                func.lower(Customer.full_name) == full_name.lower(),
                Customer.agent_id == current_user.id
            )
        )).scalars().first()

        if existing_customer:
            raise HTTPException(status_code=400, detail=f"Customer with name '{full_name}' already exists")

        new_customer = Customer(
            agent_id=current_user.id,
            full_name=customer_data.get("full_name"),
            phone=customer_data.get("phone"),
            email=customer_data.get("email"),
            dob=_parse_date(customer_data.get("dob")),
            anniversary_date=_parse_date(customer_data.get("anniversary_date")),
            address=customer_data.get("address"),
            city=customer_data.get("city"),
            state=customer_data.get("state"),
            pincode=customer_data.get("pincode"),
            ref_by=customer_data.get("ref_by"),
            status=customer_data.get("status", "active"),
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
            "created_at": _safe_date(new_customer, "created_at"),
        }

    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create customer: {str(e)}")


# ── PUT update ────────────────────────────────────────────────────────────────
@router.put("/{customer_id}")
async def update_customer(
    customer_id: int,
    customer_data: Dict[str, Any],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    DATE_FIELDS = {"dob", "anniversary_date"}
    try:
        customer = (await db.execute(
            select(Customer).where(
                Customer.id == customer_id,
                Customer.agent_id == current_user.id
            )
        )).scalars().first()

        if not customer:
            raise HTTPException(status_code=404, detail="Customer not found")

        new_full_name = customer_data.get("full_name")
        if new_full_name is not None:
            new_full_name = new_full_name.strip()
            if not new_full_name:
                raise HTTPException(status_code=400, detail="Customer full name is required")
            
            if new_full_name.lower() != customer.full_name.lower():
                existing_customer = (await db.execute(
                    select(Customer).where(
                        func.lower(Customer.full_name) == new_full_name.lower(),
                        Customer.agent_id == current_user.id
                    )
                )).scalars().first()

                if existing_customer:
                    raise HTTPException(status_code=400, detail=f"Customer with name '{new_full_name}' already exists")

        for field, value in customer_data.items():
            if hasattr(customer, field) and value is not None:
                setattr(customer, field, _parse_date(value) if field in DATE_FIELDS else value)

        await db.commit()
        await db.refresh(customer)

        return {
            "id": str(customer.id),
            "full_name": customer.full_name,
            "phone": customer.phone,
            "email": customer.email,
            "city": customer.city,
            "status": customer.status,
            "updated_at": _safe_date(customer, "updated_at"),
        }

    except HTTPException:
        raise
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid customer ID format")
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to update customer: {str(e)}")


# ── DELETE customer ───────────────────────────────────────────────────────────
@router.delete("/{customer_id}")
async def delete_customer(
    customer_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        customer = (await db.execute(
            select(Customer).where(
                Customer.id == customer_id,
                Customer.agent_id == current_user.id
            )
        )).scalars().first()

        if not customer:
            raise HTTPException(status_code=404, detail="Customer not found")

        # Explicitly delete/update all related records
        await db.execute(delete(Policy).where(Policy.customer_id == customer_id))
        await db.execute(delete(PolicyV2).where(PolicyV2.customer_id == customer_id))
        await db.execute(delete(CustomerDocument).where(CustomerDocument.customer_id == customer_id))
        await db.execute(delete(VehicleDocument).where(VehicleDocument.customer_id == customer_id))
        await db.execute(delete(MotorInsurancePolicy).where(MotorInsurancePolicy.customer_id == customer_id))
        await db.execute(delete(MotorInsuranceQuote).where(MotorInsuranceQuote.customer_id == customer_id))
        await db.execute(delete(Reminder).where(Reminder.customer_id == customer_id))
        await db.execute(update(Lead).where(Lead.converted_customer_id == customer_id).values(converted_customer_id=None))

        await db.delete(customer)
        await db.commit()
        return {"message": "Customer deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete customer: {str(e)}")

# -- GET customer policies --------------------------------------------------------
@router.get('/{customer_id}/policies')
async def get_customer_policies(
    customer_id: str,
    db: AsyncSession = Depends(get_db)
):
    print(f'Fetching policies for customer_id: {customer_id}')
    try:
        c_id = int(customer_id)
    except ValueError:
        return []

    policies_v1 = (await db.execute(
        select(Policy).where(Policy.customer_id == c_id)
    )).scalars().all()
    
    policies_v2 = (await db.execute(
        select(PolicyV2).where(PolicyV2.customer_id == c_id)
    )).scalars().all()

    if not policies_v1 and not policies_v2:
        return []

    policies_data = []
    for p in policies_v1:
        policies_data.append({
            'id': str(p.id),
            'policy_number': p.policy_number or '',
            'policy_type': p.policy_type or '',
            'insurer_name': p.insurer_name or '',
            'plan_name': p.plan_name or '',
            'sum_insured': float(p.sum_assured) if p.sum_assured else 0.0,
            'premium_amount': float(p.premium_amount) if p.premium_amount else 0.0,
            'start_date': p.start_date.isoformat() if p.start_date else '',
            'end_date': p.end_date.isoformat() if p.end_date else '',
            'status': p.status or 'active',
            'nominee_name': p.nominee_name or '',
            'nominee_relation': p.nominee_relation or '',
        })
    for p in policies_v2:
        policies_data.append({
            'id': str(p.id),
            'policy_number': p.policy_number or '',
            'policy_type': p.insurance_type or '',
            'insurer_name': p.insurance_company or '',
            'plan_name': '',
            'sum_insured': float(p.total_amount) if p.total_amount else 0.0,
            'premium_amount': float(p.final_amount) if p.final_amount else 0.0,
            'start_date': p.start_date.isoformat() if p.start_date else '',
            'end_date': p.end_date.isoformat() if p.end_date else '',
            'status': 'active' if p.is_active else 'inactive',
            'nominee_name': '',
            'nominee_relation': '',
        })
    return policies_data

