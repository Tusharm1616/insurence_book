"""
Customer Documents API — Upload, list, and delete documents for a customer.
"""
import os
import uuid as uuid_mod
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models.users import User
from models.customers import Customer
from models.customer_document import CustomerDocument
from utils.auth import get_current_user

router = APIRouter(prefix="/api/customers", tags=["Customer Documents"])

# ── Constants ─────────────────────────────────────────────────────────────────
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
ALLOWED_DOCUMENT_TYPES = {"Aadhaar", "PAN", "Driving Licence", "RC Book", "Other", "New Policy", "Renewal Policy", "Claim Document"}
ALLOWED_CONTENT_TYPES = {
    "application/pdf",
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
}
UPLOADS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "uploads", "documents")


def _is_cloudinary_configured() -> bool:
    return bool(
        os.environ.get("CLOUDINARY_URL")
        or (
            os.environ.get("CLOUDINARY_CLOUD_NAME")
            and os.environ.get("CLOUDINARY_API_KEY")
            and os.environ.get("CLOUDINARY_API_SECRET")
        )
    )


async def _upload_to_cloudinary(file_content: bytes, filename: str) -> str:
    import cloudinary
    import cloudinary.uploader

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
        folder="insurebook/customer_documents",
        public_id=filename,
    )
    return result["secure_url"]


async def _upload_to_local(file_content: bytes, filename: str) -> str:
    os.makedirs(UPLOADS_DIR, exist_ok=True)
    unique_name = f"{uuid_mod.uuid4().hex}_{filename}"
    file_path = os.path.join(UPLOADS_DIR, unique_name)
    with open(file_path, "wb") as f:
        f.write(file_content)
    return f"/uploads/documents/{unique_name}"


async def _delete_from_local(file_url: str) -> None:
    """Delete a locally stored file given its URL path."""
    if file_url and file_url.startswith("/uploads/documents/"):
        filename = file_url.replace("/uploads/documents/", "")
        file_path = os.path.join(UPLOADS_DIR, filename)
        if os.path.exists(file_path):
            os.remove(file_path)


async def _delete_from_cloudinary(file_url: str) -> None:
    """Delete a file from Cloudinary given its URL."""
    try:
        import cloudinary
        import cloudinary.uploader

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
        # Extract public_id from URL
        # e.g. https://res.cloudinary.com/.../insurebook/customer_documents/filename
        parts = file_url.split("insurebook/customer_documents/")
        if len(parts) > 1:
            public_id = f"insurebook/customer_documents/{parts[1]}"
            cloudinary.uploader.destroy(public_id, resource_type="raw")
    except Exception:
        pass  # Best effort deletion


# ── POST upload document ──────────────────────────────────────────────────────
@router.post("/{customer_id}/documents")
async def upload_customer_document(
    customer_id: int,
    document_type: str = Form(...),
    file: UploadFile = File(...),
    notes: str = Form(""),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Upload a document for a customer."""

    # Validate document type
    if document_type not in ALLOWED_DOCUMENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid document_type. Must be one of: {', '.join(ALLOWED_DOCUMENT_TYPES)}",
        )

    # Validate content type
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be PDF or image (JPEG, PNG, WebP)",
        )

    # Read and validate size
    file_content = await file.read()
    if len(file_content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File size must be under 10MB",
        )

    # Verify customer belongs to agent
    customer = (await db.execute(
        select(Customer).where(
            Customer.id == customer_id,
            Customer.agent_id == current_user.id,
        )
    )).scalars().first()

    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    # Upload file
    filename = file.filename or f"doc_{uuid_mod.uuid4().hex}"
    if _is_cloudinary_configured():
        file_url = await _upload_to_cloudinary(file_content, filename)
    else:
        file_url = await _upload_to_local(file_content, filename)

    # Save to database
    doc = CustomerDocument(
        customer_id=customer.id,
        agent_id=current_user.id,
        document_type=document_type,
        document_name=file.filename or filename,
        file_url=file_url,
        file_size=len(file_content),
        notes=notes.strip() if notes else "",
    )
    db.add(doc)
    await db.commit()
    await db.refresh(doc)

    return {
        "id": str(doc.id),
        "document_type": doc.document_type,
        "document_name": doc.document_name,
        "file_url": doc.file_url,
        "file_size": doc.file_size,
        "notes": doc.notes or "",
        "uploaded_at": doc.uploaded_at.isoformat() if doc.uploaded_at else None,
    }


# ── GET list documents ────────────────────────────────────────────────────────
@router.get("/{customer_id}/documents")
async def get_customer_documents(
    customer_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all documents for a customer."""

    # Verify customer belongs to agent
    customer = (await db.execute(
        select(Customer).where(
            Customer.id == customer_id,
            Customer.agent_id == current_user.id,
        )
    )).scalars().first()

    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    # Fetch documents
    result = await db.execute(
        select(CustomerDocument)
        .where(CustomerDocument.customer_id == customer.id)
        .order_by(CustomerDocument.uploaded_at.desc())
    )
    documents = result.scalars().all()

    return [
        {
            "id": str(doc.id),
            "document_type": doc.document_type,
            "document_name": doc.document_name,
            "file_url": doc.file_url,
            "file_size": doc.file_size,
            "notes": doc.notes or "",
            "uploaded_at": doc.uploaded_at.isoformat() if doc.uploaded_at else None,
        }
        for doc in documents
    ]


# ── DELETE document ───────────────────────────────────────────────────────────
@router.delete("/{customer_id}/documents/{doc_id}")
async def delete_customer_document(
    customer_id: int,
    doc_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a document."""

    # Verify customer belongs to agent
    customer = (await db.execute(
        select(Customer).where(
            Customer.id == customer_id,
            Customer.agent_id == current_user.id,
        )
    )).scalars().first()

    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    # Find the document
    try:
        doc_uuid = uuid_mod.UUID(doc_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid document ID")

    doc = (await db.execute(
        select(CustomerDocument).where(
            CustomerDocument.id == doc_uuid,
            CustomerDocument.customer_id == customer.id,
        )
    )).scalars().first()

    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    # Delete from storage
    if _is_cloudinary_configured():
        await _delete_from_cloudinary(doc.file_url)
    else:
        await _delete_from_local(doc.file_url)

    # Delete from DB
    await db.delete(doc)
    await db.commit()

    return {"message": "Document deleted successfully", "id": doc_id}
