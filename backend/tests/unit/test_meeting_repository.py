"""
Unit tests for MeetingRepository.
Run these tests after implementing the repository to verify it works correctly.

Usage:
    cd backend
    source venv/bin/activate
    pytest tests/unit/test_meeting_repository.py -v
"""

import pytest
from datetime import datetime, timedelta
from sqlalchemy.orm import Session

from app.repositories.meeting_repository import MeetingRepository
from app.models.meeting import Meeting, MeetingParticipant


@pytest.mark.unit
class TestMeetingRepository:
    """Test suite for MeetingRepository."""
    
    def test_create_meeting(self, db_session: Session, test_user):
        """Test creating a meeting."""
        repo = MeetingRepository(db_session)
        scheduled_at = datetime.now() + timedelta(days=1)
        
        meeting = repo.create(
            organizer_id=test_user.id,
            title="Test Meeting",
            description="Test description",
            latitude="44.4268",
            longitude="26.1025",
            address="Bucharest",
            scheduled_at=scheduled_at
        )
        
        assert meeting is not None
        assert meeting.id is not None
        assert meeting.organizer_id == test_user.id
        assert meeting.title == "Test Meeting"
        assert meeting.status == "pending"
    
    def test_get_meeting_by_id(self, db_session: Session, test_user):
        """Test getting a meeting by ID."""
        repo = MeetingRepository(db_session)
        scheduled_at = datetime.now() + timedelta(days=1)
        
        meeting = repo.create(
            organizer_id=test_user.id,
            title="Test Meeting",
            scheduled_at=scheduled_at
        )
        
        retrieved = repo.get_by_id(meeting.id)
        assert retrieved is not None
        assert retrieved.id == meeting.id
        assert retrieved.title == "Test Meeting"
    
    def test_get_meetings_by_organizer(self, db_session: Session, test_user):
        """Test getting meetings organized by a user."""
        repo = MeetingRepository(db_session)
        scheduled_at = datetime.now() + timedelta(days=1)
        
        # Create two meetings
        meeting1 = repo.create(
            organizer_id=test_user.id,
            title="Meeting 1",
            scheduled_at=scheduled_at
        )
        meeting2 = repo.create(
            organizer_id=test_user.id,
            title="Meeting 2",
            scheduled_at=scheduled_at + timedelta(days=1)
        )
        
        meetings = repo.get_by_organizer(test_user.id)
        assert len(meetings) >= 2
        assert any(m.id == meeting1.id for m in meetings)
        assert any(m.id == meeting2.id for m in meetings)
    
    def test_update_meeting(self, db_session: Session, test_user):
        """Test updating a meeting."""
        repo = MeetingRepository(db_session)
        scheduled_at = datetime.now() + timedelta(days=1)
        
        meeting = repo.create(
            organizer_id=test_user.id,
            title="Original Title",
            scheduled_at=scheduled_at
        )
        
        updated = repo.update(meeting.id, title="Updated Title", description="New description")
        assert updated is not None
        assert updated.title == "Updated Title"
        assert updated.description == "New description"
    
    def test_delete_meeting(self, db_session: Session, test_user):
        """Test deleting a meeting."""
        repo = MeetingRepository(db_session)
        scheduled_at = datetime.now() + timedelta(days=1)
        
        meeting = repo.create(
            organizer_id=test_user.id,
            title="To Delete",
            scheduled_at=scheduled_at
        )
        
        deleted = repo.delete(meeting.id)
        assert deleted is True
        
        retrieved = repo.get_by_id(meeting.id)
        assert retrieved is None
    
    def test_add_participant(self, db_session: Session, test_user, test_user2):
        """Test adding a participant to a meeting."""
        repo = MeetingRepository(db_session)
        scheduled_at = datetime.now() + timedelta(days=1)
        
        meeting = repo.create(
            organizer_id=test_user.id,
            title="Test Meeting",
            scheduled_at=scheduled_at
        )
        
        participant = repo.add_participant(meeting.id, test_user2.id, status="pending")
        assert participant is not None
        assert participant.meeting_id == meeting.id
        assert participant.user_id == test_user2.id
        assert participant.status == "pending"
    
    def test_get_participants_by_meeting(self, db_session: Session, test_user, test_user2):
        """Test getting all participants for a meeting."""
        repo = MeetingRepository(db_session)
        scheduled_at = datetime.now() + timedelta(days=1)
        
        meeting = repo.create(
            organizer_id=test_user.id,
            title="Test Meeting",
            scheduled_at=scheduled_at
        )
        
        repo.add_participant(meeting.id, test_user2.id)
        
        participants = repo.get_participants_by_meeting(meeting.id)
        assert len(participants) == 1
        assert participants[0].user_id == test_user2.id
    
    def test_update_participant_status(self, db_session: Session, test_user, test_user2):
        """Test updating participant status."""
        repo = MeetingRepository(db_session)
        scheduled_at = datetime.now() + timedelta(days=1)
        
        meeting = repo.create(
            organizer_id=test_user.id,
            title="Test Meeting",
            scheduled_at=scheduled_at
        )
        
        repo.add_participant(meeting.id, test_user2.id, status="pending")
        
        updated = repo.update_participant_status(meeting.id, test_user2.id, "accepted")
        assert updated is not None
        assert updated.status == "accepted"
    
    def test_get_meetings_by_user_participation(self, db_session: Session, test_user, test_user2):
        """Test getting all meetings where user is organizer or participant."""
        repo = MeetingRepository(db_session)
        scheduled_at = datetime.now() + timedelta(days=1)
        
        # Create meeting where user1 is organizer
        meeting1 = repo.create(
            organizer_id=test_user.id,
            title="Organized Meeting",
            scheduled_at=scheduled_at
        )
        
        # Create meeting where user2 is organizer and user1 is participant
        meeting2 = repo.create(
            organizer_id=test_user2.id,
            title="Participated Meeting",
            scheduled_at=scheduled_at + timedelta(days=1)
        )
        repo.add_participant(meeting2.id, test_user.id)
        
        # Get all meetings for user1
        meetings = repo.get_meetings_by_user_participation(test_user.id)
        assert len(meetings) >= 2
        assert any(m.id == meeting1.id for m in meetings)
        assert any(m.id == meeting2.id for m in meetings)

