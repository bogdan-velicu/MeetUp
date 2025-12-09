"""
Unit tests for MeetingsService.
Run these tests after implementing the service to verify it works correctly.

Usage:
    cd backend
    source venv/bin/activate
    pytest tests/unit/test_meetings_service.py -v
"""

import pytest
from datetime import datetime, timedelta
from sqlalchemy.orm import Session

from app.models.user import User
from app.services.meetings_service import MeetingsService
from app.repositories.meeting_repository import MeetingRepository
from app.repositories.user_repository import UserRepository
from app.repositories.friendship_repository import FriendshipRepository
from app.core.exceptions import NotFoundError, ValidationError, UnauthorizedError


@pytest.mark.unit
class TestMeetingsService:
    """Test suite for MeetingsService."""
    
    def test_create_meeting_success(self, db_session: Session, test_user: User, test_user2: User):
        """Test creating a meeting successfully."""
        # Arrange: Make users friends
        friendship_repo = FriendshipRepository(db_session)
        friendship_repo.create(test_user.id, test_user2.id, status="accepted")
        
        # Arrange: Prepare meeting data
        scheduled_at = datetime.now() + timedelta(days=1)
        meeting_data = {
            "title": "Test Meeting",
            "description": "Test description",
            "latitude": "44.4268",
            "longitude": "26.1025",
            "address": "Bucharest",
            "scheduled_at": scheduled_at,
            "participant_ids": [test_user2.id]
        }
        
        # Act: Create meeting
        service = MeetingsService(db_session)
        meeting = service.create_meeting(test_user.id, meeting_data)
        
        # Assert: Verify meeting was created
        assert meeting is not None
        assert meeting.id is not None
        assert meeting.organizer_id == test_user.id
        assert meeting.title == "Test Meeting"
        assert meeting.status == "pending"
        
        # Assert: Verify participants were created
        repo = MeetingRepository(db_session)
        participants = repo.get_participants_by_meeting(meeting.id)
        assert len(participants) == 1
        assert participants[0].user_id == test_user2.id
        assert participants[0].status == "pending"
    
    def test_create_meeting_with_non_friend(self, db_session: Session, test_user: User, test_user2: User):
        """Test that creating a meeting with non-friend fails."""
        # Arrange: Users are NOT friends
        scheduled_at = datetime.now() + timedelta(days=1)
        meeting_data = {
            "title": "Test Meeting",
            "description": "Test description",
            "latitude": "44.4268",
            "longitude": "26.1025",
            "address": "Bucharest",
            "scheduled_at": scheduled_at,
            "participant_ids": [test_user2.id]
        }
        
        # Act & Assert: Should raise ValidationError
        service = MeetingsService(db_session)
        with pytest.raises(ValidationError, match="not a friend"):
            service.create_meeting(test_user.id, meeting_data)
    
    def test_create_meeting_past_date(self, db_session: Session, test_user: User, test_user2: User):
        """Test that creating a meeting with past date fails."""
        # Arrange: Make users friends
        friendship_repo = FriendshipRepository(db_session)
        friendship_repo.create(test_user.id, test_user2.id, status="accepted")
        
        # Arrange: Past date
        scheduled_at = datetime.now() - timedelta(days=1)
        meeting_data = {
            "title": "Test Meeting",
            "scheduled_at": scheduled_at,
            "participant_ids": [test_user2.id]
        }
        
        # Act & Assert: Should raise ValidationError
        service = MeetingsService(db_session)
        with pytest.raises(ValidationError, match="future"):
            service.create_meeting(test_user.id, meeting_data)
    
    def test_get_meetings_organized(self, db_session: Session, test_user: User, test_user2: User):
        """Test getting meetings organized by user."""
        # Arrange: Create a meeting
        friendship_repo = FriendshipRepository(db_session)
        friendship_repo.create(test_user.id, test_user2.id, status="accepted")
        
        service = MeetingsService(db_session)
        scheduled_at = datetime.now() + timedelta(days=1)
        meeting = service.create_meeting(test_user.id, {
            "title": "My Meeting",
            "scheduled_at": scheduled_at,
            "participant_ids": [test_user2.id]
        })
        
        # Act: Get meetings
        meetings = service.get_meetings(test_user.id, filter_type="organized")
        
        # Assert
        assert len(meetings) >= 1
        assert any(m["id"] == meeting.id for m in meetings)
    
    def test_get_meeting_by_id(self, db_session: Session, test_user: User, test_user2: User):
        """Test getting a specific meeting by ID."""
        # Arrange: Create a meeting
        friendship_repo = FriendshipRepository(db_session)
        friendship_repo.create(test_user.id, test_user2.id, status="accepted")
        
        service = MeetingsService(db_session)
        scheduled_at = datetime.now() + timedelta(days=1)
        meeting = service.create_meeting(test_user.id, {
            "title": "My Meeting",
            "scheduled_at": scheduled_at,
            "participant_ids": [test_user2.id]
        })
        
        # Act: Get meeting
        retrieved = service.get_meeting_by_id(meeting.id, test_user.id)
        
        # Assert
        assert retrieved is not None
        assert retrieved["id"] == meeting.id
        assert retrieved["title"] == "My Meeting"
    
    def test_update_meeting_organizer_only(self, db_session: Session, test_user: User, test_user2: User):
        """Test that only organizer can update meeting."""
        # Arrange: Create a meeting
        friendship_repo = FriendshipRepository(db_session)
        friendship_repo.create(test_user.id, test_user2.id, status="accepted")
        
        service = MeetingsService(db_session)
        scheduled_at = datetime.now() + timedelta(days=1)
        meeting = service.create_meeting(test_user.id, {
            "title": "Original Title",
            "scheduled_at": scheduled_at,
            "participant_ids": [test_user2.id]
        })
        
        # Act: Update as organizer (should work)
        updated = service.update_meeting(meeting.id, test_user.id, {"title": "Updated Title"})
        assert updated["title"] == "Updated Title"
        
        # Act & Assert: Update as non-organizer (should fail)
        with pytest.raises(UnauthorizedError):
            service.update_meeting(meeting.id, test_user2.id, {"title": "Hacked Title"})
    
    def test_delete_meeting_organizer_only(self, db_session: Session, test_user: User, test_user2: User):
        """Test that only organizer can delete meeting."""
        # Arrange: Create a meeting
        friendship_repo = FriendshipRepository(db_session)
        friendship_repo.create(test_user.id, test_user2.id, status="accepted")
        
        service = MeetingsService(db_session)
        scheduled_at = datetime.now() + timedelta(days=1)
        meeting = service.create_meeting(test_user.id, {
            "title": "To Delete",
            "scheduled_at": scheduled_at,
            "participant_ids": [test_user2.id]
        })
        
        # Act: Delete as organizer (should work)
        service.delete_meeting(meeting.id, test_user.id)
        
        # Assert: Meeting should be deleted
        with pytest.raises(NotFoundError):
            service.get_meeting_by_id(meeting.id, test_user.id)
        
        # Act & Assert: Try to delete as non-organizer (should fail)
        # (This test would need a new meeting since we deleted the first one)
        meeting2 = service.create_meeting(test_user.id, {
            "title": "Another Meeting",
            "scheduled_at": scheduled_at,
            "participant_ids": [test_user2.id]
        })
        
        with pytest.raises(UnauthorizedError):
            service.delete_meeting(meeting2.id, test_user2.id)

