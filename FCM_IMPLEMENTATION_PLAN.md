# FCM (Firebase Cloud Messaging) Implementation Plan

## Current Status

### ✅ Completed
- **Frontend FCM Setup**: 
  - Firebase initialized in `main.dart`
  - `FCMService` class created with token retrieval
  - Local notifications configured for foreground messages
  - Background message handler set up
  - Token refresh listener implemented

- **Backend Notification Service Structure**:
  - `NotificationService` class exists with placeholder methods
  - Methods for invitation notifications, response notifications, and meeting updates
  - Notification preferences structure defined

### ❌ Missing
- **FCM Token Storage**: No database field to store user FCM tokens
- **Token Registration API**: No endpoint to register/update FCM tokens from frontend
- **FCM SDK Integration**: Backend doesn't have Firebase Admin SDK installed/configured
- **Actual Notification Sending**: Methods only log, don't send real push notifications
- **Frontend Token Sync**: Frontend doesn't send tokens to backend

---

## Implementation Steps

### Step 1: Database Schema Update
**Goal**: Store FCM tokens per user

**Tasks**:
1. Add `fcm_token` field to `User` model (nullable String)
2. Create Alembic migration to add column
3. Run migration

**Files to modify**:
- `backend/app/models/user.py`
- Create new migration file

---

### Step 2: Backend FCM SDK Setup
**Goal**: Install and configure Firebase Admin SDK

**Tasks**:
1. Install `firebase-admin` package: `pip install firebase-admin`
2. Add to `requirements.txt`
3. Create Firebase Admin credentials file (or use environment variable)
4. Initialize Firebase Admin in backend startup
5. Create `FCMClient` helper class for sending notifications

**Files to create/modify**:
- `backend/requirements.txt`
- `backend/app/core/firebase_admin.py` (new)
- `backend/app/services/fcm_client.py` (new)
- `backend/app/main.py` (initialize Firebase Admin)

**Configuration needed**:
- Firebase project service account JSON key
- Store in secure location (environment variable or secure file)

---

### Step 3: FCM Token Registration API
**Goal**: Allow frontend to register/update FCM tokens

**Tasks**:
1. Create `POST /api/v1/notifications/token` endpoint
2. Accept FCM token in request body
3. Update user's `fcm_token` in database
4. Handle token updates (replace old token)

**Files to create/modify**:
- `backend/app/api/v1/notifications.py` (new router)
- `backend/app/schemas/notification.py` (new - for request/response schemas)
- `backend/app/main.py` (register router)

**Endpoint structure**:
```python
POST /api/v1/notifications/token
Body: { "fcm_token": "string" }
Response: { "success": true, "message": "Token registered" }
```

---

### Step 4: Implement FCM Sending in NotificationService
**Goal**: Replace placeholder methods with actual FCM sending

**Tasks**:
1. Update `NotificationService` to use `FCMClient`
2. Implement `send_invitation_notification()`:
   - Get recipient's FCM token
   - Check notification preferences
   - Send push notification with meeting details
3. Implement `send_invitation_response_notification()`:
   - Get organizer's FCM token
   - Send notification about acceptance/decline
4. Implement `send_meeting_update_notification()`:
   - Get all participants' FCM tokens
   - Send notification about meeting changes
5. Handle errors gracefully (invalid tokens, etc.)

**Files to modify**:
- `backend/app/services/notification_service.py`
- `backend/app/services/fcm_client.py` (create helper methods)

**Notification payload structure**:
```json
{
  "notification": {
    "title": "New Meeting Invitation",
    "body": "Alice invited you to 'Coffee Meetup'"
  },
  "data": {
    "type": "meeting_invitation",
    "meeting_id": "123",
    "action": "view_invitation"
  }
}
```

---

### Step 5: Wire Up Notification Triggers
**Goal**: Call notification methods when events happen

**Tasks**:
1. In `MeetingsService.create_meeting()`:
   - After creating invitations, call `send_invitation_notification()` for each participant
2. In `InvitationsService.accept_invitation()`:
   - After accepting, call `send_invitation_response_notification()` to organizer
3. In `InvitationsService.decline_invitation()`:
   - After declining, call `send_invitation_response_notification()` to organizer
4. In `MeetingsService.update_meeting()`:
   - After updating, call `send_meeting_update_notification()` to all participants
