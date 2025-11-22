from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from app.models.friendship import Friendship
from app.models.user import User
from typing import List, Optional

class FriendshipRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def create(self, user_id: int, friend_id: int, is_close_friend: bool = False) -> Friendship:
        """Create a new friendship."""
        # Ensure user_id < friend_id for consistency
        if user_id > friend_id:
            user_id, friend_id = friend_id, user_id
        
        friendship = Friendship(
            user_id=user_id,
            friend_id=friend_id,
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
    
    def get_friends(self, user_id: int, include_close_only: bool = False) -> List[User]:
        """Get all friends of a user."""
        query = self.db.query(User).join(
            Friendship,
            or_(
                and_(Friendship.user_id == user_id, User.id == Friendship.friend_id),
                and_(Friendship.friend_id == user_id, User.id == Friendship.user_id)
            )
        )
        
        if include_close_only:
            query = query.filter(
                or_(
                    and_(Friendship.user_id == user_id, Friendship.is_close_friend == True),
                    and_(Friendship.friend_id == user_id, Friendship.is_close_friend == True)
                )
            )
        
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

