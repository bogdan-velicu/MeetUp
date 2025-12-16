from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func, cast
from sqlalchemy.types import Float
from app.models.shake_session import ShakeSession, ShakeSessionStatus
from typing import Optional, List
from datetime import datetime, timedelta

class ShakeRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def create_session(
        self,
        user_id: int,
        latitude: str,
        longitude: str,
        accuracy_m: Optional[str] = None,
        expires_in_seconds: int = 15
    ) -> ShakeSession:
        """Create a new shake session."""
        expires_at = datetime.utcnow() + timedelta(seconds=expires_in_seconds)
        
        session = ShakeSession(
            user_id=user_id,
            latitude=latitude,
            longitude=longitude,
            accuracy_m=accuracy_m,
            expires_at=expires_at,
            status=ShakeSessionStatus.ACTIVE
        )
        self.db.add(session)
        self.db.commit()
        self.db.refresh(session)
        return session
    
    def get_active_session_by_user(self, user_id: int) -> Optional[ShakeSession]:
        """Get user's active shake session."""
        return self.db.query(ShakeSession).filter(
            and_(
                ShakeSession.user_id == user_id,
                ShakeSession.status == ShakeSessionStatus.ACTIVE,
                ShakeSession.expires_at > datetime.utcnow()
            )
        ).first()
    
    def find_nearby_active_sessions(
        self,
        user_id: int,
        latitude: float,
        longitude: float,
        max_distance_m: float = 100.0,
        time_window_seconds: int = 15
    ) -> List[ShakeSession]:
        """
        Find nearby active shake sessions from friends.
        Uses a bounding box approximation for initial filtering, then calculates exact distance.
        """
        # Bounding box approximation (rough, but fast for initial filtering)
        # 1 degree latitude ≈ 111 km, so 100m ≈ 0.0009 degrees
        # For longitude, it varies by latitude, but we'll use a conservative estimate
        lat_delta = max_distance_m / 111000.0  # ~0.0009 for 100m
        lon_delta = max_distance_m / (111000.0 * abs(1.0 / (1.0 + latitude / 90.0)))  # Adjust for latitude
        
        time_threshold = datetime.utcnow() - timedelta(seconds=time_window_seconds)
        
        # Get all active sessions within bounding box
        sessions = self.db.query(ShakeSession).filter(
            and_(
                ShakeSession.user_id != user_id,  # Exclude self
                ShakeSession.status == ShakeSessionStatus.ACTIVE,
                ShakeSession.expires_at > datetime.utcnow(),
                ShakeSession.created_at >= time_threshold,
                # Bounding box filter - cast string columns to float for comparison
                func.abs(cast(ShakeSession.latitude, Float) - latitude) <= lat_delta,
                func.abs(cast(ShakeSession.longitude, Float) - longitude) <= lon_delta,
            )
        ).all()
        
        # Filter by exact distance using Haversine formula
        nearby_sessions = []
        for session in sessions:
            try:
                session_lat = float(session.latitude)
                session_lon = float(session.longitude)
                distance = self._haversine_distance(latitude, longitude, session_lat, session_lon)
                if distance <= max_distance_m:
                    nearby_sessions.append(session)
            except (ValueError, TypeError):
                continue  # Skip invalid coordinates
        
        return nearby_sessions
    
    def _haversine_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """
        Calculate distance between two points using Haversine formula.
        Returns distance in meters.
        """
        from math import radians, sin, cos, sqrt, atan2
        
        R = 6371000  # Earth radius in meters
        
        lat1_rad = radians(lat1)
        lat2_rad = radians(lat2)
        delta_lat = radians(lat2 - lat1)
        delta_lon = radians(lon2 - lon1)
        
        a = sin(delta_lat / 2) ** 2 + cos(lat1_rad) * cos(lat2_rad) * sin(delta_lon / 2) ** 2
        c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return R * c
    
    def match_sessions(self, session1_id: int, session2_id: int, meeting_id: int) -> tuple[ShakeSession, ShakeSession]:
        """Match two shake sessions and mark them as matched."""
        session1 = self.db.query(ShakeSession).filter(ShakeSession.id == session1_id).first()
        session2 = self.db.query(ShakeSession).filter(ShakeSession.id == session2_id).first()
        
        if not session1 or not session2:
            raise ValueError("One or both sessions not found")
        
        if session1.status != ShakeSessionStatus.ACTIVE or session2.status != ShakeSessionStatus.ACTIVE:
            raise ValueError("One or both sessions are not active")
        
        now = datetime.utcnow()
        session1.status = ShakeSessionStatus.MATCHED
        session1.matched_user_id = session2.user_id
        session1.matched_at = now
        session1.meeting_id = meeting_id
        
        session2.status = ShakeSessionStatus.MATCHED
        session2.matched_user_id = session1.user_id
        session2.matched_at = now
        session2.meeting_id = meeting_id
        
        self.db.commit()
        self.db.refresh(session1)
        self.db.refresh(session2)
        
        return session1, session2
    
    def expire_old_sessions(self) -> int:
        """Expire sessions that have passed their expiration time. Returns count of expired sessions."""
        expired = self.db.query(ShakeSession).filter(
            and_(
                ShakeSession.status == ShakeSessionStatus.ACTIVE,
                ShakeSession.expires_at <= datetime.utcnow()
            )
        ).update({"status": ShakeSessionStatus.EXPIRED})
        self.db.commit()
        return expired
    
    def get_session_by_id(self, session_id: int) -> Optional[ShakeSession]:
        """Get shake session by ID."""
        return self.db.query(ShakeSession).filter(ShakeSession.id == session_id).first()

