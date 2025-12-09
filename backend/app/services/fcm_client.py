"""FCM (Firebase Cloud Messaging) client for sending push notifications."""
from firebase_admin import messaging
from typing import Optional, Dict, Any
import logging
from app.core.firebase_admin import get_firebase_app

logger = logging.getLogger(__name__)


class FCMClient:
    """Client for sending FCM push notifications."""
    
    @staticmethod
    def send_notification(
        fcm_token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Send a push notification to a specific device.
        
        Args:
            fcm_token: The FCM token of the target device
            title: Notification title
            body: Notification body text
            data: Optional dictionary of custom data to include
            
        Returns:
            True if notification was sent successfully, False otherwise
        """
        try:
            app = get_firebase_app()
            if app is None:
                logger.warning("Firebase not initialized, cannot send notification")
                return False
            
            # Build the message
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                token=fcm_token,
            )
            
            # Send the message
            response = messaging.send(message)
            logger.info(f"Successfully sent notification. Message ID: {response}")
            return True
            
        except messaging.UnregisteredError:
            logger.warning(f"FCM token is unregistered (device may have uninstalled app): {fcm_token[:20]}...")
            return False
        except messaging.InvalidArgumentError as e:
            logger.error(f"Invalid FCM token or message: {e}")
            return False
        except Exception as e:
            logger.error(f"Failed to send FCM notification: {e}")
            return False
    
    @staticmethod
    def send_multicast_notification(
        fcm_tokens: list[str],
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Send a push notification to multiple devices.
        
        Args:
            fcm_tokens: List of FCM tokens
            title: Notification title
            body: Notification body text
            data: Optional dictionary of custom data to include
            
        Returns:
            Dictionary with 'success_count' and 'failure_count'
        """
        if not fcm_tokens:
            return {"success_count": 0, "failure_count": 0}
        
        try:
            app = get_firebase_app()
            if app is None:
                logger.warning("Firebase not initialized, cannot send notifications")
                return {"success_count": 0, "failure_count": len(fcm_tokens)}
            
            # Build the message
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                tokens=fcm_tokens,
            )
            
            # Send the message
            response = messaging.send_multicast(message)
            logger.info(f"Sent multicast notification. Success: {response.success_count}, Failure: {response.failure_count}")
            
            # Handle failures (remove invalid tokens)
            if response.failure_count > 0:
                for idx, response_item in enumerate(response.responses):
                    if not response_item.success:
                        error = response_item.exception
                        if isinstance(error, messaging.UnregisteredError):
                            logger.warning(f"Token {fcm_tokens[idx][:20]}... is unregistered")
                        else:
                            logger.warning(f"Failed to send to token {fcm_tokens[idx][:20]}...: {error}")
            
            return {
                "success_count": response.success_count,
                "failure_count": response.failure_count
            }
            
        except Exception as e:
            logger.error(f"Failed to send multicast FCM notification: {e}")
            return {"success_count": 0, "failure_count": len(fcm_tokens)}

