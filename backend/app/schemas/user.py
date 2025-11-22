from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=60)
    email: EmailStr
    full_name: str = Field(..., min_length=1, max_length=120)

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=100)
    phone_number: Optional[str] = Field(None, max_length=30)

class UserResponse(UserBase):
    id: int
    phone_number: Optional[str] = None
    bio: Optional[str] = None
    profile_photo_url: Optional[str] = None
    is_active: bool
    email_verified: bool
    phone_verified: bool
    location_sharing_enabled: bool
    location_update_interval: int
    availability_status: str
    total_points: int
    created_at: datetime
    updated_at: datetime
    last_login_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    user_id: Optional[int] = None
    email: Optional[str] = None

