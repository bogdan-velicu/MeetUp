from sqlalchemy.orm import Session
from sqlalchemy import desc
from app.models.points import PointsTransaction
from app.models.user import User
from typing import Optional, List
from datetime import datetime

class PointsRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def create_transaction(
        self,
        user_id: int,
        points: int,
        transaction_type: str,
        reference_id: Optional[int] = None,
        description: Optional[str] = None
    ) -> PointsTransaction:
        """Create a new points transaction."""
        transaction = PointsTransaction(
            user_id=user_id,
            points=points,
            transaction_type=transaction_type,
            reference_id=reference_id,
            description=description
        )
        self.db.add(transaction)
        
        # Update user's total points
        user = self.db.query(User).filter(User.id == user_id).first()
        if user:
            user.total_points += points
            if user.total_points < 0:
                user.total_points = 0  # Prevent negative points
        
        self.db.commit()
        self.db.refresh(transaction)
        return transaction
    
    def get_user_transactions(
        self,
        user_id: int,
        limit: int = 50,
        offset: int = 0,
        transaction_type: Optional[str] = None
    ) -> List[PointsTransaction]:
        """Get user's points transactions."""
        query = self.db.query(PointsTransaction).filter(
            PointsTransaction.user_id == user_id
        )
        
        if transaction_type:
            query = query.filter(PointsTransaction.transaction_type == transaction_type)
        
        return query.order_by(desc(PointsTransaction.created_at)).offset(offset).limit(limit).all()
    
    def get_user_total_points(self, user_id: int) -> int:
        """Get user's total points."""
        user = self.db.query(User).filter(User.id == user_id).first()
        return user.total_points if user else 0
    
    def get_transaction_by_id(self, transaction_id: int) -> Optional[PointsTransaction]:
        """Get transaction by ID."""
        return self.db.query(PointsTransaction).filter(
            PointsTransaction.id == transaction_id
        ).first()
    
    def get_transactions_by_reference(
        self,
        reference_id: int,
        transaction_type: Optional[str] = None
    ) -> List[PointsTransaction]:
        """Get transactions by reference ID (e.g., meeting_id)."""
        query = self.db.query(PointsTransaction).filter(
            PointsTransaction.reference_id == reference_id
        )
        
        if transaction_type:
            query = query.filter(PointsTransaction.transaction_type == transaction_type)
        
        return query.all()
    
    def has_user_received_points_for_meeting(self, user_id: int, meeting_id: int) -> bool:
        """Check if user has already received points for a specific meeting."""
        transaction = self.db.query(PointsTransaction).filter(
            PointsTransaction.user_id == user_id,
            PointsTransaction.reference_id == meeting_id,
            PointsTransaction.transaction_type.in_(['meeting_confirmed', 'meeting_attended'])
        ).first()
        return transaction is not None

