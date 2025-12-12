from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class ShakeInitiateRequest(BaseModel):
    """Schema for shake initiation request."""
    latitude: str = Field(..., description="Latitude coordinate")
    longitude: str = Field(..., description="Longitude coordinate")
    accuracy_m: Optional[str] = Field(None, description="Location accuracy in meters")


class NearbyFriendInfo(BaseModel):
    """Schema for nearby friend who is shaking."""
    user_id: int
    username: str
    full_name: Optional[str] = None
    distance_m: float
    shake_session_id: int
    created_at: str


class ShakeInitiateResponse(BaseModel):
    """Schema for shake initiation response."""
    session_id: int
    status: str  # "active" or "matched"
    matched: bool
    message: str
    nearby_friends_count: int = 0
    matched_user_id: Optional[int] = None
    matched_user_name: Optional[str] = None
    meeting_id: Optional[int] = None
    meeting_title: Optional[str] = None
    points_awarded: Optional[int] = None
    error: Optional[str] = None


class NearbyFriendsResponse(BaseModel):
    """Schema for nearby friends response."""
    nearby_friends: List[NearbyFriendInfo]


class ShakeSessionResponse(BaseModel):
    """Schema for active shake session response."""
    session_id: int
    latitude: str
    longitude: str
    created_at: str
    expires_at: str
    status: str

