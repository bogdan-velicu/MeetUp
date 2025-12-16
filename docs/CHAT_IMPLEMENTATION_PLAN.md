# Chat Functionality Implementation Plan

## Current State Assessment

### ✅ What We Have
1. **Authentication System** - Users can log in and authenticate
2. **Friends System** - Users can add friends and see friend lists
3. **FCM Notifications** - Push notifications are working
4. **Database Infrastructure** - SQLAlchemy, Alembic migrations
5. **FastAPI Backend** - Supports WebSockets natively
6. **Flutter Frontend** - UI framework ready
7. **API Client** - HTTP client configured with auth

### ❌ What's Missing
1. **Database Models** - No Conversation or Message models
2. **Chat API Endpoints** - No REST endpoints for chat
3. **WebSocket Support** - No real-time messaging infrastructure
4. **Chat UI** - Only placeholder screen exists
5. **Message Storage** - No persistence layer for messages

---

## Implementation Approach

### Recommended: **Hybrid Approach** (REST + WebSockets)

**Why?**
- REST API for message history, sending messages, conversation management
- WebSockets for real-time message delivery (when both users are online)
- FCM push notifications for when users are offline
- Best user experience with fallback mechanisms

### Alternative: **REST + Polling** (Simpler, but less efficient)
- Easier to implement
- No WebSocket complexity
- Higher battery/data usage
- Slight delay in message delivery

---

## Implementation Plan

### Phase 1: Database Schema (Backend)

#### 1.1 Create Database Models

**File: `backend/app/models/chat.py`**

```python
# Conversation Model
- id (BigInteger, PK)
- user1_id (BigInteger, FK to users)
- user2_id (BigInteger, FK to users)
- last_message_at (DateTime)
- last_message_preview (String, nullable)
- created_at (DateTime)
- updated_at (DateTime)
- Unique constraint on (user1_id, user2_id)

# Message Model
- id (BigInteger, PK)
- conversation_id (BigInteger, FK to conversations)
- sender_id (BigInteger, FK to users)
- content (Text)
- message_type (String: 'text', 'image', 'location')
- is_read (Boolean, default=False)
- read_at (DateTime, nullable)
- created_at (DateTime)
- updated_at (DateTime)
- Index on (conversation_id, created_at)
- Index on (sender_id, created_at)
```

**Tasks:**
- [ ] Create `chat.py` model file
- [ ] Add models to `__init__.py`
- [ ] Create Alembic migration
- [ ] Run migration

---

### Phase 2: Backend API (REST Endpoints)

#### 2.1 Create Repository Layer

**File: `backend/app/repositories/chat_repository.py`**

**Methods:**
- `get_or_create_conversation(user1_id, user2_id)` - Get existing or create new conversation
- `get_user_conversations(user_id)` - Get all conversations for a user
- `get_conversation_by_id(conversation_id, user_id)` - Get conversation with validation
- `create_message(conversation_id, sender_id, content, message_type)` - Create new message
- `get_messages(conversation_id, limit, offset)` - Get message history with pagination
- `mark_messages_as_read(conversation_id, user_id)` - Mark messages as read
- `get_unread_count(user_id)` - Get total unread messages count

**Tasks:**
- [ ] Create repository file
- [ ] Implement all methods
- [ ] Add error handling

#### 2.2 Create Service Layer

**File: `backend/app/services/chat_service.py`**

**Methods:**
- `get_conversations(user_id)` - Get all conversations with last message preview
- `get_conversation(user_id, friend_id)` - Get or create conversation with friend
- `send_message(user_id, friend_id, content, message_type)` - Send message
- `get_messages(user_id, conversation_id, limit, offset)` - Get message history
- `mark_as_read(user_id, conversation_id)` - Mark conversation as read
- `get_unread_count(user_id)` - Get unread messages count

**Tasks:**
- [ ] Create service file
- [ ] Implement business logic
- [ ] Integrate with NotificationService for push notifications
- [ ] Add validation (friendship check, etc.)

#### 2.3 Create API Endpoints

**File: `backend/app/api/v1/chat.py`**

