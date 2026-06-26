from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models.users import User
from utils.auth import get_current_user
from utils.qr_generator import generate_upi_qr
from schemas.bank_details import BankDetailsResponse, BankDetailsUpdate

router = APIRouter(prefix="/api/agent", tags=["Agent Bank Details"])


@router.get("/bank-details", response_model=BankDetailsResponse)
async def get_bank_details(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return the current agent's bank details."""
    return BankDetailsResponse(
        upi_id=current_user.upi_id,
        bank_name=current_user.bank_name,
        account_number=current_user.account_number,
        ifsc_code=current_user.ifsc_code,
        branch_name=current_user.branch_name,
        qr_code_url=current_user.qr_code_url,
    )


@router.put("/bank-details", response_model=BankDetailsResponse)
async def update_bank_details(
    payload: BankDetailsUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update the current agent's bank details and regenerate QR code."""
    current_user.upi_id = payload.upi_id
    current_user.bank_name = payload.bank_name
    current_user.account_number = payload.account_number
    current_user.ifsc_code = payload.ifsc_code
    current_user.branch_name = payload.branch_name

    # Generate QR code from UPI ID (returns None if upi_id is empty/null)
    current_user.qr_code_url = generate_upi_qr(payload.upi_id)

    await db.commit()
    await db.refresh(current_user)

    return BankDetailsResponse(
        upi_id=current_user.upi_id,
        bank_name=current_user.bank_name,
        account_number=current_user.account_number,
        ifsc_code=current_user.ifsc_code,
        branch_name=current_user.branch_name,
        qr_code_url=current_user.qr_code_url,
    )
