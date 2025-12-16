"""Service for managing chat conversations and messages."""
from sqlalchemy.orm import Session
from app.repositories.chat_repository import ChatRepository
from app.repositories.friendship_repository import FriendshipRepository
from app.repositories.user_repository import UserRepository
from app.services.notification_service import NotificationService
from app.core.exceptions import NotFoundError, ValidationError, ForbiddenError
from app.models.chat import Conversation, Message
from typing import List, Dict, Optional
from datetime import datetime


class ChatService:
    """Service for managing chat functionality."""
    
    def __init__(self, db: Session):
        self.chat_repo = ChatRepository(db)
        self.friendship_repo = FriendshipRepository(db)
        self.user_repo = UserRepository(db)
        self.notification_service = NotificationService(db)
        self.db = db
    
    def get_conversations(self, user_id: int) -> List[Dict]:
        """
        Get all conversations for a user with last message preview and unread counts.
        """
        conversations = self.chat_repo.get_user_conversations(user_id)
        
        result = []
        for conv in conversations:
            other_user_id = conv.get_other_user_id(user_id)
            other_user = self.user_repo.get_by_id(other_user_id)
            
            if not other_user:
                continue
            
            unread_count = self.chat_repo.get_conversation_unread_count(conv.id, user_id)
            
            result.append({
                "id": conv.id,
                "other_user": {
                    "id": other_user.id,
                    "username": other_user.username,
                    "full_name": other_user.full_name,
                    "profile_photo_url": other_user.profile_photo_url,
                    "availability_status": other_user.availability_status,
                },
                "last_message_at": conv.last_message_at.isoformat() if conv.last_message_at else None,
                "last_message_preview": conv.last_message_preview,
                "unread_count": unread_count,
                "created_at": conv.created_at.isoformat(),
            })
        
        return result
    
    def get_or_create_conversation(self, user_id: int, friend_id: int) -> Dict:
        """
        Get or create a conversation with a friend.
        Validates friendship before allowing conversation.
        """
        if user_id == friend_id:
            raise ValidationError("Cannot start a conversation with yourself")
        
        # Verify friendship exists and is accepted
        friendship = self.friendship_repo.get_friendship(user_id, friend_id)
        if not friendship:
            raise ForbiddenError("You must be friends to start a conversation")
        
        if friendship.status != "accepted":
            raise ForbiddenError("You can only chat with accepted friends")
        
        # Get or create conversation
        conversation = self.chat_repo.get_or_create_conversation(user_id, friend_id)
        
        # Get other user info
        other_user_id = conversation.get_other_user_id(user_id)
        other_user = self.user_repo.get_by_id(other_user_id)
        
        if not other_user:
            raise NotFoundError("Friend not found")
        
        unread_count = self.chat_repo.get_conversation_unread_count(conversation.id, user_id)
        
        return {
            "id": conversation.id,
            "other_user": {
                "id": other_user.id,
                "username": other_user.username,
                "full_name": other_user.full_name,
                "profile_photo_url": other_user.profile_photo_url,
                "availability_status": other_user.availability_status,
            },
            "last_message_at": conversation.last_message_at.isoformat() if conversation.last_message_at else None,
            "last_message_preview": conversation.last_message_preview,
            "unread_count": unread_count,
            "created_at": conversation.created_at.isoformat(),
        }
    
    def send_message(
        self,
        user_id: int,
        friend_id: int,
        content: str,
        message_type: str = "text"
    ) -> Dict:
        """
        Send a message to a friend.
        Creates conversation if it doesn't exist.
        """
        if not content or not content.strip():
            raise ValidationError("Message content cannot be empty")
        
        if len(content) > 10000:  # Reasonable limit
            raise ValidationError("Message is too long (max 10000 characters)")
        
        # Verify friendship
        friendship = self.friendship_repo.get_friendship(user_id, friend_id)
        if not friendship or friendship.status != "accepted":
            raise ForbiddenError("You can only send messages to accepted friends")
        
        # Get or create conversation
        conversation = self.chat_repo.get_or_create_conversation(user_id, friend_id)
        
        # Create message
        message = self.chat_repo.create_message(
            conversation_id=conversation.id,
            sender_id=user_id,
            content=content.strip(),
            message_type=message_type
        )
        
        # Get recipient info for notification
        recipient = self.user_repo.get_by_id(friend_id)
        sender = self.user_repo.get_by_id(user_id)
        
        # Send push notification to recipient
        if recipient and recipient.fcm_token:
            try:
                sender_name = sender.full_name if sender and sender.full_name else sender.username if sender else "Someone"
                preview = content[:100] + "..." if len(content) > 100 else content
                self.notification_service.send_chat_message_notification(
                    recipient_id=friend_id,
                    sender_name=sender_name,
                    message_preview=preview,
                    conversation_id=conversation.id
                )
            except Exception as e:
                # Log but don't fail the message send
                print(f"Failed to send chat notification: {e}")
        
        return {
            "id": message.id,
            "conversation_id": message.conversation_id,
            "sender_id": message.sender_id,
            "content": message.content,
            "message_type": message.message_type,
            "is_read": message.is_read,
            "created_at": message.created_at.isoformat(),
        }
    
    def get_messages(
        self,
        user_id: int,
        conversation_id: int,
        limit: int = 50,
        offset: int = 0
    ) -> Dict:
        """
        Get message history for a conversation with pagination.
        """
        # Verify user is part of conversation
        conversation = self.chat_repo.get_conversation_by_id(conversation_id, user_id)
        if not conversation:
            raise NotFoundError("Conversation not found")
        
        # Get messages
        messages = self.chat_repo.get_messages(conversation_id, limit, offset)
        
        # Format messages
        message_list = []
        for msg in messages:
            message_list.append({
                "id": msg.id,
                "conversation_id": msg.conversation_id,
                "sender_id": msg.sender_id,
                "content": msg.content,
                "message_type": msg.message_type,
                "is_read": msg.is_read,
                "read_at": msg.read_at.isoformat() if msg.read_at else None,
                "created_at": msg.created_at.isoformat(),
            })
        
        # Mark messages as read when user views them
        if offset == 0:  # Only mark as read when viewing latest messages
            self.chat_repo.mark_messages_as_read(conversation_id, user_id)
        
        return {
            "conversation_id": conversation_id,
            "messages": message_list,
            "has_more": len(messages) == limit,
        }
    
    def mark_as_read(self, user_id: int, conversation_id: int) -> Dict:
        """Mark all messages in a conversation as read."""
        conversation = self.chat_repo.get_conversation_by_id(conversation_id, user_id)
        if not conversation:
            raise NotFoundError("Conversation not found")
        
        updated_count = self.chat_repo.mark_messages_as_read(conversation_id, user_id)
        
        return {
            "conversation_id": conversation_id,
            "updated_count": updated_count,
        }
    
    def get_unread_count(self, user_id: int) -> Dict:
        """Get total unread messages count for a user."""
        count = self.chat_repo.get_unread_messages_count(user_id)
        return {
            "unread_count": count,
        }

