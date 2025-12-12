from sqlalchemy import Column, BigInteger, String, DateTime, Integer, Enum as SQLEnum
from sqlalchemy.sql import func
from app.core.database import Base
import enum

class ShakeSessionStatus(str, enum.Enum):
    ACTIVE = "active"
    MATCHED = "matched"
    EXPIRED = "expired"

class ShakeSession(Base):
    __tablename__ = "shake_sessions"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    user_id = Column(BigInteger, nullable=False, index=True)
    latitude = Column(String(20), nullable=False)
    longitude = Column(String(20), nullable=False)
    accuracy_m = Column(String(20), nullable=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False, index=True)
    expires_at = Column(DateTime, nullable=False, index=True)
    matched_user_id = Column(BigInteger, nullable=True, index=True)
    matched_at = Column(DateTime, nullable=True)
    status = Column(SQLEnum(ShakeSessionStatus), default=ShakeSessionStatus.ACTIVE, nullable=False, index=True)
    meeting_id = Column(BigInteger, nullable=True, index=True)

