from pydantic import BaseModel, Field
from typing import Optional


class BankDetailsResponse(BaseModel):
    upi_id: Optional[str] = None
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    ifsc_code: Optional[str] = None
    branch_name: Optional[str] = None
    qr_code_url: Optional[str] = None


class BankDetailsUpdate(BaseModel):
    upi_id: Optional[str] = Field(None, max_length=100)
    bank_name: Optional[str] = Field(None, max_length=100)
    account_number: Optional[str] = Field(None, max_length=30)
    ifsc_code: Optional[str] = Field(None, max_length=11)
    branch_name: Optional[str] = Field(None, max_length=100)
