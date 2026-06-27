from uuid import UUID as PyUUID
from datetime import datetime, timezone
import os
import uuid as uuid_mod

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, status
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func
import math

from database import get_db
from models.users import User
from models.customers import Customer
from models.policy_v2 import PolicyV2
from schemas.policies_v2 import (
    PolicyV2Create,
    PolicyV2Update,
    PolicyV2Response,
    PolicyV2ListItem,
    PolicyV2ListResponse,
)
from utils.auth import get_current_user
from utils.commission import calculate_commission

router = APIRouter(prefix="/api/policies-v2", tags=["Policies V2"])


@router.post("/", response_model=PolicyV2Response, status_code=status.HTTP_201_CREATED)
async def create_policy(
    policy_in: PolicyV2Create,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new policy. Agent is set from authenticated user."""

    # 1. Verify customer belongs to the authenticated agent
    result = await db.execute(
        select(Customer).where(Customer.id == policy_in.customer_id)
    )
    customer = result.scalars().first()

    if not customer or customer.agent_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer not found",
        )

    # 1.5 Auto-generate policy number if missing
    policy_number = policy_in.policy_number
    if not policy_number:
        # e.g. LI20260627102030A9
        policy_number = f"{policy_in.insurance_type[:2].upper()}{datetime.now().strftime('%Y%m%d%H%M%S')}{uuid_mod.uuid4().hex[:4].upper()}"

    # 2. Check for duplicate policy_number
    existing = await db.execute(
        select(PolicyV2).where(PolicyV2.policy_number == policy_number)
    )
    if existing.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Policy number already exists",
        )

    # 3. Compute commission
    commission_amount = calculate_commission(
        policy_in.final_amount, policy_in.commission_percent
    )

    # 4. Create the policy record
    new_policy = PolicyV2(
        customer_id=policy_in.customer_id,
        agent_id=current_user.id,
        policy_number=policy_number,
        insurance_company=policy_in.insurance_company,
        insurance_type=policy_in.insurance_type,
        start_date=policy_in.start_date,
        end_date=policy_in.end_date,
        total_amount=policy_in.total_amount,
        discount_amount=policy_in.discount_amount,
        final_amount=policy_in.final_amount,
        payment_mode=policy_in.payment_mode,
        payment_date=policy_in.payment_date,
        inspection_date=policy_in.inspection_date,
        inspection_status=policy_in.inspection_status,
        claim_status=policy_in.claim_status,
        claim_amount=policy_in.claim_amount,
        claim_notes=policy_in.claim_notes,
        ref_by=policy_in.ref_by,
        commission_percent=policy_in.commission_percent,
        commission_amount=commission_amount,
    )

    db.add(new_policy)
    await db.commit()
    await db.refresh(new_policy)

    # 5. Build response with customer_name
    return PolicyV2Response(
        id=new_policy.id,
        customer_id=new_policy.customer_id,
        customer_name=customer.full_name if customer else None,
        agent_id=new_policy.agent_id,
        policy_number=new_policy.policy_number,
        insurance_company=new_policy.insurance_company,
        insurance_type=new_policy.insurance_type,
        start_date=new_policy.start_date,
        end_date=new_policy.end_date,
        total_amount=new_policy.total_amount,
        discount_amount=new_policy.discount_amount,
        final_amount=new_policy.final_amount,
        payment_mode=new_policy.payment_mode,
        payment_date=new_policy.payment_date,
        inspection_date=new_policy.inspection_date,
        inspection_status=new_policy.inspection_status,
        claim_status=new_policy.claim_status,
        claim_amount=new_policy.claim_amount,
        claim_notes=new_policy.claim_notes,
        ref_by=new_policy.ref_by,
        commission_percent=new_policy.commission_percent,
        commission_amount=new_policy.commission_amount,
        policy_pdf_url=new_policy.policy_pdf_url,
        last_year_policy_pdf_url=new_policy.last_year_policy_pdf_url,
        is_active=new_policy.is_active,
        created_at=new_policy.created_at,
        updated_at=new_policy.updated_at,
    )


@router.get("/", response_model=PolicyV2ListResponse)
async def list_policies(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List agent's active policies with pagination and customer name join."""

    # Base filter: agent's own active policies
    base_filter = (PolicyV2.agent_id == current_user.id) & (PolicyV2.is_active == True)

    # 1. Get total count
    count_query = select(func.count()).select_from(PolicyV2).where(base_filter)
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    # 2. Calculate pagination
    pages = math.ceil(total / limit) if total > 0 else 0
    offset = (page - 1) * limit

    # 3. Query policies with left join to customers for customer_name
    query = (
        select(
            PolicyV2,
            func.coalesce(Customer.full_name, "Unknown").label("customer_name"),
        )
        .outerjoin(Customer, PolicyV2.customer_id == Customer.id)
        .where(base_filter)
        .order_by(PolicyV2.created_at.desc())
        .offset(offset)
        .limit(limit)
    )

    result = await db.execute(query)
    rows = result.all()

    # 4. Build response items
    data = [
        PolicyV2ListItem(
            id=policy.id,
            policy_number=policy.policy_number,
            insurance_company=policy.insurance_company,
            insurance_type=policy.insurance_type,
            customer_name=customer_name,
            start_date=policy.start_date,
            end_date=policy.end_date,
            total_amount=policy.total_amount,
            final_amount=policy.final_amount,
        )
        for policy, customer_name in rows
    ]

    return PolicyV2ListResponse(
        total=total,
        page=page,
        pages=pages,
        data=data,
    )


@router.get("/{id}", response_model=PolicyV2Response)
async def get_policy_detail(
    id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a single policy by ID. Validates UUID format, checks ownership."""

    # 1. Validate UUID format
    try:
        policy_uuid = PyUUID(id)
    except (ValueError, AttributeError):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invalid policy ID format",
        )

    # 2. Query the policy with a left join on Customer for name resolution
    result = await db.execute(
        select(PolicyV2, Customer.full_name)
        .outerjoin(Customer, PolicyV2.customer_id == Customer.id)
        .where(
            PolicyV2.id == policy_uuid,
            PolicyV2.agent_id == current_user.id,
            PolicyV2.is_active == True,
        )
    )
    row = result.first()

    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Policy not found",
        )

    policy, customer_name = row

    # 3. Build and return the full response
    return PolicyV2Response(
        id=policy.id,
        customer_id=policy.customer_id,
        customer_name=customer_name,  # null if customer doesn't exist
        agent_id=policy.agent_id,
        policy_number=policy.policy_number,
        insurance_company=policy.insurance_company,
        insurance_type=policy.insurance_type,
        start_date=policy.start_date,
        end_date=policy.end_date,
        total_amount=policy.total_amount,
        discount_amount=policy.discount_amount,
        final_amount=policy.final_amount,
        payment_mode=policy.payment_mode,
        payment_date=policy.payment_date,
        inspection_date=policy.inspection_date,
        inspection_status=policy.inspection_status,
        claim_status=policy.claim_status,
        claim_amount=policy.claim_amount,
        claim_notes=policy.claim_notes,
        ref_by=policy.ref_by,
        commission_percent=policy.commission_percent,
        commission_amount=policy.commission_amount,
        policy_pdf_url=policy.policy_pdf_url,
        last_year_policy_pdf_url=policy.last_year_policy_pdf_url,
        is_active=policy.is_active,
        created_at=policy.created_at,
        updated_at=policy.updated_at,
    )


@router.delete("/{id}", status_code=status.HTTP_200_OK)
async def delete_policy(
    id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Soft-delete a policy by setting is_active to false."""

    # 1. Validate UUID format
    try:
        policy_id = PyUUID(id)
    except (ValueError, AttributeError):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid policy ID format",
        )

    # 2. Look up policy belonging to agent and currently active
    result = await db.execute(
        select(PolicyV2).where(
            PolicyV2.id == policy_id,
            PolicyV2.agent_id == current_user.id,
            PolicyV2.is_active == True,
        )
    )
    policy = result.scalars().first()

    if not policy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Policy not found",
        )

    # 3. Soft-delete: set is_active = False and update updated_at
    policy.is_active = False
    policy.updated_at = datetime.now(timezone.utc)

    try:
        await db.commit()
    except Exception:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Deletion failed, please try again",
        )

    return {"id": str(policy_id), "message": "Policy deleted successfully"}


