from sqlalchemy import Column, BigInteger, Integer, String, DateTime, Text, Boolean
from sqlalchemy.sql import func
from app.core.database import Base

class PointsTransaction(Base):
    __tablename__ = "points_transactions"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    user_id = Column(BigInteger, nullable=False, index=True)
    points = Column(Integer, nullable=False)
    transaction_type = Column(String(30), nullable=False, index=True)
    reference_id = Column(BigInteger, nullable=True)
    description = Column(String(255), nullable=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False, index=True)

class StoreItem(Base):
    __tablename__ = "store_items"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    name = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    points_cost = Column(Integer, nullable=False)
    item_type = Column(String(30), nullable=False)
    metadata_json = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False, index=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

class UserPurchase(Base):
    __tablename__ = "user_purchases"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    user_id = Column(BigInteger, nullable=False, index=True)
    store_item_id = Column(BigInteger, nullable=False, index=True)
    purchased_at = Column(DateTime, server_default=func.now(), nullable=False)

