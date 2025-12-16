from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UserRegister(BaseModel):
    username: str = Field(..., min_length=3, max_length=60)
    email: EmailStr
    password: str = Field(..., min_length=8)  # No max_length - we handle long passwords
    full_name: str = Field(..., min_length=1, max_length=120)
    phone_number: Optional[str] = Field(None, max_length=30)

class UserLogin(BaseModel):
    email: Optional[EmailStr] = None  # Can be email or username
    username: Optional[str] = None  # Can be email or username
    password: str  # No max_length - we handle long passwords
    
    def get_identifier(self) -> str:
        """Get the login identifier (email or username)."""
        if self.email:
            return self.email
        if self.username:
            return self.username
        raise ValueError("Either email or username must be provided")

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenRefresh(BaseModel):
    access_token: str

class TokenData(BaseModel):
    user_id: Optional[int] = None
    email: Optional[str] = None

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    full_name: str
    phone_number: Optional[str]
    is_active: bool
    email_verified: bool
    total_points: int
    created_at: datetime
    
    class Config:
        from_attributes = True

