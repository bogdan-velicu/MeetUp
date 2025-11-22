from datetime import timedelta
from sqlalchemy.orm import Session
from app.repositories.user_repository import UserRepository
from app.repositories.role_repository import RoleRepository
from app.core.security import create_access_token
from app.core.config import settings
from app.core.exceptions import UnauthorizedError, ConflictError, ValidationError
from app.schemas.auth import UserRegister, UserLogin, Token, UserResponse
from typing import Optional

class AuthService:
    def __init__(self, db: Session):
        self.user_repo = UserRepository(db)
        self.role_repo = RoleRepository(db)
        self.db = db
    
    def register(self, user_data: UserRegister) -> tuple[UserResponse, Token]:
        """Register a new user."""
        # Check if email already exists
        if self.user_repo.get_by_email(user_data.email):
            raise ConflictError("Email already registered")
        
        # Check if username already exists
        if self.user_repo.get_by_username(user_data.username):
            raise ConflictError("Username already taken")
        
        # Create user
        user = self.user_repo.create(
            username=user_data.username,
            email=user_data.email,
            password=user_data.password,
            full_name=user_data.full_name,
            phone_number=user_data.phone_number
        )
        
        # Assign default "user" role
        default_role = self.role_repo.get_by_name("user")
        if default_role:
            self.role_repo.assign_role_to_user(user.id, default_role.id)
        
        # Create access token
        access_token = create_access_token(
            data={"sub": str(user.id), "email": user.email},
            expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        
        token = Token(access_token=access_token)
        user_response = UserResponse.model_validate(user)
        
        return user_response, token
    
    def login(self, login_data: UserLogin) -> tuple[UserResponse, Token]:
        """Authenticate user and return token."""
        user = self.user_repo.get_by_email(login_data.email)
        
        if not user:
            raise UnauthorizedError("Invalid email or password")
        
        if not user.is_active:
            raise UnauthorizedError("User account is inactive")
        
        if not self.user_repo.verify_password(user, login_data.password):
            raise UnauthorizedError("Invalid email or password")
        
        # Update last login
        self.user_repo.update_last_login(user.id)
        
        # Create access token
        access_token = create_access_token(
            data={"sub": str(user.id), "email": user.email},
            expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        
        token = Token(access_token=access_token)
        user_response = UserResponse.model_validate(user)
        
        return user_response, token
    
    def get_current_user(self, user_id: int) -> Optional[UserResponse]:
        """Get current user by ID."""
        user = self.user_repo.get_by_id(user_id)
        if not user:
            return None
        return UserResponse.model_validate(user)
    
    def refresh_token(self, user_id: int) -> Token:
        """Refresh access token for a user."""
        user = self.user_repo.get_by_id(user_id)
        if not user:
            raise UnauthorizedError("User not found")
        
        if not user.is_active:
            raise UnauthorizedError("User account is inactive")
        
        # Create new access token
        access_token = create_access_token(
            data={"sub": str(user.id), "email": user.email},
            expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        
        return Token(access_token=access_token)
