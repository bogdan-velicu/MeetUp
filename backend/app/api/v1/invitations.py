from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.invitations_service import InvitationsService
from app.schemas.invitation import InvitationResponse

router = APIRouter(prefix="/invitations", tags=["invitations"])


@router.get("", response_model=List[InvitationResponse])
async def get_invitations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all pending invitations for the current user."""
    service = InvitationsService(db)
    invitations = service.get_invitations(current_user.id)
    return invitations


@router.get("/{invitation_id}", response_model=InvitationResponse)
async def get_invitation(
    invitation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get invitation details by ID (meeting_id)."""
    service = InvitationsService(db)
    invitation = service.get_invitation_by_id(invitation_id, current_user.id)
    return invitation


@router.patch("/{invitation_id}/accept", response_model=InvitationResponse)
async def accept_invitation(
    invitation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Accept an invitation."""
    service = InvitationsService(db)
    invitation = service.accept_invitation(invitation_id, current_user.id)
    return invitation


@router.patch("/{invitation_id}/decline", response_model=InvitationResponse)
async def decline_invitation(
    invitation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Decline an invitation."""
    service = InvitationsService(db)
    invitation = service.decline_invitation(invitation_id, current_user.id)
    return invitation

