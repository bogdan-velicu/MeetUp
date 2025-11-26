from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from app.models.user import User
from app.core.security import get_password_hash, verify_password
from typing import Optional, List

class UserRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def create(self, username: str, email: str, password: str, full_name: str, phone_number: Optional[str] = None) -> User:
        """Create a new user."""
        hashed_password = get_password_hash(password)
        user = User(
            username=username,
            email=email,
            password_hash=hashed_password,
            full_name=full_name,
            phone_number=phone_number
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user
    
    def get_by_id(self, user_id: int) -> Optional[User]:
        """Get user by ID."""
        return self.db.query(User).filter(User.id == user_id).first()
    
    def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email."""
        return self.db.query(User).filter(User.email == email).first()
    
    def get_by_username(self, username: str) -> Optional[User]:
        """Get user by username."""
        return self.db.query(User).filter(User.username == username).first()
    
    def get_by_email_or_username(self, identifier: str) -> Optional[User]:
        """Get user by email or username."""
        return self.db.query(User).filter(
            or_(User.email == identifier, User.username == identifier)
        ).first()
    
    def verify_password(self, user: User, password: str) -> bool:
        """Verify user password."""
        return verify_password(password, user.password_hash)
    
    def update_last_login(self, user_id: int):
        """Update user's last login timestamp."""
        user = self.get_by_id(user_id)
        if user:
            from datetime import datetime
            user.last_login_at = datetime.utcnow()
            self.db.commit()
    
    def search_users(self, query: str, exclude_user_id: Optional[int] = None, limit: int = 20) -> List[User]:
        """Search users by username or email."""
        search_filter = or_(
            User.username.ilike(f"%{query}%"),
            User.full_name.ilike(f"%{query}%"),
            User.email.ilike(f"%{query}%")
        )
        
        query_builder = self.db.query(User).filter(
            and_(
                search_filter,
                User.is_active == True
            )
        )
        
        if exclude_user_id:
            query_builder = query_builder.filter(User.id != exclude_user_id)
        
        return query_builder.limit(limit).all()
