"""WebSocket connection manager for real-time chat."""
from fastapi import WebSocket, WebSocketDisconnect
from typing import Dict, List, Set
from collections import defaultdict
import json
import logging
from app.core.security import decode_access_token

logger = logging.getLogger(__name__)


class WebSocketManager:
    """Manages WebSocket connections for chat."""
    
    def __init__(self):
        # Map: conversation_id -> Set of WebSocket connections
        self.active_connections: Dict[int, Set[WebSocket]] = defaultdict(set)
        # Map: WebSocket -> (conversation_id, user_id)
        self.connection_info: Dict[WebSocket, tuple] = {}
    
    async def connect(self, websocket: WebSocket, conversation_id: int, token: str):
        """Connect a WebSocket to a conversation."""
        try:
            # Decode JWT token to get user_id
            payload = decode_access_token(token)
            if not payload:
                await websocket.close(code=1008, reason="Invalid token")
                return
            
            user_id = payload.get("sub")
            if not user_id:
                await websocket.close(code=1008, reason="Invalid token")
                return
            
            # Add connection
            self.active_connections[conversation_id].add(websocket)
            self.connection_info[websocket] = (conversation_id, int(user_id))
            
            logger.info(f"User {user_id} connected to conversation {conversation_id}")
            
        except Exception as e:
            logger.error(f"Error connecting WebSocket: {e}")
            await websocket.close(code=1011, reason="Internal error")
    
    def disconnect(self, websocket: WebSocket, conversation_id: int):
        """Disconnect a WebSocket from a conversation."""
        if websocket in self.active_connections[conversation_id]:
            self.active_connections[conversation_id].remove(websocket)
        
        if websocket in self.connection_info:
            del self.connection_info[websocket]
        
        # Clean up empty conversation sets
        if not self.active_connections[conversation_id]:
            del self.active_connections[conversation_id]
    
    async def broadcast_to_conversation(
        self,
        conversation_id: int,
        message: dict,
        exclude_user_id: int = None
    ):
        """Broadcast a message to all connections in a conversation."""
        if conversation_id not in self.active_connections:
            return
        
        disconnected = []
        message_json = json.dumps(message)
        
        for websocket in self.active_connections[conversation_id]:
            try:
                # Skip if this is the sender
                if websocket in self.connection_info:
                    _, user_id = self.connection_info[websocket]
                    if exclude_user_id and user_id == exclude_user_id:
                        continue
                
                await websocket.send_text(message_json)
            except Exception as e:
                logger.error(f"Error broadcasting to WebSocket: {e}")
                disconnected.append(websocket)
        
        # Clean up disconnected connections
        for ws in disconnected:
            self.disconnect(ws, conversation_id)
    
    async def broadcast_typing(
        self,
        conversation_id: int,
        user_id: int,
        is_typing: bool
    ):
        """Broadcast typing indicator to conversation."""
        message = {
            "type": "typing",
            "user_id": user_id,
            "is_typing": is_typing
        }
        await self.broadcast_to_conversation(
            conversation_id=conversation_id,
            message=message,
            exclude_user_id=user_id
        )
    
    def get_connection_count(self, conversation_id: int) -> int:
        """Get number of active connections for a conversation."""
        return len(self.active_connections.get(conversation_id, set()))