@router.put("/{id}", response_model=PolicyV2Response)
async def update_policy(
    id: str,
    policy_in: PolicyV2Update,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update an existing policy. Recalculates commission when financial fields change."""

    # 1. Validate UUID format
    try:
        policy_uuid = PyUUID(id)
    except (ValueError, AttributeError):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invalid policy ID format",
        )

    # 2. Check if body has at least one field provided
    update_data = policy_in.model_dump(exclude_unset=True)
    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one valid field must be provided",
        )

    # 3. Look up policy belonging to agent and currently active
    result = await db.execute(
        select(PolicyV2).where(
            PolicyV2.id == policy_uuid,
            PolicyV2.agent_id == current_user.id,
            PolicyV2.is_active == True,
        )
    )
    policy = result.scalars().first()

    if not policy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Policy not found",
        )

    # 4. Apply updates to the policy record
    for field, value in update_data.items():
        setattr(policy, field, value)

    # 5. Recalculate commission if final_amount or commission_percent changed
    if "final_amount" in update_data or "commission_percent" in update_data:
        # Use updated value if provided, otherwise use stored value
        effective_final_amount = policy.final_amount
        effective_commission_percent = policy.commission_percent
        policy.commission_amount = calculate_commission(
            effective_final_amount, effective_commission_percent
        )

    # 6. Update the updated_at timestamp
    policy.updated_at = datetime.now(timezone.utc)

    await db.commit()
    await db.refresh(policy)

    # 7. Resolve customer_name via join
    customer_name = None
    if policy.customer_id:
        cust_result = await db.execute(
            select(Customer.full_name).where(Customer.id == policy.customer_id)
        )
        customer_name = cust_result.scalar()

    # 8. Return full response
    return PolicyV2Response(
        id=policy.id,
        customer_id=policy.customer_id,
        customer_name=customer_name,
        agent_id=policy.agent_id,
        policy_number=policy.policy_number,
        insurance_company=policy.insurance_company,
        insurance_type=policy.insurance_type,
        start_date=policy.start_date,
        end_date=policy.end_date,
        total_amount=policy.total_amount,
        discount_amount=policy.discount_amount,
        final_amount=policy.final_amount,
        payment_mode=policy.payment_mode,
        payment_date=policy.payment_date,
        inspection_date=policy.inspection_date,
        inspection_status=policy.inspection_status,
        claim_status=policy.claim_status,
        claim_amount=policy.claim_amount,
        claim_notes=policy.claim_notes,
        ref_by=policy.ref_by,
        commission_percent=policy.commission_percent,
        commission_amount=policy.commission_amount,
        policy_pdf_url=policy.policy_pdf_url,
        last_year_policy_pdf_url=policy.last_year_policy_pdf_url,
        is_active=policy.is_active,
        created_at=policy.created_at,
        updated_at=policy.updated_at,
    )


# ── Maximum file size for PDF uploads: 10MB ──────────────────────────────────
MAX_PDF_SIZE = 10 * 1024 * 1024  # 10 MB in bytes
ALLOWED_PDF_TYPES = {"current", "last_year"}
UPLOADS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "uploads")


def _is_cloudinary_configured() -> bool:
    """Check if Cloudinary environment variables are configured."""
    return bool(
        os.environ.get("CLOUDINARY_URL")
        or (
            os.environ.get("CLOUDINARY_CLOUD_NAME")
            and os.environ.get("CLOUDINARY_API_KEY")
            and os.environ.get("CLOUDINARY_API_SECRET")
        )
    )


async def _upload_to_cloudinary(file_content: bytes, filename: str) -> str:
    """Upload file bytes to Cloudinary and return the secure URL."""
    import cloudinary
    import cloudinary.uploader

    # Configure from env if not already done
    if not cloudinary.config().cloud_name:
        cloudinary_url = os.environ.get("CLOUDINARY_URL")
        if cloudinary_url:
            cloudinary.config(cloudinary_url=cloudinary_url)
        else:
            cloudinary.config(
                cloud_name=os.environ.get("CLOUDINARY_CLOUD_NAME"),
                api_key=os.environ.get("CLOUDINARY_API_KEY"),
                api_secret=os.environ.get("CLOUDINARY_API_SECRET"),
            )

    result = cloudinary.uploader.upload(
        file_content,
        resource_type="raw",
        folder="insurebook/policies",
        public_id=filename,
    )
    return result["secure_url"]


async def _upload_to_local(file_content: bytes, filename: str) -> str:
    """Save file to local uploads/ directory and return the relative URL path."""
    os.makedirs(UPLOADS_DIR, exist_ok=True)

    # Generate a unique filename to avoid collisions
    unique_name = f"{uuid_mod.uuid4().hex}_{filename}"
    file_path = os.path.join(UPLOADS_DIR, unique_name)

    with open(file_path, "wb") as f:
        f.write(file_content)

    # Return a URL-style path that can be served statically
    return f"/uploads/{unique_name}"


@router.post("/{id}/upload-pdf")
async def upload_policy_pdf(
    id: str,
    type: str = Query(..., description="PDF type: 'current' or 'last_year'"),
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Upload a PDF document for a policy (current or last year)."""

    # 1. Validate the 'type' query parameter
    if type not in ALLOWED_PDF_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Type must be 'current' or 'last_year'",
        )

    # 2. Validate content type is PDF
    if file.content_type != "application/pdf":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be PDF and under 10MB",
        )

    # 3. Read file content and validate size
    file_content = await file.read()
    if len(file_content) > MAX_PDF_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be PDF and under 10MB",
        )

    # 4. Validate UUID format
    try:
        policy_uuid = PyUUID(id)
    except (ValueError, AttributeError):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Policy not found",
        )

    # 5. Look up policy belonging to agent and currently active
    result = await db.execute(
        select(PolicyV2).where(
            PolicyV2.id == policy_uuid,
            PolicyV2.agent_id == current_user.id,
            PolicyV2.is_active == True,
        )
    )
    policy = result.scalars().first()

    if not policy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Policy not found",
        )

    # 6. Upload file to storage backend
    filename = file.filename or f"policy_{id}.pdf"
    if _is_cloudinary_configured():
        file_url = await _upload_to_cloudinary(file_content, filename)
    else:
        file_url = await _upload_to_local(file_content, filename)

    # 7. Update the appropriate URL field on the policy record
    if type == "current":
        policy.policy_pdf_url = file_url
    else:
        policy.last_year_policy_pdf_url = file_url

    policy.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(policy)

    # 8. Return the updated URL
    if type == "current":
        return {"policy_pdf_url": file_url}
    else:
        return {"last_year_policy_pdf_url": file_url}
