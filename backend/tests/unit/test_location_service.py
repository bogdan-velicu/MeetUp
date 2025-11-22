"""
Unit tests for LocationService.
"""
import pytest
from datetime import datetime
from app.services.location_service import LocationService
from app.core.exceptions import ValidationError


@pytest.mark.unit
class TestLocationService:
    """Test location service."""
    
    def test_update_location(self, db_session, test_user):
        """Test updating user location."""
        location_service = LocationService(db_session)
        
        location = location_service.update_location(
            user_id=test_user.id,
            latitude="45.123456",
            longitude="25.654321",
            accuracy_m="10.5"
        )
        
        assert location is not None
        assert location["user_id"] == test_user.id
        assert location["latitude"] == "45.123456"
        assert location["longitude"] == "25.654321"
        assert location["accuracy_m"] == "10.5"
    
    def test_update_location_invalid_latitude(self, db_session, test_user):
        """Test that invalid latitude is rejected."""
        location_service = LocationService(db_session)
        
        with pytest.raises(ValidationError, match="Invalid latitude"):
            location_service.update_location(
                user_id=test_user.id,
                latitude="100.0",  # Invalid (> 90)
                longitude="25.654321"
            )
    
    def test_update_location_invalid_longitude(self, db_session, test_user):
        """Test that invalid longitude is rejected."""
        location_service = LocationService(db_session)
        
        with pytest.raises(ValidationError, match="Invalid latitude"):
            location_service.update_location(
                user_id=test_user.id,
                latitude="45.123456",
                longitude="200.0"  # Invalid (> 180)
            )
    
    def test_update_location_non_numeric(self, db_session, test_user):
        """Test that non-numeric coordinates are rejected."""
        location_service = LocationService(db_session)
        
        with pytest.raises(ValidationError, match="must be valid numbers"):
            location_service.update_location(
                user_id=test_user.id,
                latitude="not_a_number",
                longitude="25.654321"
            )
    
    def test_get_friends_locations_empty(self, db_session, test_user):
        """Test getting friends locations when user has no friends."""
        location_service = LocationService(db_session)
        
        locations = location_service.get_friends_locations(test_user.id)
        
        assert locations == []
    
    def test_get_friends_locations(self, db_session, test_user, test_user2, test_friendship):
        """Test getting friends locations."""
        location_service = LocationService(db_session)
        
        # Update friend's location
        location_service.update_location(
            user_id=test_user2.id,
            latitude="45.123456",
            longitude="25.654321"
        )
        
        # Enable location sharing for friend
        test_user2.location_sharing_enabled = True
        db_session.commit()
        
        locations = location_service.get_friends_locations(test_user.id)
        
        assert len(locations) == 1
        assert locations[0]["user_id"] == test_user2.id
        assert locations[0]["latitude"] == "45.123456"
    
    def test_get_friends_locations_sharing_disabled(self, db_session, test_user, test_user2, test_friendship):
        """Test that friends with location sharing disabled are not returned."""
        location_service = LocationService(db_session)
        
        # Update friend's location
        location_service.update_location(
            user_id=test_user2.id,
            latitude="45.123456",
            longitude="25.654321"
        )
        
        # Location sharing is disabled by default
        locations = location_service.get_friends_locations(test_user.id)
        
        assert len(locations) == 0
    
    def test_add_location_history(self, db_session, test_user):
        """Test adding location history."""
        location_service = LocationService(db_session)
        
        history = location_service.add_location_history(
            user_id=test_user.id,
            latitude="45.123456",
            longitude="25.654321",
            recorded_at=datetime.utcnow(),
            accuracy_m="10.5",
            source="gps"
        )
        
        assert history is not None
        assert history["user_id"] == test_user.id
        assert history["latitude"] == "45.123456"
    
    def test_get_location_history(self, db_session, test_user):
        """Test getting location history."""
        location_service = LocationService(db_session)
        
        # Add some history records
        now = datetime.utcnow()
        location_service.add_location_history(
            user_id=test_user.id,
            latitude="45.1",
            longitude="25.1",
            recorded_at=now
        )
        location_service.add_location_history(
            user_id=test_user.id,
            latitude="45.2",
            longitude="25.2",
            recorded_at=now
        )
        
        history = location_service.get_location_history(test_user.id)
        
        assert len(history) == 2
        assert history[0]["latitude"] == "45.2"  # Most recent first

