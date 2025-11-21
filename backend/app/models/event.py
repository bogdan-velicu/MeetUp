from sqlalchemy import Column, BigInteger, String, DateTime, Text, Integer, Boolean
from sqlalchemy.sql import func
from app.core.database import Base

class Event(Base):
    __tablename__ = "events"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    title = Column(String(150), nullable=False)
    description = Column(Text, nullable=False)
    organizer_user_id = Column(BigInteger, nullable=False, index=True)
    location_id = Column(BigInteger, nullable=True, index=True)
    latitude = Column(String(20), nullable=True)
    longitude = Column(String(20), nullable=True)
    address = Column(String(255), nullable=True)
    visibility = Column(String(20), default="public", nullable=False, index=True)
    status = Column(String(20), default="draft", nullable=False, index=True)
    start_at = Column(DateTime, nullable=False, index=True)
    end_at = Column(DateTime, nullable=True)
    capacity = Column(Integer, nullable=True)
    bonus_points = Column(Integer, default=0, nullable=False)
    eligibility_criteria_json = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

class EventParticipant(Base):
    __tablename__ = "event_participants"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    event_id = Column(BigInteger, nullable=False, index=True)
    user_id = Column(BigInteger, nullable=False, index=True)
    status = Column(String(20), default="invited", nullable=False, index=True)
    invited_at = Column(DateTime, server_default=func.now(), nullable=False)
    responded_at = Column(DateTime, nullable=True)
    attended_at = Column(DateTime, nullable=True)

