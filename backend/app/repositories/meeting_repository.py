from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from app.models.meeting import Meeting, MeetingParticipant
from typing import List, Optional
from datetime import datetime


class MeetingRepository:
    def __init__(self, db: Session):
        self.db = db
    
    # Meeting CRUD operations
    
    def create(self, organizer_id: int, title: Optional[str] = None, 
               description: Optional[str] = None, location_id: Optional[int] = None,
               latitude: Optional[str] = None, longitude: Optional[str] = None,
               address: Optional[str] = None, scheduled_at: datetime = None,
               status: str = "pending") -> Meeting:
        """Create a new meeting."""
        meeting = Meeting(
            organizer_id=organizer_id,
            title=title,
            description=description,
            location_id=location_id,
            latitude=latitude,
            longitude=longitude,
            address=address,
            scheduled_at=scheduled_at,
            status=status
        )
        self.db.add(meeting)
        self.db.commit()
        self.db.refresh(meeting)
        return meeting
    
    def get_by_id(self, meeting_id: int) -> Optional[Meeting]:
        """Get a meeting by ID."""
        return self.db.query(Meeting).filter(Meeting.id == meeting_id).first()
    
    def get_by_organizer(self, organizer_id: int, status_filter: Optional[str] = None) -> List[Meeting]:
        """Get all meetings organized by a user."""
        query = self.db.query(Meeting).filter(Meeting.organizer_id == organizer_id)
        if status_filter:
            query = query.filter(Meeting.status == status_filter)
        return query.order_by(Meeting.scheduled_at.desc()).all()
    
    def get_by_participant(self, user_id: int, status_filter: Optional[str] = None) -> List[Meeting]:
        """Get all meetings where user is a participant."""
        query = self.db.query(Meeting).join(
            MeetingParticipant,
            Meeting.id == MeetingParticipant.meeting_id
        ).filter(MeetingParticipant.user_id == user_id)
        
        if status_filter:
            query = query.filter(Meeting.status == status_filter)
        
        return query.order_by(Meeting.scheduled_at.desc()).all()
    
    def update(self, meeting_id: int, **kwargs) -> Optional[Meeting]:
        """Update a meeting. Pass fields to update as keyword arguments."""
        meeting = self.get_by_id(meeting_id)
        if not meeting:
            return None
        
        for key, value in kwargs.items():
            if hasattr(meeting, key) and value is not None:
                setattr(meeting, key, value)
        
        self.db.commit()
        self.db.refresh(meeting)
        return meeting
    
    def delete(self, meeting_id: int) -> bool:
        """Delete a meeting (cascade will delete participants)."""
        meeting = self.get_by_id(meeting_id)
        if meeting:
            self.db.delete(meeting)
            self.db.commit()
            return True
        return False
    
    # Participant operations
    
    def add_participant(self, meeting_id: int, user_id: int, status: str = "pending") -> MeetingParticipant:
        """Add a participant to a meeting."""
        participant = MeetingParticipant(
            meeting_id=meeting_id,
            user_id=user_id,
            status=status
        )
        self.db.add(participant)
        self.db.commit()
        self.db.refresh(participant)
        return participant
    
    def get_participant(self, meeting_id: int, user_id: int) -> Optional[MeetingParticipant]:
        """Get a specific participant."""
        return self.db.query(MeetingParticipant).filter(
            and_(
                MeetingParticipant.meeting_id == meeting_id,
                MeetingParticipant.user_id == user_id
            )
        ).first()
    
    def get_participants_by_meeting(self, meeting_id: int) -> List[MeetingParticipant]:
        """Get all participants for a meeting."""
        return self.db.query(MeetingParticipant).filter(
            MeetingParticipant.meeting_id == meeting_id
        ).all()
    
    def get_participant_count(self, meeting_id: int) -> int:
        """Get the count of participants for a meeting."""
        return self.db.query(MeetingParticipant).filter(
            MeetingParticipant.meeting_id == meeting_id
        ).count()
    
    def get_meetings_by_user_participation(self, user_id: int) -> List[Meeting]:
        """Get all meetings where user is either organizer or participant."""
        # Get meetings where user is organizer
        organized = self.db.query(Meeting).filter(Meeting.organizer_id == user_id).all()
        
        # Get meetings where user is participant
        participated = self.get_by_participant(user_id)
        
        # Combine and remove duplicates
        meeting_ids = set()
        result = []
        for meeting in organized:
            if meeting.id not in meeting_ids:
                meeting_ids.add(meeting.id)
                result.append(meeting)
        for meeting in participated:
            if meeting.id not in meeting_ids:
                meeting_ids.add(meeting.id)
                result.append(meeting)
        
        # Sort by scheduled_at descending
        result.sort(key=lambda m: m.scheduled_at, reverse=True)
        return result
    
    def update_participant_status(self, meeting_id: int, user_id: int, status: str, 
                                   confirmed_at: Optional[datetime] = None) -> Optional[MeetingParticipant]:
        """Update participant status."""
        participant = self.get_participant(meeting_id, user_id)
        if participant:
            participant.status = status
            if confirmed_at:
                participant.confirmed_at = confirmed_at
            self.db.commit()
            self.db.refresh(participant)
            return participant
        return None
    
    def delete_participant(self, meeting_id: int, user_id: int) -> bool:
        """Remove a participant from a meeting."""
        participant = self.get_participant(meeting_id, user_id)
        if participant:
            self.db.delete(participant)
            self.db.commit()
            return True
        return False

