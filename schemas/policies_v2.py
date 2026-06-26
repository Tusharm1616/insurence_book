from pydantic import BaseModel, Field, field_validator
from typing import Optional, List, Literal
from datetime import date, datetime
from decimal import Decimal
from uuid import UUID


# ── Valid values ────────────────────────────────────────────────────────────
VALID_INSURANCE_TYPES = {"Life", "Motor", "Health", "Travel", "Other"}
VALID_PAYMENT_MODES = {"Cash", "Online", "Cheque", "EMI"}
VALID_INSPECTION_STATUSES = {"Pending", "Passed", "Failed", "NA"}
VALID_CLAIM_STATUSES = {"No Claim", "Claimed", "Pending"}


# ── Request Schemas ─────────────────────────────────────────────────────────

class PolicyV2Create(BaseModel):
    customer_id: int
    policy_number: str = Field(..., min_length=1, max_length=50)
    insurance_company: Optional[str] = Field(default=None, max_length=100)
    insurance_type: Literal["Life", "Motor", "Health", "Travel", "Other"]
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    total_amount: Optional[Decimal] = Field(default=None, ge=Decimal("0.01"), le=Decimal("99999999.99"))
    discount_amount: Optional[Decimal] = Field(default=Decimal("0"), ge=Decimal("0"), le=Decimal("99999999.99"))
    final_amount: Optional[Decimal] = Field(default=None, ge=Decimal("0"), le=Decimal("99999999.99"))
    payment_mode: Optional[Literal["Cash", "Online", "Cheque", "EMI"]] = None
    payment_date: Optional[date] = None
    inspection_date: Optional[date] = None
    inspection_status: Optional[Literal["Pending", "Passed", "Failed", "NA"]] = "NA"
    claim_status: Optional[Literal["No Claim", "Claimed", "Pending"]] = "No Claim"
    claim_amount: Optional[Decimal] = Field(default=None, ge=Decimal("0"), le=Decimal("99999999.99"))
    claim_notes: Optional[str] = Field(default=None, max_length=1000)
    ref_by: Optional[str] = Field(default=None, max_length=150)
    commission_percent: Optional[Decimal] = Field(default=Decimal("0"), ge=Decimal("0"), le=Decimal("100"))

    @field_validator('policy_number')
    @classmethod
    def policy_number_not_empty(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError('policy_number must not be empty')
        return v.strip()

    @field_validator('insurance_type')
    @classmethod
    def validate_insurance_type(cls, v: str) -> str:
        if v not in VALID_INSURANCE_TYPES:
            raise ValueError(f'insurance_type must be one of: {", ".join(sorted(VALID_INSURANCE_TYPES))}')
        return v


class PolicyV2Update(BaseModel):
    customer_id: Optional[int] = None
    policy_number: Optional[str] = Field(default=None, max_length=50)
    insurance_company: Optional[str] = Field(default=None, max_length=100)
    insurance_type: Optional[Literal["Life", "Motor", "Health", "Travel", "Other"]] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    total_amount: Optional[Decimal] = Field(default=None, ge=Decimal("0"), le=Decimal("99999999.99"))
    discount_amount: Optional[Decimal] = Field(default=None, ge=Decimal("0"), le=Decimal("99999999.99"))
    final_amount: Optional[Decimal] = Field(default=None, ge=Decimal("0"), le=Decimal("99999999.99"))
    payment_mode: Optional[Literal["Cash", "Online", "Cheque", "EMI"]] = None
    payment_date: Optional[date] = None
    inspection_date: Optional[date] = None
    inspection_status: Optional[Literal["Pending", "Passed", "Failed", "NA"]] = None
    claim_status: Optional[Literal["No Claim", "Claimed", "Pending"]] = None
    claim_amount: Optional[Decimal] = Field(default=None, ge=Decimal("0"), le=Decimal("99999999.99"))
    claim_notes: Optional[str] = Field(default=None, max_length=1000)
    ref_by: Optional[str] = Field(default=None, max_length=150)
    commission_percent: Optional[Decimal] = Field(default=None, ge=Decimal("0"), le=Decimal("100"))

    @field_validator('policy_number')
    @classmethod
    def policy_number_not_empty(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            if not v.strip():
                raise ValueError('policy_number must not be empty')
            return v.strip()
        return v

    @field_validator('insurance_type')
    @classmethod
    def validate_insurance_type(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in VALID_INSURANCE_TYPES:
            raise ValueError(f'insurance_type must be one of: {", ".join(sorted(VALID_INSURANCE_TYPES))}')
        return v

    @field_validator('commission_percent')
    @classmethod
    def validate_commission_percent(cls, v: Optional[Decimal]) -> Optional[Decimal]:
        if v is not None and (v < 0 or v > 100):
            raise ValueError('commission_percent must be between 0 and 100')
        return v


# ── Response Schemas ────────────────────────────────────────────────────────

class PolicyV2Response(BaseModel):
    id: UUID
    customer_id: Optional[int] = None
    customer_name: Optional[str] = None
    agent_id: int
    policy_number: str
    insurance_company: Optional[str] = None
    insurance_type: str
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    total_amount: Optional[Decimal] = None
    discount_amount: Optional[Decimal] = None
    final_amount: Optional[Decimal] = None
    payment_mode: Optional[str] = None
    payment_date: Optional[date] = None
    inspection_date: Optional[date] = None
    inspection_status: Optional[str] = None
    claim_status: Optional[str] = None
    claim_amount: Optional[Decimal] = None
    claim_notes: Optional[str] = None
    ref_by: Optional[str] = None
    commission_percent: Optional[Decimal] = None
    commission_amount: Optional[Decimal] = None
    policy_pdf_url: Optional[str] = None
    last_year_policy_pdf_url: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PolicyV2ListItem(BaseModel):
    id: UUID
    policy_number: str
    insurance_company: Optional[str] = None
    insurance_type: str
    customer_name: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    total_amount: Optional[Decimal] = None
    final_amount: Optional[Decimal] = None

    class Config:
        from_attributes = True


class PolicyV2ListResponse(BaseModel):
    total: int
    page: int
    pages: int
    data: List[PolicyV2ListItem]
