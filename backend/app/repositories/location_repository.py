from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.models.user import UserLocation, User
from app.models.user_location_history import UserLocationHistory
from typing import Optional, List
from datetime import datetime

class LocationRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def update_user_location(self, user_id: int, latitude: str, longitude: str, accuracy_m: Optional[str] = None) -> UserLocation:
        """Update or create user's current location."""
        location = self.db.query(UserLocation).filter(UserLocation.user_id == user_id).first()
        
        if location:
            location.latitude = latitude
            location.longitude = longitude
            if accuracy_m:
                location.accuracy_m = accuracy_m
            location.updated_at = datetime.utcnow()
        else:
            location = UserLocation(
                user_id=user_id,
                latitude=latitude,
                longitude=longitude,
                accuracy_m=accuracy_m
            )
            self.db.add(location)
        
        self.db.commit()
        self.db.refresh(location)
        return location
    
    def get_user_location(self, user_id: int) -> Optional[UserLocation]:
        """Get user's current location."""
        return self.db.query(UserLocation).filter(UserLocation.user_id == user_id).first()
    
    def get_friends_locations(self, user_id: int, friend_ids: List[int]) -> List[dict]:
        """Get locations for multiple friends."""
        locations = self.db.query(UserLocation, User).join(
            User, UserLocation.user_id == User.id
        ).filter(
            UserLocation.user_id.in_(friend_ids)
        ).all()
        
        result = []
        for location, user in locations:
            result.append({
                "user_id": user.id,
                "username": user.username,
                "full_name": user.full_name,
                "latitude": location.latitude,
                "longitude": location.longitude,
                "accuracy_m": location.accuracy_m,
                "updated_at": location.updated_at,
                "availability_status": user.availability_status
            })
        
        return result
    
    def add_location_history(self, user_id: int, latitude: str, longitude: str, 
                           recorded_at: datetime, altitude_m: Optional[str] = None,
                           accuracy_m: Optional[str] = None, speed_mps: Optional[str] = None,
                           heading_deg: Optional[str] = None, source: str = "gps") -> UserLocationHistory:
        """Add a location history record."""
        history = UserLocationHistory(
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
        self.db.add(history)
        self.db.commit()
        self.db.refresh(history)
        return history
    
    def get_location_history(self, user_id: int, start_date: Optional[datetime] = None, 
                            end_date: Optional[datetime] = None) -> List[UserLocationHistory]:
        """Get user's location history."""
        query = self.db.query(UserLocationHistory).filter(UserLocationHistory.user_id == user_id)
        
        if start_date:
            query = query.filter(UserLocationHistory.recorded_at >= start_date)
        if end_date:
            query = query.filter(UserLocationHistory.recorded_at <= end_date)
        
        return query.order_by(UserLocationHistory.recorded_at.desc()).all()

