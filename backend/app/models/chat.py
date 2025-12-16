"""Chat models for conversations and messages."""
from sqlalchemy import Column, BigInteger, String, DateTime, Text, Boolean, ForeignKey, Index, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class Conversation(Base):
    """Represents a conversation between two users."""
    __tablename__ = "conversations"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    user1_id = Column(BigInteger, nullable=False, index=True)
    user2_id = Column(BigInteger, nullable=False, index=True)
    last_message_at = Column(DateTime, nullable=True, index=True)
    last_message_preview = Column(String(255), nullable=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    messages = relationship("Message", back_populates="conversation", cascade="all, delete-orphan")

    __table_args__ = (
        # Ensure unique conversation between two users (order-independent)
        UniqueConstraint('user1_id', 'user2_id', name='unique_conversation'),
        # Index for efficient querying
        Index('idx_conversation_users', 'user1_id', 'user2_id'),
    )

    def get_other_user_id(self, current_user_id: int) -> int:
        """Get the ID of the other user in the conversation."""
        return self.user2_id if self.user1_id == current_user_id else self.user1_id


class Message(Base):
    """Represents a message in a conversation."""
    __tablename__ = "messages"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    conversation_id = Column(BigInteger, ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False, index=True)
    sender_id = Column(BigInteger, nullable=False, index=True)
    content = Column(Text, nullable=False)
    message_type = Column(String(20), default="text", nullable=False)  # text, image, location, etc.
    is_read = Column(Boolean, default=False, nullable=False, index=True)
    read_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False, index=True)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    conversation = relationship("Conversation", back_populates="messages")

    __table_args__ = (
        # Index for efficient message history queries
        Index('idx_message_conversation_created', 'conversation_id', 'created_at'),
        # Index for unread message queries
        Index('idx_message_unread', 'conversation_id', 'is_read', 'sender_id'),
    )

