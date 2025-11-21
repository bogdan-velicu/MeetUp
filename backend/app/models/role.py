from sqlalchemy import Column, BigInteger, SmallInteger, String, DateTime, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base

class Role(Base):
    __tablename__ = "roles"

    id = Column(SmallInteger, primary_key=True, index=True, autoincrement=True)
    name = Column(String(50), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

class UserRole(Base):
    __tablename__ = "user_roles"

    user_id = Column(BigInteger, primary_key=True, nullable=False, index=True)
    role_id = Column(SmallInteger, primary_key=True, nullable=False, index=True)
    assigned_at = Column(DateTime, server_default=func.now(), nullable=False)
    status = Column(String(20), default="active", nullable=False)

