"""
Unit tests for FriendsService.
"""
import pytest
from app.services.friends_service import FriendsService
from app.core.exceptions import NotFoundError, ConflictError, ValidationError


@pytest.mark.unit
class TestFriendsService:
    """Test friends service."""
    
    def test_get_friends_empty(self, db_session, test_user):
        """Test getting friends when user has no friends."""
        friends_service = FriendsService(db_session)
        friends = friends_service.get_friends(test_user.id)
        
        assert friends == []
    
    def test_get_friends(self, db_session, test_user, test_user2, test_friendship):
        """Test getting friends list."""
        friends_service = FriendsService(db_session)
        friends = friends_service.get_friends(test_user.id)
        
        assert len(friends) == 1
        assert friends[0]["id"] == test_user2.id
        assert friends[0]["username"] == test_user2.username
    
    def test_send_friend_request(self, db_session, test_user, test_user2):
        """Test sending a friend request."""
        friends_service = FriendsService(db_session)
        
        friendship = friends_service.send_friend_request(test_user.id, test_user2.id)
        
        assert friendship is not None
        assert friendship["user_id"] == test_user.id or friendship["friend_id"] == test_user.id
        assert friendship["is_close_friend"] is False
    
    def test_send_friend_request_to_self(self, db_session, test_user):
        """Test that you cannot add yourself as a friend."""
        friends_service = FriendsService(db_session)
        
        with pytest.raises(ValidationError, match="Cannot add yourself as a friend"):
            friends_service.send_friend_request(test_user.id, test_user.id)
    
    def test_send_friend_request_duplicate(self, db_session, test_user, test_user2, test_friendship):
        """Test that duplicate friend request fails."""
        friends_service = FriendsService(db_session)
        
        with pytest.raises(ConflictError, match="Already friends"):
            friends_service.send_friend_request(test_user.id, test_user2.id)
    
    def test_remove_friend(self, db_session, test_user, test_user2, test_friendship):
        """Test removing a friend."""
        friends_service = FriendsService(db_session)
        
        result = friends_service.remove_friend(test_user.id, test_user2.id)
        
        assert result is True
        
        # Verify friend is removed
        friends = friends_service.get_friends(test_user.id)
        assert len(friends) == 0
    
    def test_toggle_close_friend(self, db_session, test_user, test_user2, test_friendship):
        """Test toggling close friend status."""
        friends_service = FriendsService(db_session)
        
        # Set as close friend
        friendship = friends_service.toggle_close_friend(test_user.id, test_user2.id, True)
        
        assert friendship["is_close_friend"] is True
        
        # Remove close friend status
        friendship = friends_service.toggle_close_friend(test_user.id, test_user2.id, False)
        
        assert friendship["is_close_friend"] is False
    
    def test_toggle_close_friend_nonexistent(self, db_session, test_user, test_user2):
        """Test toggling close friend for non-existent friendship."""
        friends_service = FriendsService(db_session)
        
        with pytest.raises(NotFoundError, match="Friendship not found"):
            friends_service.toggle_close_friend(test_user.id, test_user2.id, True)

