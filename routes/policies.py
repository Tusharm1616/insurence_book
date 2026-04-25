from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from database import get_db
from models.users import User, UserRole
from models.customers import Customer
from models.policies import Policy
from schemas.policies import PolicyCreate, PolicyResponse
from utils.auth import get_current_user

router = APIRouter(prefix="/policies", tags=["Policies"])

@router.post("/", response_model=PolicyResponse)
async def create_policy(
    policy_in: PolicyCreate, 
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Only agents can create policies")
    
    # Verify the customer belongs to this agent
    result = await db.execute(select(Customer).where(Customer.id == policy_in.customer_id))
    customer = result.scalars().first()
    
    if not customer or customer.agent_id != current_user.id:
        raise HTTPException(status_code=404, detail="Customer not found or access denied")
        
    new_policy = Policy(**policy_in.dict())
    db.add(new_policy)
    await db.commit()
    await db.refresh(new_policy)
    
    return new_policy

@router.get("/", response_model=List[PolicyResponse])
async def list_policies(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != UserRole.AGENT:
        raise HTTPException(status_code=403, detail="Access denied")
        
    # Get all policies for customers managed by this agent
    result = await db.execute(
        select(Policy).join(Customer).where(Customer.agent_id == current_user.id)
    )
    return result.scalars().all()
