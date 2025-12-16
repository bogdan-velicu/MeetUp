from sqlalchemy.orm import Session
from typing import Optional, List
from app.repositories.user_repository import UserRepository
from app.services.fcm_client import FCMClient
import logging

logger = logging.getLogger(__name__)


class NotificationService:
    """Service for sending notifications via FCM."""
    
    def __init__(self, db: Session):
        self.user_repo = UserRepository(db)
        self.fcm_client = FCMClient()
        self.db = db
    
    def send_invitation_notification(self, user_id: int, meeting_id: int, organizer_name: str, meeting_title: Optional[str] = None):
        """Send notification when a user receives a meeting invitation.
        
        Args:
            user_id: ID of the user receiving the invitation
            meeting_id: ID of the meeting
            organizer_name: Name of the meeting organizer
            meeting_title: Optional title of the meeting
        """
        # Check notification preferences
        prefs = self.get_user_notification_preferences(user_id)
        if not prefs.get("meeting_invitations", True) or not prefs.get("push_enabled", True):
            logger.info(f"User {user_id} has disabled meeting invitation notifications")
            return
        
        # Get user's FCM token
        user = self.user_repo.get_by_id(user_id)
        if not user or not user.fcm_token:
            logger.warning(f"User {user_id} does not have an FCM token registered")
            return
        
        # Prepare notification
        title = meeting_title or "New Meeting Invitation"
        body = f"{organizer_name} invited you to a meeting"
        if meeting_title:
            body = f"{organizer_name} invited you to '{meeting_title}'"
        
        data = {
            "type": "meeting_invitation",
            "meeting_id": str(meeting_id),
            "action": "view_invitation"
        }
        
        # Send notification
        success = self.fcm_client.send_notification(
            fcm_token=user.fcm_token,
            title=title,
            body=body,
            data=data
        )
        
        if success:
            logger.info(f"Sent invitation notification to user {user_id} for meeting {meeting_id}")
        else:
            logger.warning(f"Failed to send invitation notification to user {user_id}")
    
    def send_invitation_response_notification(self, organizer_id: int, participant_name: str, meeting_id: int, 
                                             accepted: bool, meeting_title: Optional[str] = None):
        """Send notification to organizer when a participant accepts/declines an invitation.
        
        Args:
            organizer_id: ID of the meeting organizer
            participant_name: Name of the participant who responded
            meeting_id: ID of the meeting
            accepted: True if accepted, False if declined
            meeting_title: Optional title of the meeting
        """
        # Check notification preferences
        prefs = self.get_user_notification_preferences(organizer_id)
        if not prefs.get("invitation_responses", True) or not prefs.get("push_enabled", True):
            logger.info(f"User {organizer_id} has disabled invitation response notifications")
            return
        
        # Get organizer's FCM token
        organizer = self.user_repo.get_by_id(organizer_id)
        if not organizer or not organizer.fcm_token:
            logger.warning(f"Organizer {organizer_id} does not have an FCM token registered")
            return
        
        # Prepare notification
        action = "accepted" if accepted else "declined"
        title = "Meeting Invitation Response"
        body = f"{participant_name} {action} your invitation"
        if meeting_title:
            body = f"{participant_name} {action} your invitation to '{meeting_title}'"
        
        data = {
            "type": "invitation_response",
            "meeting_id": str(meeting_id),
            "action": "view_meeting",
            "response": "accepted" if accepted else "declined"
        }
        
        # Send notification
        success = self.fcm_client.send_notification(
            fcm_token=organizer.fcm_token,
            title=title,
            body=body,
            data=data
        )
        
        if success:
            logger.info(f"Sent invitation response notification to organizer {organizer_id} for meeting {meeting_id}")
        else:
            logger.warning(f"Failed to send invitation response notification to organizer {organizer_id}")
    
    def send_meeting_update_notification(self, user_id: int, meeting_id: int, update_type: str, meeting_title: Optional[str] = None):
        """Send notification when a meeting is updated (time, location, etc.).
        
        Args:
            user_id: ID of the user to notify
            meeting_id: ID of the meeting
            update_type: Type of update (e.g., "time_changed", "location_changed", "cancelled")
            meeting_title: Optional title of the meeting
        """
        # Check notification preferences
        prefs = self.get_user_notification_preferences(user_id)
        if not prefs.get("meeting_updates", True) or not prefs.get("push_enabled", True):
            logger.info(f"User {user_id} has disabled meeting update notifications")
            return
        
        # Get user's FCM token
        user = self.user_repo.get_by_id(user_id)
        if not user or not user.fcm_token:
            logger.warning(f"User {user_id} does not have an FCM token registered")
            return
        
        # Prepare notification based on update type
        title = meeting_title or "Meeting Update"
        body_map = {
            "time_changed": "The meeting time has been changed",
            "location_changed": "The meeting location has been changed",
            "cancelled": "The meeting has been cancelled",
            "updated": "The meeting has been updated"
        }
        body = body_map.get(update_type, "The meeting has been updated")
        if meeting_title:
            body = f"{body}: {meeting_title}"
        
        data = {
            "type": "meeting_update",
            "meeting_id": str(meeting_id),
            "update_type": update_type,
            "action": "view_meeting"
        }
        
        # Send notification
        success = self.fcm_client.send_notification(
            fcm_token=user.fcm_token,
            title=title,
            body=body,
            data=data
        )
        
        if success:
            logger.info(f"Sent meeting update notification to user {user_id} for meeting {meeting_id}")
        else:
            logger.warning(f"Failed to send meeting update notification to user {user_id}")
    
    def send_meeting_update_to_participants(self, participant_ids: List[int], meeting_id: int, 
                                           update_type: str, meeting_title: Optional[str] = None):
        """Send meeting update notification to multiple participants.
        
        Args:
            participant_ids: List of user IDs to notify
            meeting_id: ID of the meeting
            update_type: Type of update
            meeting_title: Optional title of the meeting
        """
        # Get FCM tokens for all participants
        fcm_tokens = []
        for user_id in participant_ids:
            user = self.user_repo.get_by_id(user_id)
            if user and user.fcm_token:
                # Check preferences
                prefs = self.get_user_notification_preferences(user_id)
                if prefs.get("meeting_updates", True) and prefs.get("push_enabled", True):
                    fcm_tokens.append(user.fcm_token)
        
        if not fcm_tokens:
            logger.info(f"No FCM tokens available for meeting update notification")
            return
        
        # Prepare notification
        title = meeting_title or "Meeting Update"
        body_map = {
            "time_changed": "The meeting time has been changed",
            "location_changed": "The meeting location has been changed",
            "cancelled": "The meeting has been cancelled",
            "updated": "The meeting has been updated"
        }
        body = body_map.get(update_type, "The meeting has been updated")
        if meeting_title:
            body = f"{body}: {meeting_title}"
        
        data = {
            "type": "meeting_update",
            "meeting_id": str(meeting_id),
            "update_type": update_type,
            "action": "view_meeting"
        }
        
        # Send multicast notification
        result = self.fcm_client.send_multicast_notification(
            fcm_tokens=fcm_tokens,
            title=title,
            body=body,
            data=data
        )
        
        logger.info(f"Sent meeting update to {result['success_count']} participants, {result['failure_count']} failed")
    
    def send_shake_match_notification(self, user_id: int, friend_name: str, meeting_id: int):
        """Send notification when a shake match is found.
        
        Args:
            user_id: ID of the user receiving the notification
            friend_name: Name of the friend they matched with
            meeting_id: ID of the created meeting
        """
        # Check notification preferences
        prefs = self.get_user_notification_preferences(user_id)
        if not prefs.get("meeting_invitations", True) or not prefs.get("push_enabled", True):
            logger.info(f"User {user_id} has disabled shake match notifications")
            return
        
        # Get user's FCM token
        user = self.user_repo.get_by_id(user_id)
        if not user or not user.fcm_token:
            logger.warning(f"User {user_id} does not have an FCM token registered")
            return
        
        # Prepare notification
        title = "🎉 Shake Match!"
        body = f"You matched with {friend_name}! Meeting created."
        
        data = {
            "type": "shake_match",
            "meeting_id": str(meeting_id)
        }
        
        success = self.fcm_client.send_notification(
            fcm_token=user.fcm_token,
            title=title,
            body=body,
            data=data
        )
        
        if success:
            logger.info(f"Sent shake match notification to user {user_id}")
        else:
            logger.warning(f"Failed to send shake match notification to user {user_id}")
    
    def get_user_notification_preferences(self, user_id: int) -> dict:
        """Get user's notification preferences.
        
        Returns:
            Dictionary with notification preference settings
        """
        # TODO: Implement notification preferences storage
        # For now, return default preferences
        return {
            "meeting_invitations": True,
            "meeting_updates": True,
            "invitation_responses": True,
            "friend_requests": True,
            "push_enabled": True
        }
    
    def update_user_notification_preferences(self, user_id: int, preferences: dict) -> dict:
        """Update user's notification preferences.
        
        Args:
            user_id: ID of the user
            preferences: Dictionary with preference settings to update
        
        Returns:
            Updated preferences
        """
        # TODO: Implement notification preferences storage
        current_prefs = self.get_user_notification_preferences(user_id)
        current_prefs.update(preferences)
        return current_prefs
    
    def send_friend_request_notification(self, recipient_id: int, sender_name: str):
        """Send notification when a user receives a friend request.
        
        Args:
            recipient_id: ID of the user receiving the friend request
            sender_name: Name of the user who sent the request
        """
        # Check notification preferences
        prefs = self.get_user_notification_preferences(recipient_id)
        if not prefs.get("friend_requests", True) or not prefs.get("push_enabled", True):
            logger.info(f"User {recipient_id} has disabled friend request notifications")
            return
        
        # Get recipient's FCM token
        user = self.user_repo.get_by_id(recipient_id)
        if not user or not user.fcm_token:
            logger.warning(f"User {recipient_id} does not have an FCM token registered")
            return
        
        # Prepare notification
        title = "New Friend Request"
        body = f"{sender_name} sent you a friend request"
        
        data = {
            "type": "friend_request",
            "action": "view_friend_requests"
        }
        
        # Send notification
        success = self.fcm_client.send_notification(
            fcm_token=user.fcm_token,
            title=title,
            body=body,
            data=data
        )
        
        if success:
            logger.info(f"Sent friend request notification to user {recipient_id}")
        else:
            logger.warning(f"Failed to send friend request notification to user {recipient_id}")
    
    def send_friend_request_accepted_notification(self, sender_id: int, acceptor_name: str):
        """Send notification when a friend request is accepted.
        
        Args:
            sender_id: ID of the user who originally sent the friend request
            acceptor_name: Name of the user who accepted the request
        """
        # Check notification preferences
        prefs = self.get_user_notification_preferences(sender_id)
        if not prefs.get("friend_requests", True) or not prefs.get("push_enabled", True):
            logger.info(f"User {sender_id} has disabled friend request notifications")
            return
        
        # Get sender's FCM token
        user = self.user_repo.get_by_id(sender_id)
        if not user or not user.fcm_token:
            logger.warning(f"User {sender_id} does not have an FCM token registered")
            return
        
        # Prepare notification
        title = "Friend Request Accepted"
        body = f"{acceptor_name} accepted your friend request"
        
        data = {
            "type": "friend_request_accepted",
            "action": "view_friends"
        }
        
        # Send notification
        success = self.fcm_client.send_notification(
            fcm_token=user.fcm_token,
            title=title,
            body=body,
            data=data
        )
        
        if success:
            logger.info(f"Sent friend request accepted notification to user {sender_id}")
        else:
            logger.warning(f"Failed to send friend request accepted notification to user {sender_id}")

