from sqlalchemy import Column, BigInteger, String, Boolean, Integer, DateTime, Text, Time
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    username = Column(String(60), unique=True, index=True, nullable=False)
    full_name = Column(String(120), nullable=False)
    email = Column(String(150), unique=True, index=True, nullable=False)
    phone_number = Column(String(30), nullable=True)
    password_hash = Column(String(255), nullable=False)
    bio = Column(Text, nullable=True)
    profile_photo_url = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    email_verified = Column(Boolean, default=False, nullable=False)
    phone_verified = Column(Boolean, default=False, nullable=False)
    location_sharing_enabled = Column(Boolean, default=True, nullable=False)
    location_update_interval = Column(Integer, default=15, nullable=False)  # minutes
    availability_status = Column(String(20), default="available", nullable=False)
    total_points = Column(Integer, default=0, nullable=False)
    fcm_token = Column(String(255), nullable=True)  # Firebase Cloud Messaging token
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)
    last_login_at = Column(DateTime, nullable=True)

class UserLocation(Base):
    __tablename__ = "user_locations"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    user_id = Column(BigInteger, unique=True, nullable=False, index=True)
    latitude = Column(String(20), nullable=False)  # Using String for decimal precision
    longitude = Column(String(20), nullable=False)
    accuracy_m = Column(String(20), nullable=True)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

class AvailabilitySchedule(Base):
    __tablename__ = "availability_schedules"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    user_id = Column(BigInteger, nullable=False, index=True)
    day_of_week = Column(Integer, nullable=False)  # 0=Monday, 6=Sunday
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