**Endpoints:**
- `GET /api/v1/chat/conversations` - List all conversations
- `GET /api/v1/chat/conversations/{friend_id}` - Get/create conversation with friend
- `POST /api/v1/chat/messages` - Send a message
- `GET /api/v1/chat/conversations/{conversation_id}/messages` - Get message history
- `PATCH /api/v1/chat/conversations/{conversation_id}/read` - Mark as read
- `GET /api/v1/chat/unread-count` - Get unread messages count

**Tasks:**
- [ ] Create API router
- [ ] Add authentication middleware
- [ ] Implement all endpoints
- [ ] Add request/response schemas
- [ ] Register router in `main.py`

#### 2.4 Create Pydantic Schemas

**File: `backend/app/schemas/chat.py`**

**Schemas:**
- `MessageCreate` - For creating messages
- `MessageResponse` - Message response format
- `ConversationResponse` - Conversation with last message
- `ConversationListResponse` - List of conversations
- `UnreadCountResponse` - Unread count

**Tasks:**
- [ ] Create schema file
- [ ] Define all schemas

---

### Phase 3: WebSocket Support (Real-time)

#### 3.1 WebSocket Endpoint

**File: `backend/app/api/v1/chat.py` (add WebSocket endpoint)**

**WebSocket:**
- `WS /api/v1/chat/ws/{conversation_id}` - Real-time message delivery

**Features:**
- Authenticate via query parameter token
- Broadcast messages to all connected clients in conversation
- Handle connection/disconnection
- Send typing indicators (optional)

**Tasks:**
- [ ] Add WebSocket endpoint
- [ ] Implement connection manager
- [ ] Add message broadcasting
- [ ] Handle authentication

#### 3.2 Connection Manager

**File: `backend/app/core/websocket_manager.py`**

**Features:**
- Track active WebSocket connections per user/conversation
- Broadcast messages to relevant connections
- Clean up disconnected clients

**Tasks:**
- [ ] Create connection manager
- [ ] Implement connection tracking
- [ ] Add broadcast functionality

---

### Phase 4: Frontend Implementation

#### 4.1 Chat Service (API Client)

**File: `mobile/lib/services/chat/chat_service.dart`**

**Methods:**
- `getConversations()` - Get all conversations
- `getConversation(friendId)` - Get conversation with friend
- `sendMessage(conversationId, content, messageType)` - Send message
- `getMessages(conversationId, limit, offset)` - Get message history
- `markAsRead(conversationId)` - Mark conversation as read
- `getUnreadCount()` - Get unread count

**Tasks:**
- [ ] Create service file
- [ ] Implement all methods
- [ ] Add error handling

#### 4.2 WebSocket Client

**File: `mobile/lib/services/chat/websocket_service.dart`**

**Features:**
- Connect to WebSocket endpoint
- Listen for incoming messages
- Send messages via WebSocket
- Handle reconnection logic
- Manage connection state

**Dependencies:**
- Add `web_socket_channel` package to `pubspec.yaml`

**Tasks:**
- [ ] Add `web_socket_channel: ^2.4.0` to dependencies
- [ ] Create WebSocket service
- [ ] Implement connection management
- [ ] Add message listeners

#### 4.3 Chat UI Components

**Files:**
- `mobile/lib/features/chat/widgets/conversation_list_item.dart` - Conversation list item
- `mobile/lib/features/chat/widgets/message_bubble.dart` - Individual message bubble
- `mobile/lib/features/chat/widgets/chat_input.dart` - Message input field
- `mobile/lib/features/chat/screens/conversation_list_screen.dart` - List of conversations
- `mobile/lib/features/chat/screens/chat_detail_screen.dart` - Individual chat screen

**Features:**
- Conversation list with last message preview
- Unread message indicators
- Message bubbles (sent/received)
- Message input with send button
- Real-time message updates
- Typing indicators (optional)
- Message timestamps
- Pull-to-refresh

**Tasks:**
- [ ] Create all UI components
- [ ] Implement state management (Provider)
- [ ] Add real-time updates
- [ ] Integrate with WebSocket service
- [ ] Add navigation from friends list

#### 4.4 Chat Provider (State Management)

**File: `mobile/lib/services/chat/chat_provider.dart`**

