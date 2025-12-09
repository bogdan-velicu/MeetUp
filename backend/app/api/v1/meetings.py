from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.meetings_service import MeetingsService
from app.schemas.meeting import MeetingCreate, MeetingUpdate, MeetingResponse
from app.core.exceptions import NotFoundError

router = APIRouter(prefix="/meetings", tags=["meetings"])


@router.post("", response_model=MeetingResponse, status_code=status.HTTP_201_CREATED)
async def create_meeting(
    meeting_data: MeetingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new meeting."""
    service = MeetingsService(db)
    meeting = service.create_meeting(current_user.id, meeting_data)
    return meeting


@router.get("", response_model=List[MeetingResponse])
async def get_meetings(
    filter_type: str = Query("all", description="Filter: all, organized, invited, upcoming, past"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's meetings."""
    service = MeetingsService(db)
    meetings = service.get_meetings(current_user.id, filter_type=filter_type)
    return meetings


@router.get("/{meeting_id}", response_model=MeetingResponse)
async def get_meeting(
    meeting_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get meeting details by ID."""
    service = MeetingsService(db)
    meeting = service.get_meeting_by_id(meeting_id, current_user.id)
    return meeting


@router.patch("/{meeting_id}", response_model=MeetingResponse)
async def update_meeting(
    meeting_id: int,
    update_data: MeetingUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update a meeting. Only organizer can update."""
    service = MeetingsService(db)
    meeting = service.update_meeting(meeting_id, current_user.id, update_data)
    return meeting


@router.delete("/{meeting_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_meeting(
    meeting_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a meeting. Only organizer can delete."""
    service = MeetingsService(db)
    deleted = service.delete_meeting(meeting_id, current_user.id)
    if not deleted:
        raise NotFoundError("Meeting not found")
    return None


@router.post("/{meeting_id}/participants", response_model=MeetingResponse)
async def add_participants_to_meeting(
    meeting_id: int,
    participant_ids: List[int],
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Add participants to an existing meeting. Only organizer can add participants."""
    service = MeetingsService(db)
    meeting = service.add_participants_to_meeting(meeting_id, current_user.id, participant_ids)
    return meeting

