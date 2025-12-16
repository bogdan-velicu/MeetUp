"""Shake to MeetUp Service - Handles shake detection and matching."""
from sqlalchemy.orm import Session
from typing import Dict, List, Optional
from datetime import datetime, timedelta
from app.repositories.shake_repository import ShakeRepository
from app.repositories.friendship_repository import FriendshipRepository
from app.repositories.user_repository import UserRepository
from app.repositories.meeting_repository import MeetingRepository
from app.services.meetings_service import MeetingsService
from app.services.points_service import PointsService
from app.services.notification_service import NotificationService
from app.core.exceptions import NotFoundError, ConflictError, ValidationError
import logging

logger = logging.getLogger(__name__)


class ShakeService:
    """Service for managing shake sessions and matching."""
    
    # Configuration
    PROXIMITY_THRESHOLD_M = 100.0  # 100 meters
    TIME_WINDOW_SECONDS = 15  # 15 seconds
    SESSION_EXPIRY_SECONDS = 15
    
    def __init__(self, db: Session):
        self.db = db
        self.shake_repo = ShakeRepository(db)
        self.friendship_repo = FriendshipRepository(db)
        self.user_repo = UserRepository(db)
        self.meeting_repo = MeetingRepository(db)
        self.meetings_service = MeetingsService(db)
        self.points_service = PointsService(db)
        self.notification_service = NotificationService(db)
    
    def initiate_shake(
        self,
        user_id: int,
        latitude: str,
        longitude: str,
        accuracy_m: Optional[str] = None
    ) -> Dict:
        """
        Initiate a shake session when user shakes their phone.
        Automatically checks for nearby friends and matches if found.
        
        Returns:
            Dictionary with session info and match result (if any)
        """
        # Validate coordinates
        try:
            lat_float = float(latitude)
            lon_float = float(longitude)
            if not (-90 <= lat_float <= 90) or not (-180 <= lon_float <= 180):
                raise ValidationError("Invalid latitude or longitude values")
        except ValueError:
            raise ValidationError("Latitude and longitude must be valid numbers")
        
        # Check if user already has an active session
        existing_session = self.shake_repo.get_active_session_by_user(user_id)
        if existing_session:
            # Return existing session info
            return self._check_for_matches(existing_session, lat_float, lon_float)
        
        # Create new shake session
        session = self.shake_repo.create_session(
            user_id=user_id,
            latitude=latitude,
            longitude=longitude,
            accuracy_m=accuracy_m,
            expires_in_seconds=self.SESSION_EXPIRY_SECONDS
        )
        
        logger.info(f"Shake session created for user {user_id} at ({latitude}, {longitude})")
        
        # Check for nearby friends who are also shaking
        return self._check_for_matches(session, lat_float, lon_float)
    
    def _check_for_matches(
        self,
        session: 'ShakeSession',
        latitude: float,
        longitude: float
    ) -> Dict:
        """Check for nearby friends shaking and match if found."""
        # Get user's friends
        friends = self.friendship_repo.get_friends(session.user_id, status_filter="accepted")
        friend_ids = [f.id for f in friends]
        
        if not friend_ids:
            return {
                "session_id": session.id,
                "status": "active",
                "matched": False,
                "message": "No nearby friends shaking. Keep shaking!",
                "nearby_friends_count": 0
            }
        
        # Find nearby active shake sessions
        nearby_sessions = self.shake_repo.find_nearby_active_sessions(
            user_id=session.user_id,
            latitude=latitude,
            longitude=longitude,
            max_distance_m=self.PROXIMITY_THRESHOLD_M,
            time_window_seconds=self.TIME_WINDOW_SECONDS
        )
        
        # Filter to only friends
        friend_sessions = [s for s in nearby_sessions if s.user_id in friend_ids]
        
        if not friend_sessions:
            return {
                "session_id": session.id,
                "status": "active",
                "matched": False,
                "message": "No nearby friends shaking. Keep shaking!",
                "nearby_friends_count": 0
            }
        
        # Match with the first friend found (or could match with closest)
        matched_session = friend_sessions[0]
        matched_friend = self.user_repo.get_by_id(matched_session.user_id)
        
        if not matched_friend:
            return {
                "session_id": session.id,
                "status": "active",
                "matched": False,
                "message": "No nearby friends shaking. Keep shaking!",
                "nearby_friends_count": len(friend_sessions)
            }
        
        # Create meeting automatically
        try:
            meeting = self._create_shake_meeting(session, matched_session, matched_friend)
            
            # Match the sessions
            self.shake_repo.match_sessions(session.id, matched_session.id, meeting['id'])
            
            # Award points to both users
            try:
                self.points_service.award_points(
                    user_id=session.user_id,
                    points=PointsService.POINTS_SHAKE_MEETUP,
                    transaction_type="shake_meetup",
                    reference_id=meeting['id'],
                    description=f"Shake MeetUp with {matched_friend.full_name or matched_friend.username}"
                )
                
                self.points_service.award_points(
                    user_id=matched_session.user_id,
                    points=PointsService.POINTS_SHAKE_MEETUP,
                    transaction_type="shake_meetup",
                    reference_id=meeting['id'],
                    description=f"Shake MeetUp with {self.user_repo.get_by_id(session.user_id).full_name or self.user_repo.get_by_id(session.user_id).username}"
                )
            except Exception as e:
                logger.error(f"Failed to award points for shake meetup: {e}")
            
            # Send notifications
            try:
                self.notification_service.send_shake_match_notification(
                    user_id=session.user_id,
                    friend_name=matched_friend.full_name or matched_friend.username,
                    meeting_id=meeting['id']
                )
                self.notification_service.send_shake_match_notification(
                    user_id=matched_session.user_id,
                    friend_name=self.user_repo.get_by_id(session.user_id).full_name or self.user_repo.get_by_id(session.user_id).username,
                    meeting_id=meeting['id']
                )
            except Exception as e:
                logger.error(f"Failed to send shake match notification: {e}")
            
            logger.info(f"Shake match! User {session.user_id} matched with user {matched_session.user_id}")
            
            return {
                "session_id": session.id,
                "status": "matched",
                "matched": True,
                "matched_user_id": matched_session.user_id,
                "matched_user_name": matched_friend.full_name or matched_friend.username,
                "meeting_id": meeting['id'],
                "meeting_title": meeting['title'],
                "points_awarded": PointsService.POINTS_SHAKE_MEETUP,
                "message": f"🎉 Shake Match! Meeting created with {matched_friend.full_name or matched_friend.username}!"
            }
        except Exception as e:
            logger.error(f"Failed to create shake meeting: {e}")
            return {
                "session_id": session.id,
                "status": "active",
                "matched": False,
                "message": "Error creating meeting. Please try again.",
                "error": str(e)
            }
    
    def _create_shake_meeting(
        self,
        session1: 'ShakeSession',
        session2: 'ShakeSession',
        friend: 'User'
    ) -> Dict:
        """Create a meeting for a shake match."""
        # Calculate midpoint location
        lat1 = float(session1.latitude)
        lon1 = float(session1.longitude)
        lat2 = float(session2.latitude)
        lon2 = float(session2.longitude)
        
        midpoint_lat = (lat1 + lat2) / 2
        midpoint_lon = (lon1 + lon2) / 2
        
        # Use consistent organizer: always use the user with lower ID
        # This ensures both users see the same organizer
        organizer_id = min(session1.user_id, session2.user_id)
        participant_id = max(session1.user_id, session2.user_id)
        
        # Get friend name for title (the other user, not the organizer)
        if organizer_id == session1.user_id:
            friend_name = friend.full_name or friend.username
        else:
            # Get the other user's name
            other_user = self.user_repo.get_by_id(session1.user_id)
            friend_name = (other_user.full_name if other_user and other_user.full_name else other_user.username) if other_user else "Friend"
        
        # Try to get address via reverse geocoding (fallback to coordinates)
        address = f"Near {midpoint_lat:.6f}, {midpoint_lon:.6f}"
        try:
            import requests
            # Use a free reverse geocoding service (OpenStreetMap Nominatim)
            # Note: This is a simple implementation, you might want to use a proper geocoding service
            geocode_url = f"https://nominatim.openstreetmap.org/reverse?format=json&lat={midpoint_lat}&lon={midpoint_lon}&zoom=18&addressdetails=1"
            response = requests.get(geocode_url, headers={'User-Agent': 'MeetUpApp/1.0'}, timeout=2)
            if response.status_code == 200:
                data = response.json()
                if 'address' in data:
                    addr = data['address']
                    parts = []
                    if 'road' in addr:
                        parts.append(addr['road'])
                    if 'house_number' in addr:
                        parts.insert(0, addr['house_number'])
                    if 'city' in addr or 'town' in addr or 'village' in addr:
                        city = addr.get('city') or addr.get('town') or addr.get('village')
                        if city:
                            parts.append(city)
                    if parts:
                        address = ', '.join(parts)
        except Exception as e:
            logger.warning(f"Failed to geocode address: {e}, using coordinates")
        
        # Create meeting
        from app.schemas.meeting import MeetingCreate
        
        # Schedule meeting 1 minute in the future to pass validation
        # (MeetingsService requires scheduled_at to be in the future)
        scheduled_time = datetime.utcnow() + timedelta(minutes=1)
        
        meeting_data = MeetingCreate(
            title=f"Shake MeetUp with {friend_name}",
            description="Created via Shake to MeetUp! 🎉",
            address=address,
            latitude=str(midpoint_lat),
            longitude=str(midpoint_lon),
            scheduled_at=scheduled_time,
            participant_ids=[participant_id]
        )
        
        meeting = self.meetings_service.create_meeting(organizer_id, meeting_data)
        
        # Update meeting status to confirmed (since both agreed)
        # Note: We might want to add a method to update status directly
        # For now, the meeting will be created as "pending" but both users are already participants
        
        return meeting
    
    def get_nearby_shaking_friends(
        self,
        user_id: int,
        latitude: float,
        longitude: float
    ) -> List[Dict]:
        """Get list of nearby friends who are currently shaking."""
        # Get user's friends
        friends = self.friendship_repo.get_friends(user_id, status_filter="accepted")
        friend_ids = [f.id for f in friends]
        
        if not friend_ids:
            return []
        
        # Find nearby active sessions
        nearby_sessions = self.shake_repo.find_nearby_active_sessions(
            user_id=user_id,
            latitude=latitude,
            longitude=longitude,
            max_distance_m=self.PROXIMITY_THRESHOLD_M,
            time_window_seconds=self.TIME_WINDOW_SECONDS
        )
        
        # Filter to friends and get user info
        result = []
        for session in nearby_sessions:
            if session.user_id in friend_ids:
                friend = self.user_repo.get_by_id(session.user_id)
                if friend:
                    try:
                        session_lat = float(session.latitude)
                        session_lon = float(session.longitude)
                        distance = self.shake_repo._haversine_distance(
                            latitude, longitude, session_lat, session_lon
                        )
                        
                        result.append({
                            "user_id": friend.id,
                            "username": friend.username,
                            "full_name": friend.full_name,
                            "distance_m": round(distance, 1),
                            "shake_session_id": session.id,
                            "created_at": session.created_at.isoformat()
                        })
                    except (ValueError, TypeError):
                        continue
        
        return result
    
    def get_active_session(self, user_id: int) -> Optional[Dict]:
        """Get user's active shake session."""
        session = self.shake_repo.get_active_session_by_user(user_id)
        if not session:
            return None
        
        return {
            "session_id": session.id,
            "latitude": session.latitude,
            "longitude": session.longitude,
            "created_at": session.created_at.isoformat(),
            "expires_at": session.expires_at.isoformat(),
            "status": session.status.value
        }

