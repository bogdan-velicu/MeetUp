from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.location_service import LocationService
from app.schemas.location import (
    LocationUpdate, 
    LocationResponse, 
    FriendLocationResponse,
    LocationHistoryCreate,
    LocationHistoryResponse
)

router = APIRouter(prefix="/location", tags=["location"])

@router.patch("/update", response_model=LocationResponse)
async def update_location(
    location_data: LocationUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update user's current location."""
    location_service = LocationService(db)
    location = location_service.update_location(
        user_id=current_user.id,
        latitude=location_data.latitude,
        longitude=location_data.longitude,
        accuracy_m=location_data.accuracy_m,
        save_history=location_data.save_history
    )
    return location

@router.get("/friends/locations", response_model=list[FriendLocationResponse])
async def get_friends_locations(
    close_friends_only: bool = Query(False, description="Filter to close friends only"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get locations of user's friends."""
    location_service = LocationService(db)
    locations = location_service.get_friends_locations(
        current_user.id, 
        close_friends_only=close_friends_only
    )
    return locations

@router.post("/history", response_model=LocationHistoryResponse, status_code=201)
async def add_location_history(
    history_data: LocationHistoryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Add a location history record."""
    location_service = LocationService(db)
    history = location_service.add_location_history(
        user_id=current_user.id,
        latitude=history_data.latitude,
        longitude=history_data.longitude,
        recorded_at=history_data.recorded_at,
        altitude_m=history_data.altitude_m,
        accuracy_m=history_data.accuracy_m,
        speed_mps=history_data.speed_mps,
        heading_deg=history_data.heading_deg,
        source=history_data.source
    )
    return history

@router.get("/history", response_model=list[LocationHistoryResponse])
async def get_location_history(
    start_date: Optional[datetime] = Query(None, description="Start date for history"),
    end_date: Optional[datetime] = Query(None, description="End date for history"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's location history."""
    location_service = LocationService(db)
    history = location_service.get_location_history(
        current_user.id,
        start_date=start_date,
        end_date=end_date
    )
    return history

