from pydantic import BaseModel, field_validator
from typing import Optional
from datetime import date, datetime


# ── Create ────────────────────────────────────────────────────────────────
class VehicleDocumentCreate(BaseModel):
    customer_id:       Optional[int]    = None
    vehicle_number:    str
    vehicle_type:      str              # Car | Bike | Truck | Bus | Other
    vehicle_model:     str
    manufacturer:      str
    fuel_type:         str              # Petrol | Diesel | CNG | Electric | Hybrid
    registration_year: Optional[int]   = None
    insurance_expiry:  Optional[date]  = None
    puc_expiry:        Optional[date]  = None
    rc_expiry:         Optional[date]  = None
    license_expiry:    Optional[date]  = None
    fitness_expiry:    Optional[date]  = None
    notes:             Optional[str]   = None

    @field_validator('vehicle_number')
    @classmethod
    def normalise_vehicle_number(cls, v: str) -> str:
        return v.upper().replace(' ', '')


# ── Update (renewal / edit) ───────────────────────────────────────────────
class VehicleDocumentUpdate(BaseModel):
    customer_id:       Optional[int]    = None
    vehicle_type:      Optional[str]    = None
    vehicle_model:     Optional[str]    = None
    manufacturer:      Optional[str]    = None
    fuel_type:         Optional[str]    = None
    registration_year: Optional[int]   = None
    insurance_expiry:  Optional[date]  = None
    puc_expiry:        Optional[date]  = None
    rc_expiry:         Optional[date]  = None
    license_expiry:    Optional[date]  = None
    fitness_expiry:    Optional[date]  = None
    notes:             Optional[str]   = None
    reminder_sent:     Optional[bool]  = None


# ── Document status sub-model ─────────────────────────────────────────────
class DocStatus(BaseModel):
    expiry_date:       Optional[date]
    days_until_expiry: Optional[int]
    status:            str   # valid | expiring_soon | expired | not_set


def _compute_doc_status(expiry: Optional[date]) -> DocStatus:
    if expiry is None:
        return DocStatus(expiry_date=None, days_until_expiry=None, status="not_set")
    today = date.today()
    days  = (expiry - today).days
    if days < 0:
        status = "expired"
    elif days <= 30:
        status = "expiring_soon"
    else:
        status = "valid"
    return DocStatus(expiry_date=expiry, days_until_expiry=days, status=status)


# ── Response ──────────────────────────────────────────────────────────────
class VehicleDocumentResponse(BaseModel):
    id:                int
    agent_id:          int
    customer_id:       Optional[int]
    customer_name:     Optional[str]
    customer_mobile:   Optional[str]

    vehicle_number:    str
    vehicle_type:      str
    vehicle_model:     str
    manufacturer:      str
    fuel_type:         str
    registration_year: Optional[int]

    insurance: DocStatus
    puc:       DocStatus
    rc:        DocStatus
    license:   DocStatus
    fitness:   DocStatus

    overall_status: str   # valid | expiring_soon | expired
    reminder_sent:  bool
    notes:          Optional[str]
    created_at:     datetime
    updated_at:     datetime

    model_config = {"from_attributes": True}

    @classmethod
    def from_orm_obj(cls, obj, customer=None):
        docs = [
            _compute_doc_status(obj.insurance_expiry),
            _compute_doc_status(obj.puc_expiry),
            _compute_doc_status(obj.rc_expiry),
            _compute_doc_status(obj.license_expiry),
            _compute_doc_status(obj.fitness_expiry),
        ]
        set_docs = [d for d in docs if d.status != "not_set"]
        if any(d.status == "expired" for d in set_docs):
            overall = "expired"
        elif any(d.status == "expiring_soon" for d in set_docs):
            overall = "expiring_soon"
        else:
            overall = "valid"

        return cls(
            id=obj.id,
            agent_id=obj.agent_id,
            customer_id=obj.customer_id,
            customer_name=customer.full_name if customer else None,
            customer_mobile=customer.mobile_number if customer else None,
            vehicle_number=obj.vehicle_number,
            vehicle_type=obj.vehicle_type,
            vehicle_model=obj.vehicle_model,
            manufacturer=obj.manufacturer,
            fuel_type=obj.fuel_type,
            registration_year=obj.registration_year,
            insurance=_compute_doc_status(obj.insurance_expiry),
            puc=_compute_doc_status(obj.puc_expiry),
            rc=_compute_doc_status(obj.rc_expiry),
            license=_compute_doc_status(obj.license_expiry),
            fitness=_compute_doc_status(obj.fitness_expiry),
            overall_status=overall,
            reminder_sent=obj.reminder_sent or False,
            notes=obj.notes,
            created_at=obj.created_at,
            updated_at=obj.updated_at,
        )


# ── Summary ───────────────────────────────────────────────────────────────
class VehicleDocSummary(BaseModel):
    total:                 int
    insurance_expiring:    int
    puc_expiring:          int
    rc_expiring:           int
    license_expiring:      int
    fitness_expiring:      int
    total_expiring_soon:   int
    total_expired:         int
    total_valid:           int
