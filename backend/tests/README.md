# Testing Guide

This guide explains how to write and run unit tests for the MeetUp backend.

## What are Unit Tests?

**Unit tests** are automated tests that verify individual components (functions, methods, classes) work correctly in isolation. They:

- **Test small pieces** of code (a single function or method)
- **Run fast** (usually milliseconds)
- **Don't require external services** (like real databases, APIs)
- **Help catch bugs early** before they reach production
- **Document expected behavior** of your code

### Example

Instead of manually testing "Can a user register?" every time you change code, you write a test:

```python
def test_register_new_user():
    # Arrange: Set up test data
    user_data = UserRegister(username="test", email="test@example.com", ...)
    
    # Act: Call the function
    user, token = auth_service.register(user_data)
    
    # Assert: Verify the result
    assert user.username == "test"
    assert token is not None
```

## Running Tests

### Run all tests:
```bash
cd backend
source venv/bin/activate
pytest
```

### Run specific test file:
```bash
pytest tests/unit/test_auth_service.py
```

### Run specific test:
```bash
pytest tests/unit/test_auth_service.py::TestAuthService::test_register_new_user
```

### Run with coverage report:
```bash
pytest --cov=app --cov-report=html
# Then open htmlcov/index.html in browser
```

### Run only unit tests (fast):
```bash
pytest -m unit
```

## Test Structure

```
tests/
├── __init__.py
├── conftest.py          # Shared fixtures (test data)
├── README.md           # This file
└── unit/               # Unit tests
    ├── __init__.py
    ├── test_security.py
    ├── test_auth_service.py
    ├── test_friends_service.py
    └── test_location_service.py
```

## Writing Tests

### 1. Test File Naming
- Start with `test_`
- Example: `test_auth_service.py`

### 2. Test Function Naming
- Start with `test_`
- Be descriptive: `test_register_new_user` not `test1`

### 3. Test Class (Optional)
- Group related tests in a class
- Class name starts with `Test`

### 4. Test Structure (AAA Pattern)
```python
def test_example():
    # Arrange: Set up test data
    user = create_test_user()
    
    # Act: Execute the code being tested
    result = service.doSomething(user)
    
    # Assert: Verify the result
    assert result is not None
    assert result.status == "success"
```

### 5. Using Fixtures
Fixtures provide reusable test data. They're defined in `conftest.py`:

```python
def test_something(test_user, db_session):
    # test_user is automatically provided by pytest
    assert test_user.username == "testuser"
```

Available fixtures:
- `db_session`: Database session (fresh for each test)
- `test_user`: A test user
- `test_user2`: Another test user
- `test_friendship`: A friendship between test users
- `client`: FastAPI test client

### 6. Testing Exceptions
```python
def test_login_wrong_password():
    with pytest.raises(UnauthorizedError, match="Invalid password"):
        auth_service.login(wrong_credentials)
```

## Test Markers

Mark tests with categories:

```python
@pytest.mark.unit
def test_fast_function():
    pass

@pytest.mark.integration
def test_database_operation():
    pass
```

## Coverage Goal

We aim for **60% code coverage**, meaning 60% of our code is tested.

Check coverage:
```bash
pytest --cov=app --cov-report=term-missing
```

## Best Practices

1. **Test one thing per test**
2. **Use descriptive names**: `test_register_duplicate_email` not `test1`
3. **Keep tests independent**: Each test should work alone
4. **Test edge cases**: Empty inputs, invalid data, boundaries
5. **Test both success and failure**: Happy path + error cases
6. **Don't test implementation details**: Test behavior, not how it's done
7. **Keep tests fast**: Unit tests should run in milliseconds

## Example Test

Here's a complete example:

```python
@pytest.mark.unit
class TestAuthService:
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
        assert token.access_token is not None
```

## Next Steps

1. Run the existing tests: `pytest`
2. Look at the example tests in `tests/unit/`
3. Write tests for new features as you develop them
4. Aim for 60% coverage minimum

## Resources

- [Pytest Documentation](https://docs.pytest.org/)
- [Python Testing Guide](https://docs.python.org/3/library/unittest.html)

