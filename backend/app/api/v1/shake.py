from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from typing import Optional
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.shake_service import ShakeService
from app.schemas.shake import (
    ShakeInitiateRequest,
    ShakeInitiateResponse,
    NearbyFriendsResponse,
    ShakeSessionResponse
)

router = APIRouter(prefix="/shake", tags=["shake"])


@router.post("/initiate", response_model=ShakeInitiateResponse, status_code=status.HTTP_200_OK)
async def initiate_shake(
    shake_data: ShakeInitiateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Initiate a shake session when user shakes their phone.
    Automatically checks for nearby friends and matches if found.
    """
    service = ShakeService(db)
    result = service.initiate_shake(
        user_id=current_user.id,
        latitude=shake_data.latitude,
        longitude=shake_data.longitude,
        accuracy_m=shake_data.accuracy_m
    )
    return result


@router.get("/nearby-friends", response_model=NearbyFriendsResponse)
async def get_nearby_shaking_friends(
    latitude: float = Query(..., description="Current latitude"),
    longitude: float = Query(..., description="Current longitude"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get list of nearby friends who are currently shaking."""
    service = ShakeService(db)
    friends = service.get_nearby_shaking_friends(
        user_id=current_user.id,
        latitude=latitude,
        longitude=longitude
    )
    return {"nearby_friends": friends}


@router.get("/active-session", response_model=Optional[ShakeSessionResponse])
async def get_active_session(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's active shake session if one exists."""
    service = ShakeService(db)
    session = service.get_active_session(current_user.id)
    return session