**Features:**
- Manage conversations list
- Manage current conversation messages
- Handle sending messages
- Handle receiving messages (WebSocket)
- Update unread counts
- Cache messages locally

**Tasks:**
- [ ] Create provider
- [ ] Implement state management
- [ ] Integrate with services

---

### Phase 5: Integration & Polish

#### 5.1 Navigation Integration

**Update:**
- `mobile/lib/features/friends/widgets/friend_options_bottom_sheet.dart` - Navigate to chat
- `mobile/lib/features/map/widgets/friend_info_popup.dart` - Navigate to chat
- `mobile/lib/features/map/widgets/friend_map_bottom_sheet.dart` - Navigate to chat

**Tasks:**
- [ ] Add navigation to chat from friend options
- [ ] Pass friend ID to chat screen

#### 5.2 FCM Integration

**Update: `backend/app/services/notification_service.py`**

**Features:**
- Send push notification when new message arrives
- Include message preview in notification
- Deep link to chat screen when notification tapped

**Tasks:**
- [ ] Add message notification method
- [ ] Integrate with chat service
- [ ] Update FCM payload for chat

#### 5.3 Badge/Unread Count

**Update: `mobile/lib/features/navigation/main_navigation_screen.dart`**

**Features:**
- Show unread message count badge on Chat tab
- Update badge in real-time

**Tasks:**
- [ ] Add badge widget
- [ ] Integrate with chat provider
- [ ] Update badge on message received

---

## Technical Considerations

### Database Indexing
- Index on `conversations(user1_id, user2_id)` for fast lookup
- Index on `messages(conversation_id, created_at)` for message history
- Index on `messages(sender_id, created_at)` for user message queries
- Index on `messages(is_read, conversation_id)` for unread queries

### Performance
- Paginate message history (load 50 messages at a time)
- Cache conversations list
- Lazy load message history
- Optimize WebSocket message payload size

### Security
- Verify friendship before allowing chat
- Authenticate WebSocket connections
- Validate message content
- Rate limit message sending

### Scalability
- WebSocket connection pooling
- Message queue for high traffic
- Database connection pooling
- Consider Redis for WebSocket state (future)

---

## Dependencies to Add

### Backend
- No new dependencies needed (FastAPI supports WebSockets natively)

### Frontend
```yaml
# Add to mobile/pubspec.yaml
dependencies:
  web_socket_channel: ^2.4.0  # For WebSocket support
```

---

## Testing Strategy

### Backend Tests
- [ ] Test conversation creation
- [ ] Test message sending
- [ ] Test message retrieval with pagination
- [ ] Test friendship validation
- [ ] Test WebSocket connection
- [ ] Test message broadcasting
- [ ] Test unread count

### Frontend Tests
- [ ] Test conversation list display
- [ ] Test message sending
- [ ] Test message receiving (WebSocket)
- [ ] Test offline handling
- [ ] Test navigation integration

---

## Estimated Timeline

- **Phase 1 (Database)**: 2-3 hours
- **Phase 2 (REST API)**: 4-6 hours
- **Phase 3 (WebSocket)**: 3-4 hours
- **Phase 4 (Frontend)**: 6-8 hours
- **Phase 5 (Integration)**: 2-3 hours

**Total: ~17-24 hours** (2-3 days of focused work)

---

## Alternative: Simplified Version (No WebSockets)

If WebSockets seem too complex, we can start with:

1. REST API only
2. Polling every 2-3 seconds when chat screen is open
3. FCM notifications for new messages
4. Add WebSockets later as enhancement

**Timeline: ~12-15 hours** (1.5-2 days)

---

## Next Steps

1. **Decide on approach**: Full WebSocket or Simplified REST + Polling?
2. **Start with Phase 1**: Database models and migration
3. **Iterate**: Build backend → Test → Build frontend → Test → Integrate

---

## Questions to Consider

1. **Message Types**: Do we need images, location sharing, or just text?
2. **Group Chats**: Should we support group conversations (future)?
3. **Message Deletion**: Can users delete their messages?
4. **Read Receipts**: Do we need "seen" indicators?
5. **Typing Indicators**: Show when friend is typing?
6. **Message Search**: Search within conversations?

---

**Last Updated**: December 12, 2025