5. In `MeetingsService.delete_meeting()`:
   - After deleting, call `send_meeting_update_notification()` with "cancelled" type

**Files to modify**:
- `backend/app/services/meetings_service.py`
- `backend/app/services/invitations_service.py`

---

### Step 6: Frontend Token Registration
**Goal**: Send FCM tokens to backend when app starts/logs in

**Tasks**:
1. Create `NotificationsService` in Flutter
2. Add method to register FCM token with backend
3. Call registration after:
   - User logs in
   - FCM token is obtained
   - FCM token is refreshed
4. Handle errors (network failures, etc.)

**Files to create/modify**:
- `mobile/lib/services/notifications/notifications_service.dart` (new)
- `mobile/lib/services/notifications/fcm_service.dart` (update to call registration)
- `mobile/lib/services/auth/auth_service.dart` (call token registration after login)

**API call**:
```dart
POST /api/v1/notifications/token
Headers: { Authorization: Bearer <token> }
Body: { "fcm_token": "<fcm_token>" }
```

---

### Step 7: Notification Handling & Navigation
**Goal**: Handle notification taps and navigate to appropriate screens

**Tasks**:
1. Update `FCMService._onNotificationTapped()`:
   - Parse notification payload
   - Navigate based on `data.type`:
     - `meeting_invitation` → Navigate to invitations list or specific invitation
     - `invitation_response` → Navigate to meeting details
     - `meeting_update` → Navigate to meeting details
2. Update background message handler to handle deep links
3. Test navigation from notifications

**Files to modify**:
- `mobile/lib/services/notifications/fcm_service.dart`
- `mobile/lib/main.dart` (background handler)

---

### Step 8: Notification Preferences (Optional Enhancement)
**Goal**: Allow users to control notification settings

**Tasks**:
1. Add notification preferences fields to User model (or separate table)
2. Create API endpoints:
   - `GET /api/v1/notifications/preferences`
   - `PATCH /api/v1/notifications/preferences`
3. Create UI in Profile screen for notification settings
4. Respect preferences when sending notifications

**Files to create/modify**:
- `backend/app/models/user.py` or new `NotificationPreferences` model
- `backend/app/api/v1/notifications.py` (add endpoints)
- `mobile/lib/features/profile/notification_settings_screen.dart` (new)

---

## Testing Checklist

- [ ] FCM token is stored in database after registration
- [ ] Token is updated when user logs in on new device
- [ ] Push notification received when invitation is created
- [ ] Push notification received when invitation is accepted/declined
- [ ] Push notification received when meeting is updated
- [ ] Push notification received when meeting is cancelled
- [ ] Notification tap navigates to correct screen
- [ ] Foreground notifications display correctly
- [ ] Background notifications display correctly
- [ ] Token refresh updates backend
- [ ] Invalid tokens are handled gracefully
- [ ] Notification preferences are respected

---

## Dependencies

### Backend
- `firebase-admin` (Python package)
- Firebase project service account credentials

### Frontend
- Already configured: `firebase_core`, `firebase_messaging`, `flutter_local_notifications`

---

## Security Considerations

1. **FCM Token Storage**: Tokens should be stored securely, but they're not sensitive (can't be used to send notifications without Firebase credentials)
2. **Service Account Key**: Must be kept secure, use environment variables or secure file storage
3. **Token Validation**: Validate tokens before storing (format check)
4. **Rate Limiting**: Consider rate limiting on token registration endpoint

---

## Estimated Time

- **Step 1**: 15 minutes (database migration)
- **Step 2**: 30 minutes (Firebase Admin setup)
- **Step 3**: 30 minutes (API endpoint)
- **Step 4**: 1-2 hours (FCM sending implementation)
- **Step 5**: 30 minutes (wire up triggers)
- **Step 6**: 30 minutes (frontend token registration)
- **Step 7**: 1 hour (notification handling)
- **Step 8**: 1-2 hours (preferences - optional)

**Total**: ~5-7 hours for core implementation, +2-3 hours for preferences

---

## Next Steps After FCM

1. **Notification History**: Store sent notifications in database
2. **Notification Badges**: Show unread notification count
3. **In-App Notifications**: Display notifications in app (not just push)
4. **Notification Groups**: Group related notifications (e.g., multiple meeting invitations)
5. **Rich Notifications**: Add images, action buttons to notifications

