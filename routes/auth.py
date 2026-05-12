from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy.future import select
from sqlalchemy import func
from sqlalchemy.ext.asyncio import AsyncSession
from database import get_db
from models.users import User, UserRole
from schemas.auth import UserCreate, Token, AgentLogin, AgentRegister, ForgotPasswordRequest, LoginResponse, RegisterResponse, AgentResponse
from utils.auth import get_password_hash, verify_password, create_access_token

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=Token)
async def register_agent(user_in: UserCreate, db: AsyncSession = Depends(get_db)):
    # Check if user already exists
    result = await db.execute(select(User).where(User.username == user_in.username))
    if result.scalars().first():
        throw_already_exists()
    
    new_user = User(
        username=user_in.username,
        email=user_in.email,
        full_name=user_in.full_name,
        hashed_password=get_password_hash(user_in.password),
        role=UserRole.AGENT
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    
    access_token = create_access_token(data={"sub": new_user.username, "role": new_user.role})
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.username == form_data.username))
    user = result.scalars().first()
    
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"sub": user.username, "role": user.role})
    return {"access_token": access_token, "token_type": "bearer"}

def throw_already_exists():
    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="User with this mobile/username already exists"
    )

api_auth_router = APIRouter(prefix="/api/auth", tags=["API Authentication"])

@api_auth_router.post("/register", response_model=RegisterResponse)
async def api_register_agent(user_in: AgentRegister, db: AsyncSession = Depends(get_db)):
    email = user_in.email.lower()
    result = await db.execute(select(User).where((func.lower(User.username) == email) | (func.lower(User.email) == email)))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="User with this email already exists")
    
    new_user = User(
        username=email, # Using lowercase email as username for this flow
        email=email,
        full_name=user_in.name,
        phone=user_in.phone,
        license_no=user_in.license_no,
        hashed_password=get_password_hash(user_in.password),
        role=UserRole.AGENT
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    
    return RegisterResponse(
        message="success",
        agent=AgentResponse(
            id=str(new_user.id),
            name=new_user.full_name,
            email=new_user.email,
            license_no=new_user.license_no
        )
    )

@api_auth_router.post("/login", response_model=LoginResponse)
async def api_login(login_data: AgentLogin, db: AsyncSession = Depends(get_db)):
    try:
        email = login_data.email.lower()
        result = await db.execute(select(User).where(func.lower(User.email) == email))
        user = result.scalars().first()
        
        # Fallback to checking username if email wasn't matched
        if not user:
            result = await db.execute(select(User).where(func.lower(User.username) == email))
            user = result.scalars().first()
            
        if not user or not verify_password(login_data.password, user.hashed_password):
            raise HTTPException(status_code=401, detail="Invalid email or password")
            
        access_token = create_access_token(data={"sub": user.username, "role": user.role})
        
        return LoginResponse(
            token=access_token,
            agent=AgentResponse(
                id=str(user.id),
                name=user.full_name,
                email=user.email or user.username,
                license_no=user.license_no
            )
        )
    except Exception as e:
        import traceback
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=traceback.format_exc())

@api_auth_router.post("/forgot-password")
async def api_forgot_password(request: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    # In a real app, this would send an email. For now, we simulate it.
    email = request.email.lower()
    result = await db.execute(select(User).where(func.lower(User.email) == email))
    user = result.scalars().first()
    
    # Always return "Reset link sent" for security reasons (don't leak if email exists)
    return {"message": "Reset link sent"}

@api_auth_router.delete("/clear-all-users")
async def clear_all_users(db: AsyncSession = Depends(get_db)):
    from sqlalchemy import text
    await db.execute(text("TRUNCATE TABLE users RESTART IDENTITY CASCADE"))
    await db.commit()
    return {"message": "All users deleted successfully"}

from utils.auth import get_current_user
from pydantic import BaseModel

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

@api_auth_router.post("/change-password")
async def change_password(
    req: ChangePasswordRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not verify_password(req.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    
    current_user.hashed_password = get_password_hash(req.new_password)
    await db.commit()
    return {"message": "Password changed successfully"}

@api_auth_router.get("/profile", response_model=AgentResponse)
async def get_profile(current_user: User = Depends(get_current_user)):
    return AgentResponse(
        id=str(current_user.id),
        name=current_user.full_name,
        email=current_user.email or current_user.username,
        license_no=current_user.license_no
    )

