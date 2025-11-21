from sqlalchemy import Column, BigInteger, String, Boolean, DateTime, Text, Integer, Numeric
from sqlalchemy.sql import func
from app.core.database import Base

class Location(Base):
    __tablename__ = "locations"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    name = Column(String(150), nullable=False)
    description = Column(Text, nullable=True)
    owner_user_id = Column(BigInteger, nullable=True, index=True)
    address_line1 = Column(String(200), nullable=False)
    address_line2 = Column(String(200), nullable=True)
    city = Column(String(100), nullable=False, index=True)
    postal_code = Column(String(20), nullable=True)
    country = Column(String(100), nullable=False)
    latitude = Column(String(20), nullable=False)
    longitude = Column(String(20), nullable=False)
    place_type = Column(String(40), nullable=True)
    phone_number = Column(String(30), nullable=True)
    website_url = Column(String(255), nullable=True)
    opening_hours_json = Column(Text, nullable=True)
    is_poi = Column(Boolean, default=False, nullable=False, index=True)
    average_rating = Column(Numeric(3, 2), default=0.00, nullable=False)
    total_reviews = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

class LocationReview(Base):
    __tablename__ = "location_reviews"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    location_id = Column(BigInteger, nullable=False, index=True)
    user_id = Column(BigInteger, nullable=False, index=True)
    rating = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

class LocationCampaign(Base):
    __tablename__ = "location_campaigns"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    location_id = Column(BigInteger, nullable=False, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    offer_details = Column(Text, nullable=True)
    start_at = Column(DateTime, nullable=False)
    end_at = Column(DateTime, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False, index=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

