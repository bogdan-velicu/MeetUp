"""Firebase Admin SDK initialization."""
import firebase_admin
from firebase_admin import credentials
import os
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

_firebase_app = None


def initialize_firebase():
    """Initialize Firebase Admin SDK."""
    global _firebase_app
    
    if _firebase_app is not None:
        logger.info("Firebase Admin already initialized")
        return _firebase_app
    
    try:
        # Check if credentials path is provided
        creds_path = settings.FIREBASE_CREDENTIALS_PATH
        
        if not creds_path or creds_path == "":
            logger.warning("FIREBASE_CREDENTIALS_PATH not set. FCM notifications will not work.")
            return None
        
        # Resolve path - handle both relative and absolute paths
        # If relative, it's relative to the backend directory (where the server runs)
        if not os.path.isabs(creds_path):
            # Get the backend directory (parent of app directory)
            backend_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            creds_path = os.path.join(backend_dir, creds_path)
        
        # Check if file exists
        if not os.path.exists(creds_path):
            logger.warning(f"Firebase credentials file not found at {creds_path}. FCM notifications will not work.")
            logger.warning(f"Current working directory: {os.getcwd()}")
            return None
        
        # Initialize with service account credentials
        cred = credentials.Certificate(creds_path)
        _firebase_app = firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK initialized successfully")
        return _firebase_app
    
    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
        logger.warning("FCM notifications will not work.")
        return None


def get_firebase_app():
    """Get the initialized Firebase app instance."""
    if _firebase_app is None:
        return initialize_firebase()
    return _firebase_app

