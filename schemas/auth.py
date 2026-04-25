from pydantic import BaseModel, EmailStr
from typing import Optional

class UserBase(BaseModel):
    username: str
    email: Optional[EmailStr] = None
    full_name: str

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None
    role: Optional[str] = None

# New Agent JSON schemas
class AgentLogin(BaseModel):
    email: EmailStr
    password: str

class AgentRegister(BaseModel):
    name: str
    email: EmailStr
    phone: str
    license_no: str
    password: str

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class AgentResponse(BaseModel):
    id: int
    name: str
    email: EmailStr
    license_no: Optional[str] = None

class LoginResponse(BaseModel):
    token: str
    agent: AgentResponse

class RegisterResponse(BaseModel):
    message: str
    agent: AgentResponse
