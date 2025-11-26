from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.repositories.user_repository import UserRepository
from typing import List

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/search", response_model=List[dict])
async def search_users(
    q: str = Query(..., description="Search query (username or email)"),
    limit: int = Query(20, le=50, description="Maximum number of results"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Search for users by username or email."""
    user_repo = UserRepository(db)
    
    # Search users excluding the current user
    users = user_repo.search_users(q, exclude_user_id=current_user.id, limit=limit)
    
    # Return basic user info for search results
    return [
        {
            "id": user.id,
            "username": user.username,
            "full_name": user.full_name,
            "bio": user.bio,
            "profile_photo_url": user.profile_photo_url,
            "availability_status": user.availability_status,
        }
        for user in users
    ]
