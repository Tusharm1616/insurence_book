import os
from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import JWTError, jwt

import bcrypt

# Security configuration
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-very-secret-key-for-development")
ALGORITHM = "HS256"
# 30 days — long-lived token for mobile app so users don't get logged out
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 30


def verify_password(plain_password, hashed_password):
    """Verifies a plain text password against a hashed password."""
    if isinstance(plain_password, str):
        plain_password = plain_password[:72].encode('utf-8')
    elif isinstance(plain_password, bytes):
        plain_password = plain_password[:72]

    if isinstance(hashed_password, str):
        hashed_password = hashed_password.encode('utf-8')

    try:
        if not hashed_password.startswith(b'$2b$') and not hashed_password.startswith(b'$2a$'):
            return plain_password == hashed_password
        return bcrypt.checkpw(plain_password, hashed_password)
    except Exception:
        return False


def get_password_hash(password):
    if isinstance(password, str):
        password = password[:72].encode('utf-8')
    elif isinstance(password, bytes):
        password = password[:72]
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password, salt).decode('utf-8')


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        # Use ACCESS_TOKEN_EXPIRE_MINUTES (30 days) — NOT the old 15-minute default
        expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


from fastapi import Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from database import get_db
from models.users import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login", auto_error=False)


async def get_current_user(
    request: Request,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
):
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token invalid: sub missing",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except JWTError as e:
        print(f"DEBUG: JWT decode error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token invalid: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )

    result = await db.execute(select(User).where(
        (func.lower(User.username) == username.lower()) |
        (func.lower(User.email) == username.lower())
    ))
    user = result.scalars().first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user
