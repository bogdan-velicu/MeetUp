"""
Pytest configuration and shared fixtures.
This file is automatically loaded by pytest and provides fixtures for all tests.
"""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

from app.core.database import Base, get_db
from app.main import app
from app.models.user import User
from app.models.role import Role, UserRole
from app.models.friendship import Friendship
from app.models.user_location_history import UserLocationHistory
from app.models.user import UserLocation
from app.core.security import get_password_hash


# In-memory SQLite database for testing (faster than real database)
# Use sqlite:///:memory:?check_same_thread=false for better compatibility
SQLALCHEMY_TEST_DATABASE_URL = "sqlite:///:memory:?check_same_thread=false"

engine = create_engine(
    SQLALCHEMY_TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
    echo=False,  # Set to True for SQL debugging
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="function")
def db_session():
    """
    Create a fresh database session for each test.
    This fixture runs before each test and cleans up after.
    """
    # Create all tables
    Base.metadata.create_all(bind=engine)
    
    # Create a new session
    session = TestingSessionLocal()
    
    try:
        yield session
    finally:
        session.close()
        # Drop all tables after test
        Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def client(db_session: Session):
    """
    Create a test client for API testing.
    Overrides the database dependency to use our test database.
    """
    def override_get_db():
        try:
            yield db_session
        finally:
            pass
    
    app.dependency_overrides[get_db] = override_get_db
    
    with TestClient(app) as test_client:
        yield test_client
    
    # Clean up
    app.dependency_overrides.clear()


@pytest.fixture
def test_user(db_session: Session) -> User:
    """Create a test user."""
    user = User(
        username="testuser",
        email="test@example.com",
        password_hash=get_password_hash("testpassword123"),
        full_name="Test User",
        is_active=True,
        email_verified=True
    )
    db_session.add(user)
    db_session.flush()  # Flush to get the ID
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def test_user2(db_session: Session) -> User:
    """Create a second test user."""
    user = User(
        username="testuser2",
        email="test2@example.com",
        password_hash=get_password_hash("testpassword123"),
        full_name="Test User 2",
        is_active=True,
        email_verified=True
    )
    db_session.add(user)
    db_session.flush()  # Flush to get the ID
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def test_role_user(db_session: Session) -> Role:
    """Create a 'user' role."""
    role = Role(name="user", description="Regular user")
    db_session.add(role)
    db_session.flush()  # Flush to get the ID
    db_session.commit()
    db_session.refresh(role)
    return role


@pytest.fixture
def test_role_admin(db_session: Session) -> Role:
    """Create an 'admin' role."""
    role = Role(name="admin", description="Administrator")
    db_session.add(role)
    db_session.flush()  # Flush to get the ID
    db_session.commit()
    db_session.refresh(role)
    return role


@pytest.fixture
def test_user_with_role(db_session: Session, test_user: User, test_role_user: Role) -> User:
    """Create a test user with a role assigned."""
    user_role = UserRole(
        user_id=test_user.id,
        role_id=test_role_user.id,
        status="active"
    )
    db_session.add(user_role)
    db_session.flush()
    db_session.commit()
    return test_user


@pytest.fixture
def test_friendship(db_session: Session, test_user: User, test_user2: User) -> Friendship:
    """Create a test friendship between two users."""
    friendship = Friendship(
        user_id=test_user.id,
        friend_id=test_user2.id,
        is_close_friend=False
    )
    db_session.add(friendship)
    db_session.flush()  # Flush to get the ID
    db_session.commit()
    db_session.refresh(friendship)
    return friendship

