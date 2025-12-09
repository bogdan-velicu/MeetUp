"""Pydantic schemas for notifications."""
from pydantic import BaseModel, Field


class FCMTokenRegister(BaseModel):
    """Schema for registering/updating FCM token."""
    fcm_token: str = Field(..., description="Firebase Cloud Messaging token")


class FCMTokenResponse(BaseModel):
    """Response schema for FCM token registration."""
    success: bool
    message: str

