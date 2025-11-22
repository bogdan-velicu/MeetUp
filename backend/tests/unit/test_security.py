"""
Unit tests for security module (password hashing, JWT tokens).
These tests don't require a database.
"""
import pytest
from datetime import timedelta
from app.core.security import (
    get_password_hash,
    verify_password,
    create_access_token,
    decode_access_token
)
from app.core.config import settings


@pytest.mark.unit
class TestPasswordHashing:
    """Test password hashing and verification."""
    
    def test_hash_password(self):
        """Test that password hashing works."""
        password = "testpassword123"
        hashed = get_password_hash(password)
        
        assert hashed is not None
        assert hashed != password
        assert len(hashed) > 0
    
    def test_verify_correct_password(self):
        """Test that correct password is verified."""
        password = "testpassword123"
        hashed = get_password_hash(password)
        
        assert verify_password(password, hashed) is True
    
    def test_verify_incorrect_password(self):
        """Test that incorrect password is rejected."""
        password = "testpassword123"
        wrong_password = "wrongpassword"
        hashed = get_password_hash(password)
        
        assert verify_password(wrong_password, hashed) is False
    
    def test_hash_long_password(self):
        """Test that long passwords work (no 72-byte limit)."""
        long_password = "a" * 200  # 200 character password
        hashed = get_password_hash(long_password)
        
        assert hashed is not None
        assert verify_password(long_password, hashed) is True
    
    def test_hash_different_passwords_different_hashes(self):
        """Test that same password produces different hashes (salt)."""
        password = "testpassword123"
        hash1 = get_password_hash(password)
        hash2 = get_password_hash(password)
        
        # Hashes should be different due to salt
        assert hash1 != hash2
        # But both should verify correctly
        assert verify_password(password, hash1) is True
        assert verify_password(password, hash2) is True


@pytest.mark.unit
class TestJWTTokens:
    """Test JWT token creation and decoding."""
    
    def test_create_access_token(self):
        """Test that access token is created."""
        data = {"sub": "123", "email": "test@example.com"}
        token = create_access_token(data)
        
        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 0
    
    def test_decode_valid_token(self):
        """Test that valid token can be decoded."""
        data = {"sub": "123", "email": "test@example.com"}
        token = create_access_token(data)
        decoded = decode_access_token(token)
        
        assert decoded is not None
        assert decoded["sub"] == "123"
        assert decoded["email"] == "test@example.com"
        assert "exp" in decoded
    
    def test_decode_invalid_token(self):
        """Test that invalid token returns None."""
        invalid_token = "invalid.token.here"
        decoded = decode_access_token(invalid_token)
        
        assert decoded is None
    
    def test_token_expiration(self):
        """Test that token has expiration time."""
        data = {"sub": "123", "email": "test@example.com"}
        token = create_access_token(data, expires_delta=timedelta(minutes=30))
        decoded = decode_access_token(token)
        
        assert decoded is not None
        assert "exp" in decoded
        # Expiration should be in the future
        from datetime import datetime
        assert decoded["exp"] > datetime.utcnow().timestamp()

