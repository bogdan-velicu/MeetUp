from sqlalchemy.orm import Session
from datetime import datetime
from typing import List, Dict, Optional
from app.repositories.meeting_repository import MeetingRepository
from app.repositories.user_repository import UserRepository
from app.services.notification_service import NotificationService
from app.core.exceptions import NotFoundError, ValidationError, UnauthorizedError


class InvitationsService:
    def __init__(self, db: Session):
        self.meeting_repo = MeetingRepository(db)
        self.user_repo = UserRepository(db)
        self.notification_service = NotificationService(db)
        self.db = db
    
    def get_invitations(self, user_id: int) -> List[Dict]:
        """Get all pending invitations for a user (meetings where user is a participant with status 'pending')."""
        # Get all meetings where user is a participant
        meetings = self.meeting_repo.get_by_participant(user_id)
        
        # Filter for pending invitations only
        invitations = []
        for meeting in meetings:
            participant = self.meeting_repo.get_participant(meeting.id, user_id)
            if participant and participant.status == "pending":
                # Get organizer info
                organizer = self.user_repo.get_by_id(meeting.organizer_id)
                if organizer:
                    invitations.append(self._invitation_to_dict(meeting, participant, organizer))
        
        # Sort by scheduled_at (upcoming first)
        invitations.sort(key=lambda x: x["meeting"]["scheduled_at"])
        return invitations
    
    def get_invitation_by_id(self, invitation_id: int, user_id: int) -> Dict:
        """Get a specific invitation by meeting ID. User must be the invited participant."""
        # The invitation_id is actually the meeting_id
        meeting = self.meeting_repo.get_by_id(invitation_id)
        if not meeting:
            raise NotFoundError("Invitation not found")
        
        participant = self.meeting_repo.get_participant(meeting.id, user_id)
        if not participant:
            raise UnauthorizedError("You are not invited to this meeting")
        
        if participant.status != "pending":
            raise ValidationError("This invitation has already been responded to")
        
        organizer = self.user_repo.get_by_id(meeting.organizer_id)
        if not organizer:
            raise NotFoundError("Organizer not found")
        
        return self._invitation_to_dict(meeting, participant, organizer)
    
    def accept_invitation(self, meeting_id: int, user_id: int) -> Dict:
        """Accept an invitation (update participant status to 'accepted')."""
        meeting = self.meeting_repo.get_by_id(meeting_id)
        if not meeting:
            raise NotFoundError("Meeting not found")
        
        participant = self.meeting_repo.get_participant(meeting_id, user_id)
        if not participant:
            raise UnauthorizedError("You are not invited to this meeting")
        
        if participant.status != "pending":
            raise ValidationError("This invitation has already been responded to")
        
        # Update participant status
        updated_participant = self.meeting_repo.update_participant_status(
            meeting_id, 
            user_id, 
            "accepted",
            confirmed_at=datetime.now()
        )
        
        if not updated_participant:
            raise NotFoundError("Failed to update invitation")
        
        organizer = self.user_repo.get_by_id(meeting.organizer_id)
        if not organizer:
            raise NotFoundError("Organizer not found")
        
        return self._invitation_to_dict(meeting, updated_participant, organizer)
    
    def decline_invitation(self, meeting_id: int, user_id: int) -> Dict:
        """Decline an invitation (update participant status to 'declined')."""
        meeting = self.meeting_repo.get_by_id(meeting_id)
        if not meeting:
            raise NotFoundError("Meeting not found")
        
        participant = self.meeting_repo.get_participant(meeting_id, user_id)
        if not participant:
            raise UnauthorizedError("You are not invited to this meeting")
        
        if participant.status != "pending":
            raise ValidationError("This invitation has already been responded to")
        
        # Update participant status
        updated_participant = self.meeting_repo.update_participant_status(
            meeting_id, 
            user_id, 
            "declined"
        )
        
        if not updated_participant:
            raise NotFoundError("Failed to update invitation")
        
        organizer = self.user_repo.get_by_id(meeting.organizer_id)
        if not organizer:
            raise NotFoundError("Organizer not found")
        
        # Send notification to organizer
        try:
            participant_user = self.user_repo.get_by_id(user_id)
            participant_name = participant_user.full_name if participant_user and participant_user.full_name else participant_user.username if participant_user else "Someone"
            self.notification_service.send_invitation_response_notification(
                organizer_id=meeting.organizer_id,
                participant_name=participant_name,
                meeting_id=meeting_id,
                accepted=False,
                meeting_title=meeting.title
            )
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to send invitation response notification: {e}")
        
        return self._invitation_to_dict(meeting, updated_participant, organizer)
    
    def _invitation_to_dict(self, meeting, participant, organizer) -> Dict:
        """Convert invitation data to dictionary."""
        return {
            "id": meeting.id,  # Using meeting_id as invitation_id
            "meeting": {
                "id": meeting.id,
                "title": meeting.title,
                "description": meeting.description,
                "latitude": meeting.latitude,
                "longitude": meeting.longitude,
                "address": meeting.address,
                "scheduled_at": meeting.scheduled_at,
                "status": meeting.status,
                "created_at": meeting.created_at
            },
            "organizer": {
                "id": organizer.id,
                "username": organizer.username,
                "full_name": organizer.full_name,
                "profile_photo_url": organizer.profile_photo_url
            },
            "participant_status": participant.status,
            "invited_at": participant.created_at,
            "responded_at": participant.updated_at if participant.status != "pending" else None
        }

