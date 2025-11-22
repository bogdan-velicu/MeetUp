from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.services.auth_service import AuthService
from app.schemas.auth import UserRegister, UserLogin, Token, UserResponse, TokenRefresh
from app.core.dependencies import get_current_user
from app.models.user import User

router = APIRouter(prefix="/auth", tags=["authentication"])

@router.post("/register", response_model=dict, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserRegister,
    db: Session = Depends(get_db)
):
    """Register a new user."""
    auth_service = AuthService(db)
    user, token = auth_service.register(user_data)
    return {
        "user": user,
        "token": token
    }

@router.post("/login", response_model=dict)
async def login(
    login_data: UserLogin,
    db: Session = Depends(get_db)
):
    """Login and get access token."""
    auth_service = AuthService(db)
    user, token = auth_service.login(login_data)
    return {
        "user": user,
        "token": token
    }

@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: User = Depends(get_current_user)
):
    """Get current authenticated user."""
    return UserResponse.model_validate(current_user)

@router.post("/refresh", response_model=Token)
async def refresh_token(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Refresh access token."""
    auth_service = AuthService(db)
    token = auth_service.refresh_token(current_user.id)
    return token
