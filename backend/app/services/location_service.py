from sqlalchemy.orm import Session
from app.repositories.location_repository import LocationRepository
from app.repositories.friendship_repository import FriendshipRepository
from app.repositories.user_repository import UserRepository
from app.core.exceptions import NotFoundError, ValidationError
from typing import List, Optional
from datetime import datetime

class LocationService:
    def __init__(self, db: Session):
        self.location_repo = LocationRepository(db)
        self.friendship_repo = FriendshipRepository(db)
        self.user_repo = UserRepository(db)
        self.db = db
    
    def update_location(self, user_id: int, latitude: str, longitude: str, 
                       accuracy_m: Optional[str] = None, save_history: bool = True) -> dict:
        """Update user's current location."""
        # Validate coordinates
        try:
            lat_float = float(latitude)
            lon_float = float(longitude)
            if not (-90 <= lat_float <= 90) or not (-180 <= lon_float <= 180):
                raise ValidationError("Invalid latitude or longitude values")
        except ValueError:
            raise ValidationError("Latitude and longitude must be valid numbers")
        
        # Update current location
        location = self.location_repo.update_user_location(
            user_id=user_id,
            latitude=latitude,
            longitude=longitude,
            accuracy_m=accuracy_m
        )
        
        # Save to history if enabled
        if save_history:
            user = self.user_repo.get_by_id(user_id)
            if user and user.location_sharing_enabled:
                self.location_repo.add_location_history(
                    user_id=user_id,
                    latitude=latitude,
                    longitude=longitude,
                    recorded_at=datetime.utcnow(),
                    accuracy_m=accuracy_m,
                    source="gps"
                )
        
        return {
            "user_id": location.user_id,
            "latitude": location.latitude,
            "longitude": location.longitude,
            "accuracy_m": location.accuracy_m,
            "updated_at": location.updated_at
        }
    
    def get_friends_locations(self, user_id: int, close_friends_only: bool = False) -> List[dict]:
        """Get locations of user's friends."""
        # Get friends list
        friends = self.friendship_repo.get_friends(user_id, include_close_only=close_friends_only)
        
        if not friends:
            return []
        
        # Get friend IDs
        friend_ids = [friend.id for friend in friends]
        
        # Get locations
        locations = self.location_repo.get_friends_locations(user_id, friend_ids)
        
        # Filter by location sharing enabled and close friends if needed
        result = []
        for loc in locations:
            friend = self.user_repo.get_by_id(loc["user_id"])
            if not friend or not friend.location_sharing_enabled:
                continue
            
            # If close_friends_only, check if this friend is marked as close
            if close_friends_only:
                friendship = self.friendship_repo.get_friendship(user_id, loc["user_id"])
                if not friendship or not friendship.is_close_friend:
                    continue
            
            result.append(loc)
        
        return result
    
    def add_location_history(self, user_id: int, latitude: str, longitude: str,
                           recorded_at: datetime, altitude_m: Optional[str] = None,
                           accuracy_m: Optional[str] = None, speed_mps: Optional[str] = None,
                           heading_deg: Optional[str] = None, source: str = "gps") -> dict:
        """Add a location history record."""
        history = self.location_repo.add_location_history(
            user_id=user_id,
            latitude=latitude,
            longitude=longitude,
            recorded_at=recorded_at,
            altitude_m=altitude_m,
            accuracy_m=accuracy_m,
            speed_mps=speed_mps,
            heading_deg=heading_deg,
            source=source
        )
        
        return {
            "id": history.id,
            "user_id": history.user_id,
            "latitude": history.latitude,
            "longitude": history.longitude,
            "recorded_at": history.recorded_at,
            "accuracy_m": history.accuracy_m
        }
    
    def get_location_history(self, user_id: int, start_date: Optional[datetime] = None,
                           end_date: Optional[datetime] = None) -> List[dict]:
        """Get user's location history."""
        history = self.location_repo.get_location_history(user_id, start_date, end_date)
        
        return [
            {
                "id": h.id,
                "latitude": h.latitude,
                "longitude": h.longitude,
                "recorded_at": h.recorded_at,
                "accuracy_m": h.accuracy_m,
                "altitude_m": h.altitude_m,
                "speed_mps": h.speed_mps,
                "heading_deg": h.heading_deg,
                "source": h.source
            }
            for h in history
        ]

