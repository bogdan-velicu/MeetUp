from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class FriendResponse(BaseModel):
    id: int
    username: str
    full_name: str
    email: str
    profile_photo_url: Optional[str]
    availability_status: str
    is_close_friend: bool
    
    class Config:
        from_attributes = True

class FriendRequest(BaseModel):
    friend_id: int

class FriendshipResponse(BaseModel):
    id: int
    user_id: int
    friend_id: int
    is_close_friend: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class CloseFriendUpdate(BaseModel):
    is_close_friend: bool

