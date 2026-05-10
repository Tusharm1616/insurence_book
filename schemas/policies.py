from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import date

# ── Valid values ────────────────────────────────────────────────────────────
VALID_STATUSES = {
    'active', 'live', 'expiring_soon', 'expired',
    'premium_due', 'overdue', 'lapsed', 'matured',
    'renewed', 'cancelled', 'pending'
}

VALID_POLICY_TYPES = {
    'Life', 'Health', 'Motor', 'Two Wheeler', 'Travel',
    'Home', 'Business', 'Shop/Commercial', 'Accident',
    'Term', 'WC Insurance', 'Other'
}

VALID_INSURERS = {
    'LIC', 'HDFC Ergo', 'HDFC Life', 'SBI Life', 'SBI General',
    'Tata AIA', 'ICICI Lombard', 'ICICI Prudential',
    'Star Health', 'Bajaj Allianz', 'Reliance General',
    'New India Assurance', 'United India Insurance',
    'National Insurance', 'Oriental Insurance',
    'Kotak Mahindra Life', 'Max Life', 'PNB MetLife',
    'Birla Sun Life', 'Canara HSBC', 'Edelweiss Tokio',
    'Future Generali', 'Niva Bupa', 'Care Health',
    'Aditya Birla Health', 'ManipalCigna',
    'Royal Sundaram', 'Shriram General', 'Cholamandalam',
    'Digit Insurance', 'Acko General', 'Go Digit',
    'Unknown'
}


class PolicyBase(BaseModel):
    customer_id: int
    policy_number: str = Field(default='', max_length=100)
    policy_type: str
    insurer_name: Optional[str] = None
    plan_name: Optional[str] = None
    sum_assured: Optional[float] = Field(default=0.0, ge=0)
    premium_amount: Optional[float] = Field(default=0.0, ge=0)
    issue_date: date
    expiry_date: date
    premium_due_date: Optional[date] = None
    maturity_date: Optional[date] = None
    status: str = Field(default='active')
    ncb_percent: Optional[float] = Field(default=0.0, ge=0, le=50)
    vehicle_reg_no: Optional[str] = None
    nominee_name: Optional[str] = None
    nominee_relation: Optional[str] = None

    @field_validator('status')
    @classmethod
    def normalize_status(cls, v: str) -> str:
        """Normalize and validate status value"""
        normalized = v.strip().lower()
        # Map legacy aliases
        alias_map = {
            'live': 'active',
            'running': 'active',
            'activee': 'active',     # typo fix
            'runningg': 'active',    # typo fix
            'due': 'premium_due',
            'overdue': 'overdue',
        }
        return alias_map.get(normalized, normalized)

    @field_validator('policy_type')
    @classmethod
    def normalize_policy_type(cls, v: str) -> str:
        """Normalize policy type"""
        return v.strip().title() if v else 'Other'

    @field_validator('insurer_name')
    @classmethod
    def normalize_insurer(cls, v: Optional[str]) -> Optional[str]:
        if not v or v.strip().lower() in ('unknown', '', 'none', 'test', 'demo'):
            return None
        return v.strip()


class PolicyCreate(PolicyBase):
    pass


class PolicyResponse(PolicyBase):
    id: int
    agent_id: Optional[int] = None
    computed_status: Optional[str] = None   # date-driven status for display
    customer_name: Optional[str] = None      # joined from customers table

    class Config:
        from_attributes = True
