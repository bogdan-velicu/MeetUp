import logging
import sys
from logging.handlers import RotatingFileHandler

def setup_logging():
    """Configure logging for the application."""
    # Create logger
    logger = logging.getLogger("meetup")
    logger.setLevel(logging.INFO)
    
    # Create formatters
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # File handler (optional - for production)
    # file_handler = RotatingFileHandler('meetup.log', maxBytes=10485760, backupCount=5)
    # file_handler.setLevel(logging.INFO)
    # file_handler.setFormatter(formatter)
    # logger.addHandler(file_handler)
    
    return logger

