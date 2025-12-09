# Android Notification Testing Guide

## ✅ What We Fixed

1. **Added POST_NOTIFICATIONS permission** to AndroidManifest.xml (required for Android 13+)
2. **Added runtime permission request** for Android 13+
3. **Created notification channel** properly
4. **Enhanced notification details** with sound and vibration

---

## 🧪 Testing Notifications

### Method 1: Test from Firebase Console (Easiest)

1. **Go to Firebase Console** → Your Project → Cloud Messaging
2. **Click "Send test message"**
3. **Enter your FCM token** (from database or Flutter logs)
4. **Add notification title and body**
5. **Click "Test"**

**Expected:**
- ✅ Notification appears on your device
- ✅ Sound plays (if enabled)
- ✅ Vibration (if enabled)

---

### Method 2: Test from Backend (Real Scenario)

1. **Make sure you're logged in** on the app
2. **Check FCM token is in database:**
   ```sql
   SELECT id, username, fcm_token FROM users WHERE id = YOUR_USER_ID;
   ```
3. **Trigger a notification** (e.g., send friend request, create meeting)
4. **Check backend logs** for:
   ```
   INFO: Sent friend request notification to user X
   ```

---

### Method 3: Manual Backend Test Script

Create a test script to send notification:

```python
# test_fcm.py
from app.core.firebase_admin import initialize_firebase, get_firebase_app
from app.services.fcm_client import FCMClient
from app.repositories.user_repository import UserRepository
from app.core.database import SessionLocal

# Initialize Firebase
initialize_firebase()

# Get user's FCM token from database
db = SessionLocal()
user_repo = UserRepository(db)
user = user_repo.get_by_id(1)  # Replace with your user ID

if user and user.fcm_token:
    fcm_client = FCMClient()
    success = fcm_client.send_notification(
        fcm_token=user.fcm_token,
        title="Test Notification",
        body="This is a test notification from backend"
    )
    print(f"Notification sent: {success}")
else:
    print("User not found or no FCM token")
```

Run it:
```bash
cd backend
source venv/bin/activate
python test_fcm.py
```

---

## 🔍 Troubleshooting

### Issue: No notification appears

**Check 1: Permission Status**
- Go to Android Settings → Apps → MeetUp → Notifications
- Make sure notifications are enabled
- Check if "Show notifications" is ON

**Check 2: Notification Channel**
- Android Settings → Apps → MeetUp → Notifications → MeetUp Notifications channel
- Make sure channel is enabled
- Check importance level (should be "High")

**Check 3: App State**
- **Foreground**: Should show notification (via local notifications)
- **Background**: Should show notification (via FCM)
- **Killed**: Should show notification (via FCM)

**Check 4: Flutter Logs**
Look for:
```
✅ Android notification permission granted
✅ Notification channel created: meetup_channel
✅ FCM token registered with backend successfully
```

**Check 5: Backend Logs**
Look for:
```
INFO: Firebase Admin SDK initialized successfully
INFO: Sent friend request notification to user X
```

**Check 6: FCM Token Validity**
- Token might be expired or invalid
- Try re-login to get a fresh token
- Check backend logs for "UnregisteredError"

---

### Issue: Permission dialog doesn't appear

**For Android 13+ (API 33+):**
- The permission request should appear automatically
- If it doesn't, check:
  - App is targeting Android 13+ (targetSdk >= 33)
  - Permission is in AndroidManifest.xml
  - Code is calling `requestNotificationsPermission()`

**For Android 12 and below:**
- Notifications are enabled by default
- No permission dialog needed

---

### Issue: Notification appears but no sound/vibration

**Check:**
1. Device is not in silent/Do Not Disturb mode
2. Notification channel settings allow sound
3. App notification settings allow sound
4. Channel importance is set to "High"

---

### Issue: Notification appears but tapping does nothing

**Check:**
- `_onNotificationTapped` method is implemented
- Navigation logic is correct
- App is handling the notification payload

---

## 📱 Device Settings to Check

1. **App Notifications**: Settings → Apps → MeetUp → Notifications → ON
2. **Notification Channel**: Settings → Apps → MeetUp → Notifications → MeetUp Notifications → Enabled, High importance
3. **Do Not Disturb**: Make sure DND is OFF
4. **Battery Optimization**: Settings → Apps → MeetUp → Battery → Unrestricted (optional, for background notifications)

---

## 🧪 Step-by-Step Test

1. **Clean install the app** (to ensure fresh permissions)
2. **Open the app** → Should see permission request (Android 13+)
3. **Grant permission** → Check logs for "permission granted"
4. **Login** → Check logs for "FCM token registered"
5. **Check database** → Verify token is stored
6. **Send test notification** from Firebase Console
7. **Verify notification appears**

---

## 🔧 Debug Commands

### Check notification permission (Android)
```bash
adb shell dumpsys notification | grep -A 10 "meetup_app"
```

### Check FCM token
```sql
SELECT id, username, LEFT(fcm_token, 30) as token_preview 
FROM users 
WHERE fcm_token IS NOT NULL;
```

### Test FCM directly
```bash
# Get your FCM token from database
# Then use Firebase Console or curl to test
```

---

## 💡 Common Mistakes

1. **Testing on emulator** - FCM may not work properly on emulators
2. **Wrong FCM token** - Using token from wrong user/device
3. **App in foreground** - Foreground notifications use local notifications, not FCM
4. **Permission not granted** - Check app settings
5. **Channel not created** - Check logs for channel creation
6. **Firebase not initialized** - Check backend logs

---

## ✅ Success Checklist

- [ ] POST_NOTIFICATIONS permission in AndroidManifest.xml
- [ ] Permission requested at runtime (Android 13+)
- [ ] Notification channel created
- [ ] FCM token stored in database
- [ ] Firebase Admin initialized in backend
- [ ] Notification appears when sent from Firebase Console
- [ ] Notification appears when triggered from app (friend request, etc.)
- [ ] Notification sound/vibration works
- [ ] Tapping notification navigates correctly

