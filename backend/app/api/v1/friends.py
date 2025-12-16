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

@router.get("/debug/{friend_id}", response_model=dict)
async def debug_friendship(
    friend_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Debug endpoint to check friendship status between current user and friend."""
    from app.repositories.friendship_repository import FriendshipRepository
    from app.repositories.user_repository import UserRepository
    
    friendship_repo = FriendshipRepository(db)
    user_repo = UserRepository(db)
    
    friend = user_repo.get_by_id(friend_id)
    if not friend:
        return {"error": f"User {friend_id} not found"}
    
    # Get friendship in both directions
    friendship_1 = friendship_repo.get_friendship(current_user.id, friend_id)
    friendship_2 = friendship_repo.get_friendship(friend_id, current_user.id)
    
    # Get all friends for both users
    current_user_friends = friendship_repo.get_friends(current_user.id, status_filter="accepted")
    friend_friends = friendship_repo.get_friends(friend_id, status_filter="accepted")
    
    return {
        "current_user_id": current_user.id,
        "current_user_username": current_user.username,
        "friend_id": friend_id,
        "friend_username": friend.username,
        "friendship_1_to_2": {
            "exists": friendship_1 is not None,
            "status": friendship_1.status if friendship_1 else None,
            "is_close": friendship_1.is_close_friend if friendship_1 else None,
        } if friendship_1 else None,
        "friendship_2_to_1": {
            "exists": friendship_2 is not None,
            "status": friendship_2.status if friendship_2 else None,
            "is_close": friendship_2.is_close_friend if friendship_2 else None,
        } if friendship_2 else None,
        "current_user_friends_count": len(current_user_friends),
        "current_user_friends_ids": [f.id for f in current_user_friends],
        "friend_friends_count": len(friend_friends),
        "friend_friends_ids": [f.id for f in friend_friends],
        "current_user_sees_friend": friend_id in [f.id for f in current_user_friends],
        "friend_sees_current_user": current_user.id in [f.id for f in friend_friends],
    }

@router.get("/requests/pending", response_model=list[dict])
async def get_pending_friend_requests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get pending friend requests for the current user (incoming requests)."""
    friends_service = FriendsService(db)
    requests = friends_service.get_pending_friend_requests(current_user.id)
    return requests

@router.get("/requests/sent", response_model=list[dict])
async def get_sent_friend_requests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get sent friend requests by the current user (outgoing requests)."""
    friends_service = FriendsService(db)
    requests = friends_service.get_sent_friend_requests(current_user.id)
    return requests

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

@router.patch("/{friend_id}/decline", status_code=status.HTTP_204_NO_CONTENT)
async def decline_friend_request(
    friend_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Decline a friend request."""
    friends_service = FriendsService(db)
    friends_service.remove_friend(friend_id, current_user.id)  # Remove the pending request
    return None

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

