# Testing Guide for Sprint 2 Development

This guide explains how to test components as we build them incrementally.

## Quick Start

### 1. Backend Unit Tests (Fast, Automated)
After implementing a service or repository, run:
```bash
cd backend
source venv/bin/activate
pytest tests/unit/test_meetings_service.py -v
```

### 2. Backend Manual API Tests (End-to-End)
After implementing API endpoints, run:
```bash
cd backend
source venv/bin/activate
python test_meetings_manual.py
```

**Prerequisites:**
- Backend server must be running: `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`

### 3. Frontend Manual Testing
- Run Flutter app
- Navigate through UI
- Check network logs in Flutter console
- Verify data displays correctly

## Testing Workflow

### Step-by-Step Process

1. **Implement Component** (e.g., MeetingRepository)
2. **Write Unit Test** (if applicable)
3. **Run Unit Test** → Fix any issues
4. **Implement Next Component** (e.g., MeetingsService)
5. **Run Unit Tests Again** → Verify integration
6. **Implement API Endpoint**
7. **Run Manual API Test** → Verify endpoint works
8. **Move to Next Component**

## Test Files

### Unit Tests
- `tests/unit/test_meetings_service.py` - Service layer tests
- Add more test files as needed

### Manual API Tests
- `test_meetings_manual.py` - End-to-end API testing script

## What Gets Tested

### Repository Layer
- Database operations
- Query correctness
- Data integrity

### Service Layer
- Business logic
- Validation rules
- Error handling
- Permissions

### API Layer
- Endpoint availability
- Request/response format
- Authentication
- Authorization

## Running All Tests

```bash
# All unit tests
pytest tests/unit/ -v

# With coverage
pytest --cov=app --cov-report=html

# View coverage report
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

## Troubleshooting

### Unit Tests Fail
- Check database fixtures
- Verify imports are correct
- Check test data setup

### Manual API Tests Fail
- Ensure backend server is running
- Check server logs for errors
- Verify database has test data
- Check authentication tokens

### Frontend Tests
- Check network tab in Flutter DevTools
- Verify API base URL is correct
- Check authentication token is set
- Look for CORS errors

## Best Practices

1. **Test Immediately**: Don't wait until the end
2. **Fix Issues Right Away**: Don't accumulate technical debt
3. **Test Both Success and Failure**: Test happy path + error cases
4. **Verify Permissions**: Test that unauthorized users can't access
5. **Check Data Integrity**: Verify data is saved/retrieved correctly

## Next Steps

As we build components, we'll:
1. Add unit tests for each new component
2. Update manual test script with new endpoints
3. Test frontend UI manually as we build it
4. Update verification checklist as we complete items

