from sqlalchemy import Column, BigInteger, Boolean, DateTime, UniqueConstraint
from sqlalchemy.sql import func
from app.core.database import Base

class Friendship(Base):
    __tablename__ = "friendships"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    user_id = Column(BigInteger, nullable=False, index=True)
    friend_id = Column(BigInteger, nullable=False, index=True)
    is_close_friend = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)

    __table_args__ = (
        UniqueConstraint('user_id', 'friend_id', name='unique_friendship'),
    )

