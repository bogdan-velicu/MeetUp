from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.friends_service import FriendsService
from app.schemas.friends import FriendResponse, FriendRequest, FriendshipResponse, CloseFriendUpdate

router = APIRouter(prefix="/friends", tags=["friends"])

@router.get("", response_model=list[FriendResponse])
async def get_friends(
    close_friends_only: bool = Query(False, description="Filter to close friends only"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get list of user's friends."""
    friends_service = FriendsService(db)
    friends = friends_service.get_friends(current_user.id, close_friends_only=close_friends_only)
    return friends

@router.post("/{friend_id}/request", response_model=FriendshipResponse, status_code=status.HTTP_201_CREATED)
async def send_friend_request(
    friend_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a friend request."""
    friends_service = FriendsService(db)
    friendship = friends_service.send_friend_request(current_user.id, friend_id)
    return friendship

@router.patch("/{friend_id}/accept", response_model=FriendshipResponse)
async def accept_friend_request(
    friend_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Accept a friend request."""
    friends_service = FriendsService(db)
    friendship = friends_service.accept_friend_request(current_user.id, friend_id)
    return friendship

@router.delete("/{friend_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_friend(
    friend_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Remove a friend."""
    friends_service = FriendsService(db)
    friends_service.remove_friend(current_user.id, friend_id)
    return None

@router.patch("/{friend_id}/close-status", response_model=FriendshipResponse)
async def update_close_friend_status(
    friend_id: int,
    update_data: CloseFriendUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update close friend status."""
    friends_service = FriendsService(db)
    friendship = friends_service.toggle_close_friend(
        current_user.id, 
        friend_id, 
        update_data.is_close_friend
    )
    return friendship

