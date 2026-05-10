from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func
from typing import List, Optional
from datetime import date, timedelta

from database import get_db
from models.users import User, UserRole
from models.customers import Customer
from models.policies import Policy
from schemas.policies import PolicyCreate, PolicyResponse
from utils.auth import get_current_user

router = APIRouter(prefix="/policies", tags=["Policies"])

# ── Company code lookup ──────────────────────────────────────────────────────
_COMPANY_CODES = {
    'lic': 'LIC',
    'hdfc ergo': 'HDFC',
    'hdfc life': 'HDFL',
    'sbi life': 'SBIL',
    'sbi general': 'SBIG',
    'tata aia': 'TATA',
    'icici lombard': 'ICICI',
    'icici prudential': 'ICICIP',
    'star health': 'STAR',
    'bajaj allianz': 'BJAJ',
    'reliance general': 'RLG',
    'new india assurance': 'NIA',
    'united india insurance': 'UII',
    'national insurance': 'NIC',
    'oriental insurance': 'OIC',
    'kotak mahindra life': 'KOTAK',
    'max life': 'MAX',
    'pnb metlife': 'PNB',
    'digit insurance': 'DIGIT',
    'acko general': 'ACKO',
    'niva bupa': 'NIVA',
    'care health': 'CARE',
}

# ── Policy type codes ────────────────────────────────────────────────────────
_TYPE_CODES = {
    'life': 'LF',
    'health': 'HL',
    'motor': 'MT',
    'two wheeler': 'TW',
    'travel': 'TR',
    'home': 'HM',
    'business': 'BS',
    'shop/commercial': 'SC',
    'shop / commercial': 'SC',
    'accident': 'AC',
    'term': 'TM',
    'wc insurance': 'WC',
    'other': 'OT',
}


def _get_company_code(insurer_name: Optional[str]) -> str:
    if not insurer_name:
        return 'INS'
    key = insurer_name.strip().lower()
    for k, v in _COMPANY_CODES.items():
        if k in key:
            return v
    # Use first 4 chars of the name in uppercase
    return insurer_name.upper().replace(' ', '')[:4]


def _get_type_code(policy_type: Optional[str]) -> str:
    if not policy_type:
        return 'PL'
    key = policy_type.strip().lower()
    for k, v in _TYPE_CODES.items():
        if k in key:
            return v
    return policy_type.upper()[:2]


def _looks_random(policy_number: str) -> bool:
    """Return True if the policy number looks like a random / invalid entry."""
    if not policy_number or len(policy_number) < 4:
        return True
    # If it has no uppercase letters or digits, it's likely junk
    has_digit = any(c.isdigit() for c in policy_number)
    has_upper_or_dash = any(c.isupper() or c == '-' for c in policy_number)
    # Very short numbers without structure are suspicious
    if len(policy_number) < 8 and not has_digit:
        return True
    # All lowercase with no digits = likely junk (e.g. "134wjsjnd")
    if policy_number.islower() and not has_digit:
        return True
    return False


async def _generate_policy_number(
    db: AsyncSession,
    agent_id: int,
    insurer_name: Optional[str],
    policy_type: Optional[str],
    year: int,
) -> str:
    """Generate a professional policy number: COMPANY-YEAR-TYPE-SEQUENCE"""
    company_code = _get_company_code(insurer_name)
    type_code = _get_type_code(policy_type)

    # Count existing policies for this agent with same company+type this year
    result = await db.execute(
        select(func.count(Policy.id)).where(
            Policy.agent_id == agent_id,
            Policy.policy_number.like(f"{company_code}-{year}-{type_code}-%"),
        )
    )
    count = result.scalar() or 0
    seq = 1001 + count  # Start at 1001 for professional look
    return f"{company_code}-{year}-{type_code}-{seq}"


def _compute_status(policy: Policy) -> str:
    """Compute display status from dates — always accurate."""
    today = date.today()

    if policy.expiry_date and policy.expiry_date < today:
        return 'expired'

    if policy.expiry_date and policy.expiry_date <= today + timedelta(days=30):
        return 'expiring_soon'

    if policy.premium_due_date and policy.premium_due_date < today:
        stored = (policy.status or '').lower()
        if stored in ('lapsed', 'matured', 'cancelled'):
            return stored
        return 'premium_due'

    # Return stored status (normalized)
    stored = (policy.status or 'active').lower()
    # Map legacy aliases to canonical
    return {
        'live': 'active',
        'running': 'active',
    }.get(stored, stored)


