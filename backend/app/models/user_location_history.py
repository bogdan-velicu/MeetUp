from sqlalchemy import Column, BigInteger, DateTime, String, Float, Numeric
from sqlalchemy.sql import func
from app.core.database import Base

class UserLocationHistory(Base):
    __tablename__ = "user_location_history"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    user_id = Column(BigInteger, nullable=False, index=True)
    recorded_at = Column(DateTime, nullable=False, index=True)
    latitude = Column(String(20), nullable=False)  # Using String for decimal precision
    longitude = Column(String(20), nullable=False)
    altitude_m = Column(String(20), nullable=True)
    accuracy_m = Column(String(20), nullable=True)
    speed_mps = Column(String(20), nullable=True)
    heading_deg = Column(String(20), nullable=True)
    source = Column(String(20), default="gps", nullable=False)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)

