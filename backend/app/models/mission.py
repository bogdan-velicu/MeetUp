from sqlalchemy import Column, BigInteger, String, Boolean, Integer, DateTime, Text
from sqlalchemy.sql import func
from app.core.database import Base

class Mission(Base):
    __tablename__ = "missions"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    mission_type = Column(String(30), nullable=False)
    points_reward = Column(Integer, nullable=False)
    criteria_json = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False, index=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

class UserMission(Base):
    __tablename__ = "user_missions"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    user_id = Column(BigInteger, nullable=False, index=True)
    mission_id = Column(BigInteger, nullable=False, index=True)
    status = Column(String(20), default="in_progress", nullable=False, index=True)
    progress_json = Column(Text, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

