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
        """Get list of accepted friends for a user."""
        friends = self.friendship_repo.get_friends(user_id, include_close_only=close_friends_only, status_filter="accepted")
        
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
                "is_close_friend": friendship.is_close_friend if friendship else False,
                "status": friendship.status if friendship else "unknown"
            })
        
        return result
    
    def send_friend_request(self, user_id: int, friend_id: int) -> dict:
        """Send a friend request with pending status."""
        if user_id == friend_id:
            raise ValidationError("Cannot add yourself as a friend")
        
        # Check if friend exists
        friend = self.user_repo.get_by_id(friend_id)
        if not friend:
            raise NotFoundError("User not found")
        
        # Check if already friends or request exists
        existing = self.friendship_repo.get_friendship(user_id, friend_id)
        if existing:
            if existing.status == "pending":
                raise ConflictError("Friend request already sent")
            elif existing.status == "accepted":
                raise ConflictError("Already friends with this user")
        
        # Create friendship with pending status
        friendship = self.friendship_repo.create(user_id, friend_id, status="pending", is_close_friend=False)
        
        return {
            "id": friendship.id,
            "user_id": friendship.user_id,
            "friend_id": friendship.friend_id,
            "status": friendship.status,
            "is_close_friend": friendship.is_close_friend,
            "created_at": friendship.created_at
        }
    
    def accept_friend_request(self, user_id: int, friend_id: int) -> dict:
        """Accept a friend request by changing status to accepted."""
        # Find the pending friend request where friend_id sent request to user_id
        friendship = self.friendship_repo.get_friendship(friend_id, user_id)
        if not friendship or friendship.status != "pending":
            raise NotFoundError("Pending friend request not found")
        
        # Update status to accepted
        friendship = self.friendship_repo.update_friendship_status(friend_id, user_id, "accepted")
        
        # Create reciprocal friendship (both directions)
        reciprocal = self.friendship_repo.get_friendship(user_id, friend_id)
        if not reciprocal:
            self.friendship_repo.create(user_id, friend_id, status="accepted", is_close_friend=False)
        
        return {
            "id": friendship.id,
            "user_id": friendship.user_id,
            "friend_id": friendship.friend_id,
            "status": friendship.status,
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
    
    def get_pending_friend_requests(self, user_id: int) -> List[dict]:
        """Get pending friend requests for a user (incoming requests)."""
        pending_requests = self.friendship_repo.get_pending_requests(user_id)
        
        result = []
        for friendship in pending_requests:
            # Get the user who sent the request
            requester = self.user_repo.get_by_id(friendship.user_id)
            if requester:
                result.append({
                    "id": friendship.id,
                    "user_id": requester.id,
                    "username": requester.username,
                    "full_name": requester.full_name,
                    "profile_photo_url": requester.profile_photo_url,
                    "status": friendship.status,
                    "created_at": friendship.created_at
                })
        
        return result
    
    def get_sent_friend_requests(self, user_id: int) -> List[dict]:
        """Get sent friend requests by a user (outgoing requests)."""
        sent_requests = self.friendship_repo.get_sent_requests(user_id)
        
        result = []
        for friendship in sent_requests:
            # Get the user who received the request
            recipient = self.user_repo.get_by_id(friendship.friend_id)
            if recipient:
                result.append({
                    "id": friendship.id,
                    "user_id": recipient.id,
                    "username": recipient.username,
                    "full_name": recipient.full_name,
                    "profile_photo_url": recipient.profile_photo_url,
                    "status": friendship.status,
                    "created_at": friendship.created_at
                })
        
        return result

