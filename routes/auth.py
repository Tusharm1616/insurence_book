from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy.future import select
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
    result = await db.execute(select(User).where((User.username == user_in.email) | (User.email == user_in.email)))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="User with this email already exists")
    
    new_user = User(
        username=user_in.email, # Using email as username for this flow
        email=user_in.email,
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
            id=new_user.id,
            name=new_user.full_name,
            email=new_user.email,
            license_no=new_user.license_no
        )
    )

@api_auth_router.post("/login", response_model=LoginResponse)
async def api_login(login_data: AgentLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == login_data.email))
    user = result.scalars().first()
    
    # Fallback to checking username if email wasn't matched
    if not user:
        result = await db.execute(select(User).where(User.username == login_data.email))
        user = result.scalars().first()
        
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password")
        
    access_token = create_access_token(data={"sub": user.username, "role": user.role})
    
    return LoginResponse(
        token=access_token,
        agent=AgentResponse(
            id=user.id,
            name=user.full_name,
            email=user.email or user.username,
            license_no=user.license_no
        )
    )

@api_auth_router.post("/forgot-password")
async def api_forgot_password(request: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    # In a real app, this would send an email. For now, we simulate it.
    result = await db.execute(select(User).where(User.email == request.email))
    user = result.scalars().first()
    
    # Always return "Reset link sent" for security reasons (don't leak if email exists)
    return {"message": "Reset link sent"}
