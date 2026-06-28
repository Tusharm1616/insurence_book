from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, and_, text, literal, union_all, case, String
from typing import Optional, Dict, Any
from datetime import date
import uuid

from database import get_db
from models.users import User
from models.customers import Customer
from models.policies import Policy
from models.policy_v2 import PolicyV2
from utils.auth import get_current_user

router = APIRouter(prefix="/api/policies", tags=["Policies"])

@router.get("/")
async def get_policies(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    filter: Optional[str] = Query("all", regex="^(all|expired|expiring_1m|expiring_2m|active)$"),
    search: Optional[str] = Query(None),
    customer_id: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get paginated list of policies with filtering.
    All filtering logic happens in DATABASE using CURRENT_DATE.
    """
    
    print(f"--- GET /api/policies called ---")
    print(f"customer_id received: {customer_id}")
    try:
        agent_id = current_user.id
        print(f"agent_id from token: {agent_id}")
        offset = (page - 1) * limit
        
        # Build union of Policy and PolicyV2
        stmt1 = select(
            Policy.id.cast(String).label("id"),
            Policy.policy_number.label("policy_number"),
            Policy.policy_type.label("policy_type"),
            Policy.insurer_name.label("insurer_name"),
            Policy.plan_name.label("plan_name"),
            Policy.sum_assured.label("sum_assured"),
            Policy.premium_amount.label("premium_amount"),
            Policy.start_date.label("start_date"),
            Policy.end_date.label("end_date"),
            Policy.status.label("status"),
            Policy.agent_id.label("agent_id"),
            Policy.customer_id.label("customer_id")
        )

        stmt2 = select(
            PolicyV2.id.cast(String).label("id"),
            PolicyV2.policy_number.label("policy_number"),
            PolicyV2.insurance_type.label("policy_type"),
            PolicyV2.insurance_company.label("insurer_name"),
            literal("").label("plan_name"),
            PolicyV2.total_amount.label("sum_assured"),
            PolicyV2.final_amount.label("premium_amount"),
            PolicyV2.start_date.label("start_date"),
            PolicyV2.end_date.label("end_date"),
            case((PolicyV2.is_active == True, "active"), else_="inactive").label("status"),
            PolicyV2.agent_id.label("agent_id"),
            PolicyV2.customer_id.label("customer_id")
        )

        union_subq = union_all(stmt1, stmt2).subquery("u")
        
        # Build base query
        query = select(union_subq, Customer).outerjoin(
            Customer, union_subq.c.customer_id == Customer.id
        )
        
        # Temporarily removing agent_id filter if customer_id is provided, for debugging
        if not customer_id:
            query = query.where(union_subq.c.agent_id == agent_id)
        # Apply filter logic according to specification
        if filter == 'expired':
            query = query.where(
                union_subq.c.end_date < func.current_date(),
                union_subq.c.status.in_(['active', 'expired'])
            )
        elif filter == 'expiring_1m':
            query = query.where(
                union_subq.c.end_date.between(
                    func.current_date(),
                    func.current_date() + text("INTERVAL '30 days'")
                ),
                union_subq.c.status == 'active'
            )
        elif filter == 'expiring_2m':
            query = query.where(
                union_subq.c.end_date.between(
                    func.current_date(),
                    func.current_date() + text("INTERVAL '60 days'")
                ),
                union_subq.c.status == 'active'
            )
        elif filter == 'active':
            query = query.where(
                union_subq.c.status == 'active',
                union_subq.c.end_date >= func.current_date()
            )
        
        # Apply customer filter if provided
        if customer_id:
            try:
                c_id = int(customer_id)
                query = query.where(union_subq.c.customer_id == c_id)
            except ValueError:
                raise HTTPException(status_code=400, detail="customer_id must be a valid integer")
        if search:
            search_term = f"%{search}%"
            query = query.where(
                union_subq.c.policy_number.ilike(search_term) |
                union_subq.c.policy_type.ilike(search_term) |
                union_subq.c.insurer_name.ilike(search_term) |
                Customer.full_name.ilike(search_term)
            )
        
        # Get total count
        count_query = select(func.count()).select_from(query.subquery())
        count_result = await db.execute(count_query)
        total = count_result.scalar() or 0
        
        print(f"SQL query result count: {total}")
        
        # Get paginated data — order by end_date desc or id desc
        # (Using end_date is safer because IDs are different types (int vs uuid))
        query = query.order_by(union_subq.c.end_date.desc()).offset(offset).limit(limit)
        result = await db.execute(query)
        
        data = []
        for row in result.all():
            policy = row[0:12] # The union columns
            customer = row[12] # The customer object
            
            p_id, p_no, p_type, p_ins, p_plan, p_sum, p_prem, p_start, p_end, p_status, p_agent, p_cust = policy
            
            today = date.today()
            days_remaining = (p_end - today).days if p_end else 0
            
            policy_data = {
                "id": str(p_id),
                "policy_number": p_no or "",
                "policy_type": p_type or "",
                "insurer_name": p_ins or "",
                "plan_name": p_plan or "",
                "sum_assured": float(p_sum) if p_sum else 0.0,
                "premium_amount": float(p_prem) if p_prem else 0.0,
                "start_date": p_start.isoformat() if p_start else None,
                "end_date": p_end.isoformat() if p_end else None,
                "status": p_status or "active",
                "customer": {
                    "id": str(customer.id) if customer else "",
                    "full_name": customer.full_name if customer else "Unknown",
                    "phone": customer.phone if customer else ""
                },
                "days_remaining": days_remaining
            }
            data.append(policy_data)
        
        pages = (total + limit - 1) // limit
        
        return {
            "total": total,
            "page": page,
            "pages": pages,
            "data": data
        }
        
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="Invalid filter parameter"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch policies: {str(e)}"
        )

@router.get("/debug/{customer_id}")
async def debug_get_policies(
    customer_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Debug endpoint to fetch policies for a customer without auth checks."""
    try:
        c_id = int(customer_id)
        stmt1 = select(
            Policy.id.cast(String).label("id"),
            Policy.policy_number.label("policy_number"),
            Policy.policy_type.label("policy_type"),
            Policy.insurer_name.label("insurer_name"),
            Policy.plan_name.label("plan_name"),
            Policy.sum_assured.label("sum_assured"),
            Policy.premium_amount.label("premium_amount"),
            Policy.start_date.label("start_date"),
            Policy.end_date.label("end_date"),
            Policy.status.label("status"),
            Policy.agent_id.label("agent_id"),
            Policy.customer_id.label("customer_id")
        )

        stmt2 = select(
            PolicyV2.id.cast(String).label("id"),
            PolicyV2.policy_number.label("policy_number"),
            PolicyV2.insurance_type.label("policy_type"),
            PolicyV2.insurance_company.label("insurer_name"),
            literal("").label("plan_name"),
            PolicyV2.total_amount.label("sum_assured"),
            PolicyV2.final_amount.label("premium_amount"),
            PolicyV2.start_date.label("start_date"),
            PolicyV2.end_date.label("end_date"),
            case((PolicyV2.is_active == True, "active"), else_="inactive").label("status"),
            PolicyV2.agent_id.label("agent_id"),
            PolicyV2.customer_id.label("customer_id")
        )

        union_subq = union_all(stmt1, stmt2).subquery("u")
        query = select(union_subq).where(union_subq.c.customer_id == c_id)
        
        result = await db.execute(query)
        
        data = []
        for row in result.all():
            data.append(dict(row._mapping))
            
        return {"customer_id": c_id, "count": len(data), "policies": data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/")
async def create_policy(
    policy_data: Dict[str, Any],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new policy. Auto-generates policy_number if not provided."""
    
    print("--- POST /api/policies called ---")
    print(f"Incoming payload: {policy_data}")
    
    # Required field validation
    required_fields = ["customer_id", "policy_type", "insurer_name"]
    missing_fields = [f for f in required_fields if not policy_data.get(f)]
    if missing_fields:
        print(f"Missing required fields: {missing_fields}")
        raise HTTPException(
            status_code=422,
            detail=f"Missing required fields: {', '.join(missing_fields)}"
        )
        
    from datetime import date as _date
    import uuid as _uuid

    def _parse_date(val):
        if val is None:
            return None
        if isinstance(val, _date):
            return val
        try:
            return _date.fromisoformat(str(val)[:10])
        except (ValueError, TypeError):
            return None

    def _auto_policy_number(policy_type: str) -> str:
        """Generate a unique policy number from type + timestamp + random hex."""
        prefix_map = {
            'health': 'HL', 'motor': 'MI', 'life': 'LI', 'term': 'TM',
            'travel': 'TR', 'home': 'HM', 'business': 'BS', 'shop': 'SC',
            'accident': 'AC', 'two wheeler': 'TW', 'two-wheeler': 'TW',
        }
        pt = (policy_type or '').lower()
        prefix = next((v for k, v in prefix_map.items() if k in pt), 'PL')
        from datetime import datetime
        return f"{prefix}{datetime.now().strftime('%Y%m%d%H%M%S')}{_uuid.uuid4().hex[:8].upper()}"

    try:
        agent_id = current_user.id

        # Resolve customer_id — verify it belongs to this agent if provided
        customer_id = policy_data.get("customer_id")
        if customer_id:
            try:
                customer_id = int(customer_id)
                customer_result = await db.execute(
                    select(Customer).where(
                        Customer.id == customer_id,
                        Customer.agent_id == agent_id
                    )
                )
                if not customer_result.scalars().first():
                    customer_id = None  # don't block save, just unlink
            except (ValueError, TypeError):
                customer_id = None

        # Auto-generate policy number if blank/null
        raw_pno = policy_data.get("policy_number")
        policy_number = (raw_pno or "").strip()

        if policy_number:
            # Check if user-provided policy_number already exists
            existing = await db.execute(
                select(Policy).where(Policy.policy_number == policy_number)
            )
            if existing.scalars().first():
                raise HTTPException(
                    status_code=409,
                    detail=f"Policy number '{policy_number}' already exists. Please use a unique policy number."
                )
        else:
            # Auto-generate a unique policy number with retry
            policy_type_val = policy_data.get("policy_type", "PL")
            for _attempt in range(5):
                policy_number = _auto_policy_number(policy_type_val)
                existing = await db.execute(
                    select(Policy).where(Policy.policy_number == policy_number)
                )
                if not existing.scalars().first():
                    break
            # After 5 attempts with uuid+timestamp, collision is virtually impossible

        # Ensure policy_type is never null
        policy_type = (policy_data.get("policy_type") or "Other").strip()

        new_policy = Policy(
            agent_id=agent_id,
            customer_id=customer_id,
            policy_number=policy_number,
            policy_type=policy_type,
            insurer_name=policy_data.get("insurer_name") or "Unknown",
            plan_name=policy_data.get("plan_name") or policy_type,
            sum_assured=policy_data.get("sum_assured") or policy_data.get("sum_insured") or 0,
            premium_amount=policy_data.get("premium_amount") or 0,
            start_date=_parse_date(policy_data.get("start_date")),
            end_date=_parse_date(policy_data.get("end_date")),
            issue_date=_parse_date(
                policy_data.get("issue_date") or policy_data.get("start_date")
            ),
            expiry_date=_parse_date(
                policy_data.get("expiry_date") or policy_data.get("end_date")
            ),
            status=(policy_data.get("status") or "active").lower(),
            nominee_name=policy_data.get("nominee_name"),
            nominee_relation=policy_data.get("nominee_relation"),
            notes=policy_data.get("notes"),
        )

        db.add(new_policy)
        await db.commit()
        await db.refresh(new_policy)

        return {
            "id": str(new_policy.id),
            "policy_number": new_policy.policy_number,
            "policy_type": new_policy.policy_type,
            "insurer_name": new_policy.insurer_name,
            "plan_name": new_policy.plan_name,
            "sum_assured": float(new_policy.sum_assured) if new_policy.sum_assured else 0.0,
            "premium_amount": float(new_policy.premium_amount) if new_policy.premium_amount else 0.0,
            "start_date": new_policy.start_date.isoformat() if new_policy.start_date else None,
            "end_date": new_policy.end_date.isoformat() if new_policy.end_date else None,
            "issue_date": new_policy.issue_date.isoformat() if new_policy.issue_date else None,
            "expiry_date": new_policy.expiry_date.isoformat() if new_policy.expiry_date else None,
            "status": new_policy.status,
        }

    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create policy: {str(e)}"
        )

@router.put("/{policy_id}")
async def update_policy(
    policy_id: str,
    policy_data: Dict[str, Any],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update an existing policy.
    """
    
    try:
        agent_id = current_user.id
        
        # Get existing policy
        policy_query = select(Policy).where(
            Policy.id == int(policy_id),
            Policy.agent_id == agent_id
        )
        policy_result = await db.execute(policy_query)
        policy = policy_result.scalars().first()
        
        if not policy:
            raise HTTPException(
                status_code=404,
                detail="Policy not found"
            )
        
        # Update policy fields
        for field, value in policy_data.items():
            if hasattr(policy, field) and value is not None:
                if field == "customer_id":
                    # Verify new customer belongs to agent
                    customer_query = select(Customer).where(
                        Customer.id == int(value),
                        Customer.agent_id == agent_id
                    )
                    customer_result = await db.execute(customer_query)
                    customer = customer_result.scalars().first()
                    
                    if not customer:
                        raise HTTPException(
                            status_code=404,
                            detail="Customer not found or access denied"
                        )
                    setattr(policy, field, int(value))
                else:
                    setattr(policy, field, value)
        
        await db.commit()
        await db.refresh(policy)
        
        return {
            "id": str(policy.id),
            "policy_number": policy.policy_number,
            "policy_type": policy.policy_type,
            "insurer_name": policy.insurer_name,
            "plan_name": policy.plan_name,
            "sum_assured": float(policy.sum_assured) if policy.sum_assured else 0.0,
            "premium_amount": float(policy.premium_amount) if policy.premium_amount else 0.0,
            "start_date": policy.start_date.isoformat() if policy.start_date else None,
            "end_date": policy.end_date.isoformat() if policy.end_date else None,
            "status": policy.status,
        }
        
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="Invalid policy ID format"
        )
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update policy: {str(e)}"
        )

# ── DELETE policy ─────────────────────────────────────────────────────────────
@router.delete("/{policy_id}")
async def delete_policy(
    policy_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    is_uuid = False
    try:
        import uuid
        uuid.UUID(policy_id)
        is_uuid = True
    except ValueError:
        pass

    try:
        if is_uuid:
            policy = (await db.execute(
                select(PolicyV2).where(
                    PolicyV2.id == policy_id,
                    PolicyV2.agent_id == current_user.id
                )
            )).scalars().first()
        else:
            policy = (await db.execute(
                select(Policy).where(
                    Policy.id == int(policy_id),
                    Policy.agent_id == current_user.id
                )
            )).scalars().first()

        if not policy:
            raise HTTPException(status_code=404, detail="Policy not found")

        await db.delete(policy)
        await db.commit()
        return {"message": "Policy deleted successfully"}

    except HTTPException:
        raise
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid policy ID format")
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete policy: {str(e)}")
