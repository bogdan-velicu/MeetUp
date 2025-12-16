# Import all models here for Alembic to detect them
from .user import User, UserLocation, AvailabilitySchedule
from .user_location_history import UserLocationHistory
from .role import Role, UserRole
from .friendship import Friendship
from .meeting import Meeting, MeetingParticipant
from .group import Group, GroupMember
from .points import PointsTransaction, StoreItem, UserPurchase
from .mission import Mission, UserMission
from .event import Event, EventParticipant
from .location import Location, LocationReview, LocationCampaign
from .shake_session import ShakeSession, ShakeSessionStatus
from .chat import Conversation, Message

__all__ = [
    "User",
    "UserLocation",
    "UserLocationHistory",
    "AvailabilitySchedule",
    "Role",
    "UserRole",
    "Friendship",
    "Meeting",
    "MeetingParticipant",
    "Group",
    "GroupMember",
    "PointsTransaction",
    "StoreItem",
    "UserPurchase",
    "Mission",
    "UserMission",
    "Event",
    "EventParticipant",
    "Location",
    "LocationReview",
    "LocationCampaign",
    "ShakeSession",
    "ShakeSessionStatus",
    "Conversation",
    "Message",
]

