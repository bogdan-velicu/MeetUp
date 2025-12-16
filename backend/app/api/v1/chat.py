"""API endpoints for chat functionality."""
from fastapi import APIRouter, Depends, status, Query, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from typing import Optional
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.chat_service import ChatService
from app.schemas.chat import (
    MessageCreate,
    MessageResponse,
    ConversationResponse,
    ConversationListResponse,
    MessagesResponse,
    MarkReadResponse,
    UnreadCountResponse
)
from app.core.websocket_manager import WebSocketManager
import json
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/chat", tags=["chat"])
websocket_manager = WebSocketManager()


@router.get("/conversations", response_model=ConversationListResponse)
async def get_conversations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all conversations for the current user."""
    service = ChatService(db)
    conversations = service.get_conversations(current_user.id)
    return ConversationListResponse(conversations=conversations)


@router.get("/conversations/{friend_id}", response_model=ConversationResponse)
async def get_or_create_conversation(
    friend_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get or create a conversation with a friend."""
    service = ChatService(db)
    conversation = service.get_or_create_conversation(current_user.id, friend_id)
    return conversation


@router.post("/messages", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def send_message(
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a message to a friend."""
    service = ChatService(db)
    message = service.send_message(
        user_id=current_user.id,
        friend_id=message_data.friend_id,
        content=message_data.content,
        message_type=message_data.message_type
    )
    
    # Broadcast message via WebSocket if recipient is connected
    conversation = service.chat_repo.get_conversation_with_friend(
        current_user.id,
        message_data.friend_id
    )
    if conversation:
        websocket_manager.broadcast_to_conversation(
            conversation_id=conversation.id,
            message={
                "type": "new_message",
                "data": message
            },
            exclude_user_id=current_user.id
        )
    
    return message


@router.get("/conversations/{conversation_id}/messages", response_model=MessagesResponse)
async def get_messages(
    conversation_id: int,
    limit: int = Query(50, ge=1, le=100, description="Number of messages to retrieve"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get message history for a conversation."""
    service = ChatService(db)
    result = service.get_messages(
        user_id=current_user.id,
        conversation_id=conversation_id,
        limit=limit,
        offset=offset
    )
    return result


@router.patch("/conversations/{conversation_id}/read", response_model=MarkReadResponse)
async def mark_as_read(
    conversation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark all messages in a conversation as read."""
    service = ChatService(db)
    result = service.mark_as_read(current_user.id, conversation_id)
    return result


@router.get("/unread-count", response_model=UnreadCountResponse)
async def get_unread_count(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get total unread messages count for the current user."""
    service = ChatService(db)
    result = service.get_unread_count(current_user.id)
    return result


@router.websocket("/ws/{conversation_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    conversation_id: int,
    token: Optional[str] = Query(None)
):
    """
    WebSocket endpoint for real-time chat messages.
    Requires authentication token in query parameter.
    """
    if not token:
        await websocket.close(code=1008, reason="Authentication required")
        return
    
    try:
        # Connect and authenticate
        await websocket_manager.connect(websocket, conversation_id, token)
        
        # Get user_id from connection info
        user_id = None
        if websocket in websocket_manager.connection_info:
            _, user_id = websocket_manager.connection_info[websocket]
        
        logger.info(f"WebSocket connected for conversation {conversation_id}, user {user_id}")
        
        # Listen for messages
        while True:
            try:
                data = await websocket.receive_text()
                message_data = json.loads(data)
                
                # Handle different message types
                if message_data.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
                elif message_data.get("type") == "typing" and user_id:
                    # Broadcast typing indicator
                    await websocket_manager.broadcast_typing(
                        conversation_id=conversation_id,
                        user_id=user_id,
                        is_typing=message_data.get("is_typing", False)
                    )
                
            except WebSocketDisconnect:
                logger.info(f"WebSocket disconnected for conversation {conversation_id}")
                break
            except Exception as e:
                logger.error(f"Error in WebSocket: {e}")
                break
    
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        try:
            await websocket.close(code=1011, reason="Internal error")
        except:
            pass
    finally:
        websocket_manager.disconnect(websocket, conversation_id)

