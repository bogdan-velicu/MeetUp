from sqlalchemy import Column, BigInteger, String, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base

class Meeting(Base):
    __tablename__ = "meetings"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    organizer_id = Column(BigInteger, nullable=False, index=True)
    title = Column(String(200), nullable=True)
    description = Column(Text, nullable=True)
    location_id = Column(BigInteger, nullable=True, index=True)
    latitude = Column(String(20), nullable=True)
    longitude = Column(String(20), nullable=True)
    address = Column(String(255), nullable=True)
    scheduled_at = Column(DateTime, nullable=False, index=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)
    status = Column(String(20), default="pending", nullable=False, index=True)

class MeetingParticipant(Base):
    __tablename__ = "meeting_participants"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    meeting_id = Column(BigInteger, nullable=False, index=True)
    user_id = Column(BigInteger, nullable=False, index=True)
    status = Column(String(20), default="pending", nullable=False)
    confirmed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

