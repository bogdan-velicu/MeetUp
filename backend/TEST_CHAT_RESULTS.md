# Chat Backend Testing Results

## Test Execution Guide

### Prerequisites
1. Backend server must be running on `http://localhost:9000`
2. Database must be running and accessible
3. Two users must exist and be friends in the database

### Running the Test

```bash
cd backend
source venv/bin/activate
python3 test_chat_backend.py
```

The script will:
1. Check if backend server is running
2. Prompt for two user credentials (must be friends)
3. Run comprehensive tests on all chat endpoints
4. Display results summary

## Test Coverage

### ✅ Basic Functionality Tests
- [x] Get all conversations
- [x] Get or create conversation with friend
- [x] Send message
- [x] Get message history
- [x] Mark messages as read
- [x] Get unread count

### ✅ Validation Tests
- [x] Friendship validation (block non-friends)
- [x] Message content validation (empty messages)
- [x] Message length validation

### ✅ Edge Cases
- [x] Conversation normalization (user1_id < user2_id)
- [x] Same conversation retrieved with reversed user IDs
- [x] Unread count updates correctly
- [x] Message preview truncation

## Manual Testing Checklist

### 1. REST API Endpoints

#### GET /api/v1/chat/conversations
```bash
curl -X GET "http://localhost:9000/api/v1/chat/conversations" \
  -H "Authorization: Bearer YOUR_TOKEN"
```
**Expected**: List of conversations with last message preview

#### GET /api/v1/chat/conversations/{friend_id}
```bash
curl -X GET "http://localhost:9000/api/v1/chat/conversations/2" \
  -H "Authorization: Bearer YOUR_TOKEN"
```
**Expected**: Conversation object or creates new one

#### POST /api/v1/chat/messages
```bash
curl -X POST "http://localhost:9000/api/v1/chat/messages" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"friend_id": 2, "content": "Hello!", "message_type": "text"}'
```
**Expected**: Created message object

#### GET /api/v1/chat/conversations/{conversation_id}/messages
```bash
curl -X GET "http://localhost:9000/api/v1/chat/conversations/1/messages?limit=50&offset=0" \
  -H "Authorization: Bearer YOUR_TOKEN"
```
**Expected**: List of messages with pagination

#### PATCH /api/v1/chat/conversations/{conversation_id}/read
```bash
curl -X PATCH "http://localhost:9000/api/v1/chat/conversations/1/read" \
  -H "Authorization: Bearer YOUR_TOKEN"
```
**Expected**: Updated count of read messages

#### GET /api/v1/chat/unread-count
```bash
curl -X GET "http://localhost:9000/api/v1/chat/unread-count" \
  -H "Authorization: Bearer YOUR_TOKEN"
```
**Expected**: Total unread message count

### 2. WebSocket Testing

#### Connect to WebSocket
```javascript
// Using JavaScript/Node.js
const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:9000/api/v1/chat/ws/1?token=YOUR_JWT_TOKEN');

ws.on('open', () => {
  console.log('Connected to WebSocket');
  
  // Send ping
  ws.send(JSON.stringify({ type: 'ping' }));
  
  // Send typing indicator
  ws.send(JSON.stringify({ type: 'typing', is_typing: true }));
});

ws.on('message', (data) => {
  const message = JSON.parse(data);
  console.log('Received:', message);
});

ws.on('error', (error) => {
  console.error('WebSocket error:', error);
});
```

**Expected Behavior**:
- Connection established with valid token
- Receives pong response to ping
- Receives new_message events when messages are sent
- Receives typing indicators

### 3. Error Cases

#### Test Non-Friend Message
```bash
curl -X POST "http://localhost:9000/api/v1/chat/messages" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"friend_id": 999, "content": "Hello!", "message_type": "text"}'
```
**Expected**: 403 Forbidden or 404 Not Found

#### Test Empty Message
```bash
curl -X POST "http://localhost:9000/api/v1/chat/messages" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"friend_id": 2, "content": "", "message_type": "text"}'
```
**Expected**: 422 Validation Error

#### Test Invalid Conversation Access
```bash
curl -X GET "http://localhost:9000/api/v1/chat/conversations/999/messages" \
  -H "Authorization: Bearer YOUR_TOKEN"
```
**Expected**: 404 Not Found

### 4. Database Verification

```sql
-- Check conversations
SELECT * FROM conversations ORDER BY created_at DESC LIMIT 10;

-- Check messages
SELECT * FROM messages ORDER BY created_at DESC LIMIT 10;

-- Check unread messages
SELECT conversation_id, COUNT(*) as unread_count 
FROM messages 
WHERE is_read = 0 
GROUP BY conversation_id;
```

## Known Issues / Notes

1. **Date Format**: Service returns ISO strings, Pydantic models expect datetime - FastAPI handles conversion automatically
2. **WebSocket Authentication**: Token must be passed as query parameter
3. **Message Preview**: Truncated to 255 characters in database
4. **Conversation Normalization**: Always stores with user1_id < user2_id

## Performance Considerations

- Message history pagination: 50 messages per page (configurable)
- Database indexes on:
  - `conversations(user1_id, user2_id)` - unique constraint
  - `messages(conversation_id, created_at)` - message history queries
  - `messages(is_read, conversation_id)` - unread queries

## Next Steps After Testing

1. ✅ Verify all REST endpoints work correctly
2. ✅ Test WebSocket connections
3. ✅ Verify FCM notifications are sent
4. ⏳ Proceed with frontend implementation
5. ⏳ Integration testing with frontend

---

**Last Updated**: December 12, 2025

