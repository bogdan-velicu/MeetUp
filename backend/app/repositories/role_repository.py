from sqlalchemy.orm import Session
from app.models.role import Role, UserRole
from typing import Optional

class RoleRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def get_by_name(self, name: str) -> Optional[Role]:
        """Get role by name."""
        return self.db.query(Role).filter(Role.name == name).first()
    
    def assign_role_to_user(self, user_id: int, role_id: int) -> UserRole:
        """Assign a role to a user."""
        user_role = UserRole(
            user_id=user_id,
            role_id=role_id,
            status="active"
        )
        self.db.add(user_role)
        self.db.commit()
        self.db.refresh(user_role)
        return user_role
    
    def user_has_role(self, user_id: int, role_name: str) -> bool:
        """Check if user has a specific role."""
        role = self.get_by_name(role_name)
        if not role:
            return False
        
        user_role = self.db.query(UserRole).filter(
            UserRole.user_id == user_id,
            UserRole.role_id == role.id,
            UserRole.status == "active"
        ).first()
        
        return user_role is not None
