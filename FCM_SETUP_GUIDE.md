# FCM Setup Guide

## ✅ Code Implementation Complete!

All the code for FCM notifications has been implemented. Now you need to complete the Firebase setup.

---

## 🔧 Your Setup Tasks

### 1. Get Firebase Service Account Credentials

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Click the **⚙️ Settings** icon → **Project settings**
4. Go to the **Service accounts** tab
5. Click **Generate new private key**
6. Save the downloaded JSON file securely

**Recommended location**: `backend/firebase-service-account.json`

**⚠️ Important**: Add this file to `.gitignore` to keep it secure!

---

### 2. Configure Environment Variables

Add to your `backend/.env` file:

```bash
# Firebase Configuration
FIREBASE_CREDENTIALS_PATH=backend/firebase-service-account.json
FIREBASE_PROJECT_ID=your-project-id  # Optional, can be extracted from JSON
```

**Note**: Use the **absolute path** or **relative path from where you run the backend**.

---

### 3. Install Backend Dependencies

```bash
cd backend
source venv/bin/activate  # or activate your virtual environment
pip install -r requirements.txt
```

This will install `firebase-admin>=6.3.0`.

---

### 4. Run Database Migration

```bash
cd backend
source venv/bin/activate
alembic upgrade head
```

This adds the `fcm_token` column to the `users` table.

---

### 5. Test the Setup

1. **Start the backend server**
2. **Start the mobile app**
3. **Login** - The FCM token should be automatically registered
4. **Create a meeting** - Invited users should receive push notifications
5. **Accept/decline invitation** - Organizer should receive notification

---

## 📱 How It Works

### Frontend Flow:
1. App starts → FCM service initializes
2. FCM token is obtained
3. Token is automatically sent to backend via `POST /api/v1/notifications/token`
4. Token is stored in user's database record
5. When token refreshes, it's automatically updated

### Backend Flow:
1. When meeting is created → Notification sent to all participants
2. When invitation is accepted/declined → Notification sent to organizer
3. When meeting is updated → Notification sent to all participants
4. When meeting is cancelled → Notification sent to all participants

---

## 🧪 Testing Checklist

- [ ] Backend starts without Firebase errors (check logs)
- [ ] FCM token is stored in database after login
- [ ] Push notification received when invitation is created
- [ ] Push notification received when invitation is accepted
- [ ] Push notification received when invitation is declined
- [ ] Push notification received when meeting is updated
- [ ] Push notification received when meeting is cancelled

---

## 🐛 Troubleshooting

### Backend: "Firebase not initialized"
- Check that `FIREBASE_CREDENTIALS_PATH` is set correctly
- Verify the JSON file exists at that path
- Check file permissions (should be readable)

### Backend: "Invalid credentials"
- Verify the service account JSON is valid
- Make sure you downloaded the correct file
- Check that the JSON hasn't been corrupted

### Frontend: "Failed to register FCM token"
- Check that user is logged in (token registration requires auth)
- Verify backend `/api/v1/notifications/token` endpoint is accessible
- Check network connectivity

### No notifications received
- Verify FCM token is stored in database: `SELECT fcm_token FROM users WHERE id = ?`
- Check backend logs for notification sending errors
- Verify Firebase project is correctly configured
- Check device notification permissions

---

## 📝 Files Modified/Created

### Backend:
- ✅ `backend/app/models/user.py` - Added `fcm_token` field
- ✅ `backend/app/core/config.py` - Added Firebase config
- ✅ `backend/app/core/firebase_admin.py` - Firebase initialization
- ✅ `backend/app/services/fcm_client.py` - FCM sending logic
- ✅ `backend/app/services/notification_service.py` - Notification service with FCM
- ✅ `backend/app/api/v1/notifications.py` - Token registration endpoint
- ✅ `backend/app/services/meetings_service.py` - Notification triggers
- ✅ `backend/app/services/invitations_service.py` - Notification triggers
- ✅ Migration: `add_fcm_token_to_users`

### Frontend:
- ✅ `mobile/lib/services/notifications/notifications_service.dart` - Token registration
- ✅ `mobile/lib/services/notifications/fcm_service.dart` - Auto-register tokens

---

## 🎉 Next Steps

Once setup is complete:
1. Test with two devices/users
2. Create a meeting and verify notifications
3. Accept/decline invitations and verify notifications
4. Update meetings and verify notifications

All done! 🚀

