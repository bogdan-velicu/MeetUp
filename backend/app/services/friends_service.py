from sqlalchemy.orm import Session
from app.repositories.friendship_repository import FriendshipRepository
from app.repositories.user_repository import UserRepository
from app.core.exceptions import NotFoundError, ConflictError, ValidationError
from app.models.user import User
from typing import List

class FriendsService:
    def __init__(self, db: Session):
        self.friendship_repo = FriendshipRepository(db)
        self.user_repo = UserRepository(db)
        self.db = db
    
    def get_friends(self, user_id: int, close_friends_only: bool = False) -> List[dict]:
        """Get list of friends for a user."""
        friends = self.friendship_repo.get_friends(user_id, include_close_only=close_friends_only)
        
        result = []
        for friend in friends:
            friendship = self.friendship_repo.get_friendship(user_id, friend.id)
            result.append({
                "id": friend.id,
                "username": friend.username,
                "full_name": friend.full_name,
                "email": friend.email,
                "profile_photo_url": friend.profile_photo_url,
                "availability_status": friend.availability_status,
                "is_close_friend": friendship.is_close_friend if friendship else False
            })
        
        return result
    
    def send_friend_request(self, user_id: int, friend_id: int) -> dict:
        """Send a friend request (create friendship immediately - simplified for now)."""
        if user_id == friend_id:
            raise ValidationError("Cannot add yourself as a friend")
        
        # Check if friend exists
        friend = self.user_repo.get_by_id(friend_id)
        if not friend:
            raise NotFoundError("User not found")
        
        # Check if already friends
        existing = self.friendship_repo.get_friendship(user_id, friend_id)
        if existing:
            raise ConflictError("Already friends with this user")
        
        # Create friendship (in a real app, you'd have a pending status)
        friendship = self.friendship_repo.create(user_id, friend_id, is_close_friend=False)
        
        return {
            "id": friendship.id,
            "user_id": friendship.user_id,
            "friend_id": friendship.friend_id,
            "is_close_friend": friendship.is_close_friend,
            "created_at": friendship.created_at
        }
    
    def accept_friend_request(self, user_id: int, friend_id: int) -> dict:
        """Accept a friend request (for now, same as send - simplified)."""
        # In a full implementation, this would change status from pending to accepted
        # For now, we'll just verify the friendship exists
        friendship = self.friendship_repo.get_friendship(user_id, friend_id)
        if not friendship:
            raise NotFoundError("Friend request not found")
        
        return {
            "id": friendship.id,
            "user_id": friendship.user_id,
            "friend_id": friendship.friend_id,
            "is_close_friend": friendship.is_close_friend,
            "created_at": friendship.created_at
        }
    
    def remove_friend(self, user_id: int, friend_id: int) -> bool:
        """Remove a friend."""
        return self.friendship_repo.delete_friendship(user_id, friend_id)
    
    def toggle_close_friend(self, user_id: int, friend_id: int, is_close_friend: bool) -> dict:
        """Toggle close friend status."""
        friendship = self.friendship_repo.update_close_friend_status(user_id, friend_id, is_close_friend)
        if not friendship:
            raise NotFoundError("Friendship not found")
        
        return {
            "id": friendship.id,
            "user_id": friendship.user_id,
            "friend_id": friendship.friend_id,
            "is_close_friend": friendship.is_close_friend
        }

