from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from app.models.friendship import Friendship
from app.models.user import User
from typing import List, Optional

class FriendshipRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def create(self, user_id: int, friend_id: int, status: str = "pending", is_close_friend: bool = False) -> Friendship:
        """Create a new friendship."""
        friendship = Friendship(
            user_id=user_id,
            friend_id=friend_id,
            status=status,
            is_close_friend=is_close_friend
        )
        self.db.add(friendship)
        self.db.commit()
        self.db.refresh(friendship)
        return friendship
    
    def get_friendship(self, user_id: int, friend_id: int) -> Optional[Friendship]:
        """Get friendship between two users."""
        # Check both directions
        friendship = self.db.query(Friendship).filter(
            and_(
                or_(
                    and_(Friendship.user_id == user_id, Friendship.friend_id == friend_id),
                    and_(Friendship.user_id == friend_id, Friendship.friend_id == user_id)
                )
            )
        ).first()
        return friendship
    
    def get_friends(self, user_id: int, include_close_only: bool = False, status_filter: str = "accepted") -> List[User]:
        """Get all friends of a user with specific status."""
        # Get friendships where user is either user_id or friend_id
        # Use a more explicit query to ensure we get all friends correctly
        friendships = self.db.query(Friendship).filter(
            and_(
                or_(
                    Friendship.user_id == user_id,
                    Friendship.friend_id == user_id
                ),
                Friendship.status == status_filter
            )
        ).all()
        
        # Extract friend IDs
        friend_ids = set()
        for friendship in friendships:
            if friendship.user_id == user_id:
                friend_ids.add(friendship.friend_id)
            else:
                friend_ids.add(friendship.user_id)
        
        if not friend_ids:
            return []
        
        # Get users and apply close friends filter if needed
        query = self.db.query(User).filter(User.id.in_(friend_ids))
        
        if include_close_only:
            # Filter to only close friends
            close_friend_ids = set()
            for friendship in friendships:
                if friendship.is_close_friend:
                    if friendship.user_id == user_id:
                        close_friend_ids.add(friendship.friend_id)
                    else:
                        close_friend_ids.add(friendship.user_id)
            
            if close_friend_ids:
                query = query.filter(User.id.in_(close_friend_ids))
            else:
                return []  # No close friends
        
        return query.all()
    
    def delete_friendship(self, user_id: int, friend_id: int) -> bool:
        """Delete friendship between two users."""
        friendship = self.get_friendship(user_id, friend_id)
        if friendship:
            self.db.delete(friendship)
            self.db.commit()
            return True
        return False
    
    def update_close_friend_status(self, user_id: int, friend_id: int, is_close_friend: bool) -> Optional[Friendship]:
        """Update close friend status."""
        friendship = self.get_friendship(user_id, friend_id)
        if friendship:
            friendship.is_close_friend = is_close_friend
            self.db.commit()
            self.db.refresh(friendship)
            return friendship
        return None
    
    def update_friendship_status(self, user_id: int, friend_id: int, status: str) -> Optional[Friendship]:
        """Update friendship status."""
        friendship = self.get_friendship(user_id, friend_id)
        if friendship:
            friendship.status = status
            self.db.commit()
            self.db.refresh(friendship)
            return friendship
        return None
    
    def get_pending_requests(self, user_id: int) -> List[Friendship]:
        """Get pending friend requests for a user (requests sent TO this user)."""
        return self.db.query(Friendship).filter(
            and_(
                Friendship.friend_id == user_id,
                Friendship.status == "pending"
            )
        ).all()
    
    def get_sent_requests(self, user_id: int) -> List[Friendship]:
        """Get sent friend requests by a user (requests sent BY this user)."""
        return self.db.query(Friendship).filter(
            and_(
                Friendship.user_id == user_id,
                Friendship.status == "pending"
            )
        ).all()