def _policy_to_response(policy: Policy) -> dict:
    return {
        "id": policy.id,
        "agent_id": policy.agent_id,
        "customer_id": policy.customer_id,
        "customer_name": policy.customer.full_name if policy.customer else None,
        "policy_number": policy.policy_number,
        "policy_type": policy.policy_type,
        "insurer_name": policy.insurer_name,
        "plan_name": policy.plan_name,
        "sum_assured": policy.sum_assured or 0.0,
        "premium_amount": policy.premium_amount or 0.0,
        "issue_date": policy.issue_date,
        "expiry_date": policy.expiry_date,
        "premium_due_date": policy.premium_due_date,
        "maturity_date": policy.maturity_date,
        "status": policy.status,
        "computed_status": _compute_status(policy),
        "ncb_percent": policy.ncb_percent or 0.0,
        "vehicle_reg_no": policy.vehicle_reg_no,
        "nominee_name": policy.nominee_name,
        "nominee_relation": policy.nominee_relation,
    }


# ── POST /policies/ ──────────────────────────────────────────────────────────
@router.post("/", response_model=dict)
async def create_policy(
    policy_in: PolicyCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Only agents can create policies")

    # Verify the customer belongs to this agent
    result = await db.execute(
        select(Customer).where(Customer.id == policy_in.customer_id)
    )
    customer = result.scalars().first()

    if not customer or customer.agent_id != current_user.id:
        raise HTTPException(status_code=404, detail="Customer not found or access denied")

    # Determine policy number
    policy_number = policy_in.policy_number.strip()
    if _looks_random(policy_number):
        # Auto-generate professional policy number
        policy_number = await _generate_policy_number(
            db,
            current_user.id,
            policy_in.insurer_name,
            policy_in.policy_type,
            policy_in.issue_date.year if policy_in.issue_date else date.today().year,
        )

    # Ensure uniqueness (retry up to 5 times if collision)
    for attempt in range(5):
        existing = await db.execute(
            select(Policy).where(Policy.policy_number == policy_number)
        )
        if not existing.scalars().first():
            break
        if attempt == 4:
            raise HTTPException(
                status_code=409,
                detail=f"Policy number '{policy_number}' already exists. Please use a different one."
            )
        # Append suffix to make it unique
        policy_number = f"{policy_number}-{attempt + 2}"

    # Resolve status
    raw_status = policy_in.status.strip().lower()
    status_map = {'live': 'active', 'running': 'active', 'activee': 'active'}
    status = status_map.get(raw_status, raw_status)

    new_policy = Policy(
        customer_id=policy_in.customer_id,
        agent_id=current_user.id,
        policy_number=policy_number,
        policy_type=policy_in.policy_type,
        status=status,
        insurer_name=policy_in.insurer_name,
        plan_name=policy_in.plan_name,
        premium_amount=policy_in.premium_amount or 0.0,
        premium_due_date=policy_in.premium_due_date,
        issue_date=policy_in.issue_date,
        expiry_date=policy_in.expiry_date,
        maturity_date=policy_in.maturity_date,
        sum_assured=policy_in.sum_assured or 0.0,
        ncb_percent=policy_in.ncb_percent or 0.0,
        vehicle_reg_no=policy_in.vehicle_reg_no,
        nominee_name=policy_in.nominee_name,
        nominee_relation=policy_in.nominee_relation,
    )

    db.add(new_policy)
    await db.commit()
    await db.refresh(new_policy)

    # Reload with customer relationship
    await db.refresh(new_policy, ["customer"])
    return _policy_to_response(new_policy)


# ── GET /policies/ ───────────────────────────────────────────────────────────
@router.get("/", response_model=List[dict])
async def list_policies(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    status: Optional[str] = Query(None, description="Filter by computed status"),
    policy_type: Optional[str] = Query(None, description="Filter by policy type"),
    search: Optional[str] = Query(None, description="Search policy number or customer name"),
):
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Access denied")

    query = (
        select(Policy)
        .where(Policy.agent_id == current_user.id)
        .order_by(Policy.expiry_date.asc())
    )

    # Apply DB-level filters
    if policy_type:
        query = query.where(Policy.policy_type.ilike(f"%{policy_type}%"))

    result = await db.execute(query)
    policies = result.scalars().all()

    # Eager-load customers (already loaded via relationship if joined, else fetch)
    output = []
    for p in policies:
        try:
            await db.refresh(p, ["customer"])
        except Exception:
            pass

        computed = _compute_status(p)

        # Apply computed status filter (after date-based computation)
        if status and computed != status.lower():
            continue

        row = _policy_to_response(p)

        # Apply search filter
        if search:
            s = search.lower()
            policy_no = (row.get("policy_number") or "").lower()
            cust_name = (row.get("customer_name") or "").lower()
            insurer = (row.get("insurer_name") or "").lower()
            if s not in policy_no and s not in cust_name and s not in insurer:
                continue

        output.append(row)

    return output
