"""Pydantic schemas for chat API."""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class MessageCreate(BaseModel):
    """Schema for creating a message."""
    friend_id: int = Field(..., description="ID of the friend to send message to")
    content: str = Field(..., min_length=1, max_length=10000, description="Message content")
    message_type: str = Field(default="text", description="Type of message: text, image, location")


class UserInfo(BaseModel):
    """User information for chat responses."""
    id: int
    username: str
    full_name: Optional[str] = None
    profile_photo_url: Optional[str] = None
    availability_status: Optional[str] = None


class MessageResponse(BaseModel):
    """Schema for message response."""
    id: int
    conversation_id: int
    sender_id: int
    content: str
    message_type: str
    is_read: bool
    read_at: Optional[datetime] = None
    created_at: datetime


class ConversationResponse(BaseModel):
    """Schema for conversation response."""
    id: int
    other_user: UserInfo
    last_message_at: Optional[datetime] = None
    last_message_preview: Optional[str] = None
    unread_count: int
    created_at: datetime


class ConversationListResponse(BaseModel):
    """Schema for list of conversations."""
    conversations: List[ConversationResponse]


class MessagesResponse(BaseModel):
    """Schema for messages list response."""
    conversation_id: int
    messages: List[MessageResponse]
    has_more: bool


class MarkReadResponse(BaseModel):
    """Schema for mark as read response."""
    conversation_id: int
    updated_count: int


class UnreadCountResponse(BaseModel):
    """Schema for unread count response."""
    unread_count: int

