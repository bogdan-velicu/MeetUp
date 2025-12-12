from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from typing import Optional
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.points_service import PointsService
from app.schemas.points import (
    PointsSummaryResponse,
    PointsHistoryResponse,
    PointsAwardResponse
)

router = APIRouter(prefix="/points", tags=["points"])


@router.get("/summary", response_model=PointsSummaryResponse)
async def get_points_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's points summary (total points and breakdown)."""
    service = PointsService(db)
    summary = service.get_user_points_summary(current_user.id)
    return summary


@router.get("/history", response_model=PointsHistoryResponse)
async def get_points_history(
    limit: int = Query(50, ge=1, le=100, description="Number of transactions to return"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    transaction_type: Optional[str] = Query(None, description="Filter by transaction type"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's points transaction history."""
    service = PointsService(db)
    history = service.get_user_points_history(
        user_id=current_user.id,
        limit=limit,
        offset=offset,
        transaction_type=transaction_type
    )
    return history


@router.post("/meetings/{meeting_id}/confirm", response_model=PointsAwardResponse, status_code=status.HTTP_200_OK)
async def confirm_meeting(
    meeting_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Confirm a meeting and award points.
    Only participants can confirm meetings.
    """
    points_service = PointsService(db)
    result = points_service.award_meeting_confirmation_points(
        user_id=current_user.id,
        meeting_id=meeting_id
    )
    return result

