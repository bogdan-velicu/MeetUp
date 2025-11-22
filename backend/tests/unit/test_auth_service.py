"""
Unit tests for AuthService.
These tests use a test database.
"""
import pytest
from app.services.auth_service import AuthService
from app.schemas.auth import UserRegister, UserLogin
from app.core.exceptions import UnauthorizedError, ConflictError


@pytest.mark.unit
class TestAuthService:
    """Test authentication service."""
    
    def test_register_new_user(self, db_session, test_role_user):
        """Test user registration."""
        auth_service = AuthService(db_session)
        
        user_data = UserRegister(
            username="newuser",
            email="newuser@example.com",
            password="password123",
            full_name="New User"
        )
        
        user_response, token = auth_service.register(user_data)
        
        assert user_response is not None
        assert user_response.username == "newuser"
        assert user_response.email == "newuser@example.com"
        assert token.access_token is not None
    
    def test_register_duplicate_email(self, db_session, test_user, test_role_user):
        """Test that registering with duplicate email fails."""
        auth_service = AuthService(db_session)
        
        user_data = UserRegister(
            username="differentuser",
            email=test_user.email,  # Same email
            password="password123",
            full_name="Different User"
        )
        
        with pytest.raises(ConflictError, match="Email already registered"):
            auth_service.register(user_data)
    
    def test_register_duplicate_username(self, db_session, test_user, test_role_user):
        """Test that registering with duplicate username fails."""
        auth_service = AuthService(db_session)
        
        user_data = UserRegister(
            username=test_user.username,  # Same username
            email="different@example.com",
            password="password123",
            full_name="Different User"
        )
        
        with pytest.raises(ConflictError, match="Username already taken"):
            auth_service.register(user_data)
    
    def test_login_success(self, db_session, test_user):
        """Test successful login."""
        auth_service = AuthService(db_session)
        
        login_data = UserLogin(
            email=test_user.email,
            password="testpassword123"  # Password from test_user fixture
        )
        
        user_response, token = auth_service.login(login_data)
        
        assert user_response is not None
        assert user_response.id == test_user.id
        assert token.access_token is not None
    
    def test_login_wrong_password(self, db_session, test_user):
        """Test login with wrong password."""
        auth_service = AuthService(db_session)
        
        login_data = UserLogin(
            email=test_user.email,
            password="wrongpassword"
        )
        
        with pytest.raises(UnauthorizedError, match="Invalid email or password"):
            auth_service.login(login_data)
    
    def test_login_nonexistent_user(self, db_session):
        """Test login with non-existent email."""
        auth_service = AuthService(db_session)
        
        login_data = UserLogin(
            email="nonexistent@example.com",
            password="password123"
        )
        
        with pytest.raises(UnauthorizedError, match="Invalid email or password"):
            auth_service.login(login_data)
    
    def test_refresh_token(self, db_session, test_user):
        """Test token refresh."""
        auth_service = AuthService(db_session)
        
        token = auth_service.refresh_token(test_user.id)
        
        assert token is not None
        assert token.access_token is not None
    
    def test_refresh_token_inactive_user(self, db_session):
        """Test that inactive user cannot refresh token."""
        from app.models.user import User
        from app.core.security import get_password_hash
        
        # Create inactive user
        inactive_user = User(
            username="inactive",
            email="inactive@example.com",
            password_hash=get_password_hash("password123"),
            full_name="Inactive User",
            is_active=False
        )
        db_session.add(inactive_user)
        db_session.commit()
        db_session.refresh(inactive_user)
        
        auth_service = AuthService(db_session)
        
        with pytest.raises(UnauthorizedError, match="User account is inactive"):
            auth_service.refresh_token(inactive_user.id)

