"""Repository for chat-related database operations."""
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc, func
from app.models.chat import Conversation, Message
from app.models.user import User
from typing import List, Optional
from datetime import datetime


class ChatRepository:
    """Repository for managing conversations and messages."""
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_or_create_conversation(self, user1_id: int, user2_id: int) -> Conversation:
        """
        Get existing conversation between two users or create a new one.
        Ensures user1_id < user2_id for consistency.
        """
        # Normalize: always store with smaller ID first
        if user1_id > user2_id:
            user1_id, user2_id = user2_id, user1_id
        
        conversation = self.db.query(Conversation).filter(
            and_(
                Conversation.user1_id == user1_id,
                Conversation.user2_id == user2_id
            )
        ).first()
        
        if not conversation:
            conversation = Conversation(
                user1_id=user1_id,
                user2_id=user2_id
            )
            self.db.add(conversation)
            self.db.commit()
            self.db.refresh(conversation)
        
        return conversation
    
    def get_conversation_by_id(self, conversation_id: int, user_id: int) -> Optional[Conversation]:
        """Get conversation by ID, ensuring user is a participant."""
        conversation = self.db.query(Conversation).filter(
            and_(
                Conversation.id == conversation_id,
                or_(
                    Conversation.user1_id == user_id,
                    Conversation.user2_id == user_id
                )
            )
        ).first()
        return conversation
    
    def get_user_conversations(self, user_id: int) -> List[Conversation]:
        """Get all conversations for a user, ordered by last message time."""
        conversations = self.db.query(Conversation).filter(
            or_(
                Conversation.user1_id == user_id,
                Conversation.user2_id == user_id
            )
        ).order_by(desc(Conversation.last_message_at)).all()
        return conversations
    
    def get_conversation_with_friend(self, user_id: int, friend_id: int) -> Optional[Conversation]:
        """Get conversation between user and friend."""
        # Normalize IDs
        user1_id, user2_id = (user_id, friend_id) if user_id < friend_id else (friend_id, user_id)
        
        conversation = self.db.query(Conversation).filter(
            and_(
                Conversation.user1_id == user1_id,
                Conversation.user2_id == user2_id
            )
        ).first()
        return conversation
    
    def create_message(
        self,
        conversation_id: int,
        sender_id: int,
        content: str,
        message_type: str = "text"
    ) -> Message:
        """Create a new message in a conversation."""
        message = Message(
            conversation_id=conversation_id,
            sender_id=sender_id,
            content=content,
            message_type=message_type
        )
        self.db.add(message)
        
        # Update conversation's last message info
        conversation = self.db.query(Conversation).filter(
            Conversation.id == conversation_id
        ).first()
        if conversation:
            # Truncate preview to 255 chars
            preview = content[:252] + "..." if len(content) > 255 else content
            conversation.last_message_at = datetime.utcnow()
            conversation.last_message_preview = preview
            conversation.updated_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(message)
        return message
    
    def get_messages(
        self,
        conversation_id: int,
        limit: int = 50,
        offset: int = 0
    ) -> List[Message]:
        """Get messages for a conversation with pagination, ordered by creation time."""
        messages = self.db.query(Message).filter(
            Message.conversation_id == conversation_id
        ).order_by(desc(Message.created_at)).limit(limit).offset(offset).all()
        
        # Return in chronological order (oldest first)
        return list(reversed(messages))
    
    def get_unread_messages_count(self, user_id: int, conversation_id: Optional[int] = None) -> int:
        """Get count of unread messages for a user in a conversation or all conversations."""
        query = self.db.query(func.count(Message.id)).join(Conversation).filter(
            and_(
                Message.sender_id != user_id,  # Messages not sent by user
                Message.is_read == False,
                or_(
                    Conversation.user1_id == user_id,
                    Conversation.user2_id == user_id
                )
            )
        )
        
        if conversation_id:
            query = query.filter(Message.conversation_id == conversation_id)
        
        return query.scalar() or 0
    
    def mark_messages_as_read(self, conversation_id: int, user_id: int) -> int:
        """Mark all unread messages in a conversation as read (except user's own messages)."""
        updated = self.db.query(Message).filter(
            and_(
                Message.conversation_id == conversation_id,
                Message.sender_id != user_id,
                Message.is_read == False
            )
        ).update({
            'is_read': True,
            'read_at': datetime.utcnow()
        })
        self.db.commit()
        return updated
    
    def get_conversation_unread_count(self, conversation_id: int, user_id: int) -> int:
        """Get unread message count for a specific conversation."""
        count = self.db.query(func.count(Message.id)).filter(
            and_(
                Message.conversation_id == conversation_id,
                Message.sender_id != user_id,
                Message.is_read == False
            )
        ).scalar()
        return count or 0
    
    def get_last_message(self, conversation_id: int) -> Optional[Message]:
        """Get the last message in a conversation."""
        message = self.db.query(Message).filter(
            Message.conversation_id == conversation_id
        ).order_by(desc(Message.created_at)).first()
        return message

