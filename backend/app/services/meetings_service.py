from sqlalchemy.orm import Session
from datetime import datetime
from typing import List, Optional, Dict
from app.repositories.meeting_repository import MeetingRepository
from app.repositories.friendship_repository import FriendshipRepository
from app.repositories.user_repository import UserRepository
from app.services.notification_service import NotificationService
from app.core.exceptions import NotFoundError, ValidationError, UnauthorizedError
from app.schemas.meeting import MeetingCreate, MeetingUpdate


class MeetingsService:
    def __init__(self, db: Session):
        self.meeting_repo = MeetingRepository(db)
        self.friendship_repo = FriendshipRepository(db)
        self.user_repo = UserRepository(db)
        self.notification_service = NotificationService(db)
        self.db = db
    
    def create_meeting(self, organizer_id: int, meeting_data: MeetingCreate) -> Dict:
        """Create a new meeting with participants."""
        # Validate scheduled_at is in the future
        if meeting_data.scheduled_at <= datetime.now():
            raise ValidationError("Meeting must be scheduled in the future")
        
        # Validate participants are friends
        for participant_id in meeting_data.participant_ids:
            if participant_id == organizer_id:
                raise ValidationError("Cannot invite yourself to a meeting")
            
            # Check if user exists
            user = self.user_repo.get_by_id(participant_id)
            if not user:
                raise NotFoundError(f"User with ID {participant_id} not found")
            
            # Check if they are friends
            friendship = self.friendship_repo.get_friendship(organizer_id, participant_id)
            if not friendship or friendship.status != "accepted":
                raise ValidationError(f"User {participant_id} is not a friend")
        
        # Create meeting
        meeting = self.meeting_repo.create(
            organizer_id=organizer_id,
            title=meeting_data.title,
            description=meeting_data.description,
            location_id=meeting_data.location_id,
            latitude=meeting_data.latitude,
            longitude=meeting_data.longitude,
            address=meeting_data.address,
            scheduled_at=meeting_data.scheduled_at,
            status="pending"
        )
        
        # Add participants and send notifications
        participants = []
        organizer = self.user_repo.get_by_id(organizer_id)
        organizer_name = organizer.full_name if organizer and organizer.full_name else organizer.username if organizer else "Someone"
        
        for participant_id in meeting_data.participant_ids:
            participant = self.meeting_repo.add_participant(
                meeting.id, 
                participant_id, 
                status="pending"
            )
            participants.append(participant)
            
            # Send invitation notification
            try:
                self.notification_service.send_invitation_notification(
                    user_id=participant_id,
                    meeting_id=meeting.id,
                    organizer_name=organizer_name,
                    meeting_title=meeting.title
                )
            except Exception as e:
                # Log error but don't fail meeting creation
                import logging
                logger = logging.getLogger(__name__)
                logger.error(f"Failed to send invitation notification: {e}")
        
        # Return meeting with participants
        return self._meeting_to_dict(meeting, include_participants=True)
    
    def get_meetings(self, user_id: int, filter_type: str = "all") -> List[Dict]:
        """Get meetings for a user.
        
        filter_type: "all", "organized", "invited", "upcoming", "past"
        """
        if filter_type == "organized":
            meetings = self.meeting_repo.get_by_organizer(user_id)
        elif filter_type == "invited":
            meetings = self.meeting_repo.get_by_participant(user_id)
        else:  # "all" or default
            meetings = self.meeting_repo.get_meetings_by_user_participation(user_id)
        
        # Apply time-based filters
        now = datetime.now()
        if filter_type == "upcoming":
            meetings = [m for m in meetings if m.scheduled_at > now and m.status != "cancelled"]
        elif filter_type == "past":
            meetings = [m for m in meetings if m.scheduled_at <= now or m.status == "completed"]
        
        # Sort by scheduled_at descending
        meetings.sort(key=lambda m: m.scheduled_at, reverse=True)
        
        return [self._meeting_to_dict(m, include_participants=False) for m in meetings]
    
    def get_meeting_by_id(self, meeting_id: int, user_id: int) -> Dict:
        """Get a specific meeting by ID. User must be organizer or participant."""
        meeting = self.meeting_repo.get_by_id(meeting_id)
        if not meeting:
            raise NotFoundError("Meeting not found")
        
        # Check if user is organizer or participant
        is_organizer = meeting.organizer_id == user_id
        is_participant = self.meeting_repo.get_participant(meeting_id, user_id) is not None
        
        if not is_organizer and not is_participant:
            raise UnauthorizedError("You don't have access to this meeting")
        
        return self._meeting_to_dict(meeting, include_participants=True)
    
    def update_meeting(self, meeting_id: int, user_id: int, update_data: MeetingUpdate) -> Dict:
        """Update a meeting. Only organizer can update."""
        meeting = self.meeting_repo.get_by_id(meeting_id)
        if not meeting:
            raise NotFoundError("Meeting not found")
        
        # Check if user is organizer
        if meeting.organizer_id != user_id:
            raise UnauthorizedError("Only the organizer can update this meeting")
        
        # Validate scheduled_at if provided
        if update_data.scheduled_at and update_data.scheduled_at <= datetime.now():
            raise ValidationError("Meeting must be scheduled in the future")
        
        # Prepare update dict (only include non-None values)
        update_dict = {}
        for field, value in update_data.model_dump(exclude_unset=True).items():
            if value is not None:
                update_dict[field] = value
        
        # Update meeting
        updated_meeting = self.meeting_repo.update(meeting_id, **update_dict)
        if not updated_meeting:
            raise NotFoundError("Meeting not found")
        
        # Determine update type for notification
        update_type = "updated"
        if "scheduled_at" in update_dict:
            update_type = "time_changed"
        elif "address" in update_dict or "latitude" in update_dict or "longitude" in update_dict:
            update_type = "location_changed"
        
        # Get all participants and send update notification
        try:
            participants = self.meeting_repo.get_participants_by_meeting(meeting_id)
            participant_ids = [p.user_id for p in participants]
            if participant_ids:
                self.notification_service.send_meeting_update_to_participants(
                    participant_ids=participant_ids,
                    meeting_id=meeting_id,
                    update_type=update_type,
                    meeting_title=updated_meeting.title
                )
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to send meeting update notifications: {e}")
        
        return self._meeting_to_dict(updated_meeting, include_participants=True)
    
    def delete_meeting(self, meeting_id: int, user_id: int) -> bool:
        """Delete a meeting. Only organizer can delete."""
        meeting = self.meeting_repo.get_by_id(meeting_id)
        if not meeting:
            raise NotFoundError("Meeting not found")
        
        # Check if user is organizer
        if meeting.organizer_id != user_id:
            raise UnauthorizedError("Only the organizer can delete this meeting")
        
        # Get all participants before deleting to send cancellation notification
        try:
            participants = self.meeting_repo.get_participants_by_meeting(meeting_id)
            participant_ids = [p.user_id for p in participants]
            if participant_ids:
                self.notification_service.send_meeting_update_to_participants(
                    participant_ids=participant_ids,
                    meeting_id=meeting_id,
                    update_type="cancelled",
                    meeting_title=meeting.title
                )
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to send meeting cancellation notifications: {e}")
        
        return self.meeting_repo.delete(meeting_id)
    
    def add_participants_to_meeting(self, meeting_id: int, user_id: int, participant_ids: List[int]) -> Dict:
        """Add participants to an existing meeting. Only organizer can add participants."""
        meeting = self.meeting_repo.get_by_id(meeting_id)
        if not meeting:
            raise NotFoundError("Meeting not found")
        
        # Check if user is organizer
        if meeting.organizer_id != user_id:
            raise UnauthorizedError("Only the organizer can add participants to this meeting")
        
        # Validate participants are friends
        for participant_id in participant_ids:
            if participant_id == user_id:
                raise ValidationError("Cannot invite yourself to a meeting")
            
            # Check if user exists
            user = self.user_repo.get_by_id(participant_id)
            if not user:
                raise NotFoundError(f"User with ID {participant_id} not found")
            
            # Check if they are friends
            friendship = self.friendship_repo.get_friendship(user_id, participant_id)
            if not friendship or friendship.status != "accepted":
                raise ValidationError(f"User {participant_id} is not a friend")
            
            # Check if already a participant
            existing_participant = self.meeting_repo.get_participant(meeting_id, participant_id)
            if existing_participant:
                continue  # Skip if already a participant
            
            # Add participant
            self.meeting_repo.add_participant(meeting_id, participant_id, status="pending")
            
            # Send invitation notification
            try:
                organizer = self.user_repo.get_by_id(user_id)
                organizer_name = organizer.full_name if organizer and organizer.full_name else organizer.username if organizer else "Someone"
                self.notification_service.send_invitation_notification(
                    user_id=participant_id,
                    meeting_id=meeting_id,
                    organizer_name=organizer_name,
                    meeting_title=meeting.title
                )
            except Exception as e:
                import logging
                logger = logging.getLogger(__name__)
                logger.error(f"Failed to send invitation notification: {e}")
        
        # Return updated meeting with participants
        return self._meeting_to_dict(meeting, include_participants=True)
    
    def _meeting_to_dict(self, meeting, include_participants: bool = False) -> Dict:
        """Convert meeting model to dictionary."""
        # Always get participant count for efficiency
        participant_count = self.meeting_repo.get_participant_count(meeting.id)
        
        result = {
            "id": meeting.id,
            "organizer_id": meeting.organizer_id,
            "title": meeting.title,
            "description": meeting.description,
            "location_id": meeting.location_id,
            "latitude": meeting.latitude,
            "longitude": meeting.longitude,
            "address": meeting.address,
            "scheduled_at": meeting.scheduled_at,
            "status": meeting.status,
            "created_at": meeting.created_at,
            "updated_at": meeting.updated_at,
            "participant_count": participant_count
        }
        
        if include_participants:
            participants = self.meeting_repo.get_participants_by_meeting(meeting.id)
            result["participants"] = []
            for p in participants:
                # Get user info for participant
                user = self.user_repo.get_by_id(p.user_id)
                participant_dict = {
                    "id": p.id,
                    "meeting_id": p.meeting_id,
                    "user_id": p.user_id,
                    "status": p.status,
                    "confirmed_at": p.confirmed_at,
                    "created_at": p.created_at,
                    "updated_at": p.updated_at
                }
                if user:
                    participant_dict["user"] = {
                        "id": user.id,
                        "username": user.username,
                        "full_name": user.full_name,
                        "profile_photo_url": user.profile_photo_url
                    }
                result["participants"].append(participant_dict)
        else:
            result["participants"] = []
        
        return result

