from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class OrganizerInfo(BaseModel):
    """Organizer information in invitation."""
    id: int
    username: str
    full_name: Optional[str]
    profile_photo_url: Optional[str]


class MeetingInfo(BaseModel):
    """Meeting information in invitation."""
    id: int
    title: Optional[str]
    description: Optional[str]
    latitude: Optional[str]
    longitude: Optional[str]
    address: Optional[str]
    scheduled_at: datetime
    status: str
    created_at: datetime


class InvitationResponse(BaseModel):
    """Schema for invitation response."""
    id: int  # This is the meeting_id
    meeting: MeetingInfo
    organizer: OrganizerInfo
    participant_status: str
    invited_at: datetime
    responded_at: Optional[datetime]

