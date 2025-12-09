"""API endpoints for notifications."""
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.notification import FCMTokenRegister, FCMTokenResponse

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.post("/token", response_model=FCMTokenResponse, status_code=status.HTTP_200_OK)
async def register_fcm_token(
    token_data: FCMTokenRegister,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Register or update user's FCM token."""
    user_repo = UserRepository(db)
    
    # Update user's FCM token
    user_repo.update(current_user.id, fcm_token=token_data.fcm_token)
    
    return FCMTokenResponse(
        success=True,
        message="FCM token registered successfully"
    )

