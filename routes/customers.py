from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import delete, update
from typing import List

from database import get_db
from models.users import User, UserRole
from models.customers import Customer
from models.policies import Policy
from models.policy_v2 import PolicyV2
from models.customer_document import CustomerDocument
from models.motor_insurance import MotorInsurancePolicy, MotorInsuranceQuote
from models.vehicle_documents import VehicleDocument
from models.reminders import Reminder
from models.leads import Lead
from schemas.customers import CustomerCreate, CustomerResponse
from utils.auth import get_current_user, get_password_hash
from utils.credentials import generate_user_id, generate_temp_password

router = APIRouter(prefix="/customers", tags=["Customers"])

@router.post("/", response_model=CustomerResponse)
async def create_customer(
    customer_in: CustomerCreate, 
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Only agents can create customers")
    
    # 1. Generate Credentials
    gen_username = generate_user_id()
    gen_password = generate_temp_password()
    
    # 2. Create User account for customer
    customer_user = User(
        username=gen_username,
        full_name=customer_in.full_name,
        hashed_password=get_password_hash(gen_password),
        role=UserRole.CUSTOMER
    )
    db.add(customer_user)
    await db.flush() # Get user ID
    
    # 3. Create Customer profile
    new_customer = Customer(
        **customer_in.dict(),
        user_id=customer_user.id,
        agent_id=current_user.id,
        is_active=1
    )
    db.add(new_customer)
    await db.commit()
    await db.refresh(new_customer)
    
    # 4. Prepare response with raw credentials (shown once)
    response_data = CustomerResponse.from_orm(new_customer)
    response_data.generated_username = gen_username
    response_data.generated_password = gen_password
    
    return response_data

@router.get("/", response_model=List[CustomerResponse])
async def list_customers(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Access denied")
        
    result = await db.execute(
        select(Customer).where(Customer.agent_id == current_user.id)
    )
    return result.scalars().all()


@router.delete("/{customer_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_customer(
    customer_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Access denied")

    result = await db.execute(
        select(Customer).where(Customer.id == customer_id, Customer.agent_id == current_user.id)
    )
    customer = result.scalars().first()

    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    # Explicitly delete/update all related records
    await db.execute(delete(Policy).where(Policy.customer_id == customer_id))
    await db.execute(delete(PolicyV2).where(PolicyV2.customer_id == customer_id))
    await db.execute(delete(CustomerDocument).where(CustomerDocument.customer_id == customer_id))
    await db.execute(delete(VehicleDocument).where(VehicleDocument.customer_id == customer_id))
    await db.execute(delete(MotorInsurancePolicy).where(MotorInsurancePolicy.customer_id == customer_id))
    await db.execute(delete(MotorInsuranceQuote).where(MotorInsuranceQuote.customer_id == customer_id))
    await db.execute(delete(Reminder).where(Reminder.customer_id == customer_id))
    await db.execute(update(Lead).where(Lead.converted_customer_id == customer_id).values(converted_customer_id=None))

    await db.delete(customer)
    await db.commit()
    return None
