from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import date

class CustomerBase(BaseModel):
    full_name: str
    mobile_number: str
    email: Optional[EmailStr] = None
    state: str
    city: str
    address: str
    dob: Optional[date] = None
    anniversary_date: Optional[date] = None
    
    gender: Optional[str] = None
    height: Optional[str] = None
    weight_kg: Optional[float] = None
    education: Optional[str] = None
    marital_status: Optional[str] = None
    
    business_job_type: Optional[str] = None
    business_job_name: Optional[str] = None
    duty_type: Optional[str] = None
    annual_income: Optional[float] = None
    pan_no: Optional[str] = None
    gst_no: Optional[str] = None

class CustomerCreate(CustomerBase):
    pass

class CustomerResponse(CustomerBase):
    id: int
    user_id: int
    agent_id: int
    is_active: int
    
    # Credentials to be shown to agent (Once or stored in user record)
    generated_username: Optional[str] = None
    generated_password: Optional[str] = None

    class Config:
        from_attributes = True
