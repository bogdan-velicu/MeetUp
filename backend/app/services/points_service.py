"""Points Engine Service - Handles all points-related operations."""
from sqlalchemy.orm import Session
from typing import Dict, List, Optional
from app.repositories.points_repository import PointsRepository
from app.repositories.user_repository import UserRepository
from app.repositories.meeting_repository import MeetingRepository
from app.core.exceptions import NotFoundError, ConflictError
import logging

logger = logging.getLogger(__name__)


class PointsService:
    """Service for managing points transactions and calculations."""
    
    # Points values for different actions
    POINTS_MEETING_CONFIRMED = 50
    POINTS_MEETING_ATTENDED = 25
    POINTS_SHAKE_MEETUP = 50
    POINTS_SHAKE_MEETUP_BONUS = 25
    
    def __init__(self, db: Session):
        self.db = db
        self.points_repo = PointsRepository(db)
        self.user_repo = UserRepository(db)
        self.meeting_repo = MeetingRepository(db)
    
    def award_points(
        self,
        user_id: int,
        points: int,
        transaction_type: str,
        reference_id: Optional[int] = None,
        description: Optional[str] = None
    ) -> Dict:
        """
        Award points to a user.
        
        Args:
            user_id: User to award points to
            points: Number of points to award (positive)
            transaction_type: Type of transaction (e.g., 'meeting_confirmed')
            reference_id: Optional reference ID (e.g., meeting_id)
            description: Optional description
            
        Returns:
            Dictionary with transaction details and new total
        """
        if points <= 0:
            raise ValueError("Points must be positive")
        
        # Verify user exists
        user = self.user_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError(f"User {user_id} not found")
        
        # Create transaction
        transaction = self.points_repo.create_transaction(
            user_id=user_id,
            points=points,
            transaction_type=transaction_type,
            reference_id=reference_id,
            description=description
        )
        
        # Get updated total
        total_points = self.points_repo.get_user_total_points(user_id)
        
        logger.info(f"Awarded {points} points to user {user_id} for {transaction_type}. New total: {total_points}")
        
        return {
            "transaction_id": transaction.id,
            "points": points,
            "transaction_type": transaction_type,
            "total_points": total_points,
            "description": description
        }
    
    def deduct_points(
        self,
        user_id: int,
        points: int,
        transaction_type: str,
        reference_id: Optional[int] = None,
        description: Optional[str] = None
    ) -> Dict:
        """
        Deduct points from a user (for purchases, etc.).
        
        Args:
            user_id: User to deduct points from
            points: Number of points to deduct (positive, will be negated)
            transaction_type: Type of transaction (e.g., 'store_purchase')
            reference_id: Optional reference ID (e.g., store_item_id)
            description: Optional description
            
        Returns:
            Dictionary with transaction details and new total
        """
        if points <= 0:
            raise ValueError("Points must be positive")
        
        # Verify user exists and has enough points
        user = self.user_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError(f"User {user_id} not found")
        
        current_points = self.points_repo.get_user_total_points(user_id)
        if current_points < points:
            raise ConflictError(f"Insufficient points. Current: {current_points}, Required: {points}")
        
        # Create transaction with negative points
        transaction = self.points_repo.create_transaction(
            user_id=user_id,
            points=-points,  # Negative for deduction
            transaction_type=transaction_type,
            reference_id=reference_id,
            description=description
        )
        
        # Get updated total
        total_points = self.points_repo.get_user_total_points(user_id)
        
        logger.info(f"Deducted {points} points from user {user_id} for {transaction_type}. New total: {total_points}")
        
        return {
            "transaction_id": transaction.id,
            "points": -points,
            "transaction_type": transaction_type,
            "total_points": total_points,
            "description": description
        }
    
    def award_meeting_confirmation_points(self, user_id: int, meeting_id: int) -> Dict:
        """
        Award points for confirming a meeting.
        
        Args:
            user_id: User confirming the meeting
            meeting_id: Meeting ID
            
        Returns:
            Dictionary with transaction details
        """
        # Check if user has already received points for this meeting
        if self.points_repo.has_user_received_points_for_meeting(user_id, meeting_id):
            raise ConflictError("Points already awarded for this meeting")
        
        # Verify meeting exists and user is a participant
        meeting = self.meeting_repo.get_meeting_by_id(meeting_id)
        if not meeting:
            raise NotFoundError(f"Meeting {meeting_id} not found")
        
        # Check if user is a participant
        participants = self.meeting_repo.get_participants_by_meeting(meeting_id)
        participant_ids = [p.user_id for p in participants]
        if user_id not in participant_ids and user_id != meeting.organizer_id:
            raise ConflictError("User is not a participant in this meeting")
        
        # Award points
        return self.award_points(
            user_id=user_id,
            points=self.POINTS_MEETING_CONFIRMED,
            transaction_type="meeting_confirmed",
            reference_id=meeting_id,
            description=f"Meeting confirmed: {meeting.title or 'Untitled Meeting'}"
        )
    
    def get_user_points_summary(self, user_id: int) -> Dict:
        """
        Get user's points summary.
        
        Returns:
            Dictionary with total points and breakdown
        """
        user = self.user_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError(f"User {user_id} not found")
        
        total_points = self.points_repo.get_user_total_points(user_id)
        
        # Get transaction counts by type
        transactions = self.points_repo.get_user_transactions(user_id, limit=1000)
        
        breakdown = {}
        for transaction in transactions:
            if transaction.points > 0:  # Only count positive transactions
                transaction_type = transaction.transaction_type
                if transaction_type not in breakdown:
                    breakdown[transaction_type] = {
                        "count": 0,
                        "total_points": 0
                    }
                breakdown[transaction_type]["count"] += 1
                breakdown[transaction_type]["total_points"] += transaction.points
        
        return {
            "user_id": user_id,
            "total_points": total_points,
            "breakdown": breakdown
        }
    
    def get_user_points_history(
        self,
        user_id: int,
        limit: int = 50,
        offset: int = 0,
        transaction_type: Optional[str] = None
    ) -> Dict:
        """
        Get user's points transaction history.
        
        Returns:
            Dictionary with transactions list and pagination info
        """
        user = self.user_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError(f"User {user_id} not found")
        
        transactions = self.points_repo.get_user_transactions(
            user_id=user_id,
            limit=limit,
            offset=offset,
            transaction_type=transaction_type
        )
        
        return {
            "user_id": user_id,
            "transactions": [
                {
                    "id": t.id,
                    "points": t.points,
                    "transaction_type": t.transaction_type,
                    "reference_id": t.reference_id,
                    "description": t.description,
                    "created_at": t.created_at.isoformat()
                }
                for t in transactions
            ],
            "limit": limit,
            "offset": offset
        }

