from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class MeetingCreate(BaseModel):
    """Schema for creating a meeting."""
    title: Optional[str] = Field(None, max_length=200, description="Meeting title")
    description: Optional[str] = Field(None, description="Meeting description")
    location_id: Optional[int] = Field(None, description="Location ID if using a registered location")
    latitude: Optional[str] = Field(None, description="Latitude coordinate")
    longitude: Optional[str] = Field(None, description="Longitude coordinate")
    address: Optional[str] = Field(None, max_length=255, description="Address string")
    scheduled_at: datetime = Field(..., description="When the meeting is scheduled")
    participant_ids: List[int] = Field(default_factory=list, description="List of friend IDs to invite")


class MeetingUpdate(BaseModel):
    """Schema for updating a meeting (all fields optional)."""
    title: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = None
    location_id: Optional[int] = None
    latitude: Optional[str] = None
    longitude: Optional[str] = None
    address: Optional[str] = Field(None, max_length=255)
    scheduled_at: Optional[datetime] = None
    status: Optional[str] = Field(None, description="Meeting status: pending, confirmed, cancelled, completed")


class ParticipantUserInfo(BaseModel):
    """User information for participant."""
    id: int
    username: str
    full_name: Optional[str]
    profile_photo_url: Optional[str]


class MeetingParticipantResponse(BaseModel):
    """Schema for meeting participant response."""
    id: int
    meeting_id: int
    user_id: int
    status: str
    confirmed_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    user: Optional[ParticipantUserInfo] = None
    
    class Config:
        from_attributes = True


class MeetingResponse(BaseModel):
    """Schema for meeting response."""
    id: int
    organizer_id: int
    title: Optional[str]
    description: Optional[str]
    location_id: Optional[int]
    latitude: Optional[str]
    longitude: Optional[str]
    address: Optional[str]
    scheduled_at: datetime
    status: str
    created_at: datetime
    updated_at: datetime
    participant_count: int = Field(default=0, description="Number of participants (always included)")
    participants: List[MeetingParticipantResponse] = Field(default_factory=list)
    
    class Config:
        from_attributes = True

