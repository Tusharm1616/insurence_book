import logging
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from database import get_db
from models.users import User
from utils.auth import get_current_user
from utils.qr_generator import generate_upi_qr
from schemas.bank_details import BankDetailsResponse, BankDetailsUpdate

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/agent", tags=["Agent Bank Details"])


async def _ensure_qr_code_url_is_text(db: AsyncSession):
    """Ensure qr_code_url column is TEXT, not VARCHAR(500)."""
    try:
        result = await db.execute(text(
            "SELECT data_type, character_maximum_length FROM information_schema.columns "
            "WHERE table_name='users' AND column_name='qr_code_url'"
        ))
        row = result.fetchone()
        if row and row[0] == 'character varying':
            # Column is VARCHAR — alter to TEXT
            await db.execute(text("ALTER TABLE users ALTER COLUMN qr_code_url TYPE TEXT"))
            await db.commit()
            logger.info("Altered qr_code_url column from VARCHAR to TEXT")
    except Exception as e:
        logger.warning(f"Could not check/alter qr_code_url column type: {e}")
        await db.rollback()


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
    try:
        # Ensure column can hold base64 data
        await _ensure_qr_code_url_is_text(db)

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
    except Exception as e:
        await db.rollback()
        logger.error(f"Failed to update bank details: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update bank details: {str(e)}"
        )
