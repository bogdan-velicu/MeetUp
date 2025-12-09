# FCM Token Registration Debugging Guide

## 🔍 How to Check if FCM Tokens Are Being Registered

### Step 1: Check Flutter Console Logs

When the app starts, you should see:
```
FCM Token obtained: [first 20 chars]...
✅ FCM token registered with backend successfully
```

**OR if user is not logged in:**
```
FCM Token obtained: [first 20 chars]...
⚠️ User not logged in, FCM token will be registered after login
```

**OR if there's an error:**
```
❌ Failed to register FCM token with backend: [error message]
```

### Step 2: Check Backend Logs

When a token registration request comes in, you should see:
```
INFO: POST /api/v1/notifications/token - 200 OK
```

**OR if there's an error:**
```
ERROR: POST /api/v1/notifications/token - 401 Unauthorized
```

### Step 3: Check Database

```sql
-- Check if FCM tokens are stored
SELECT id, username, email, fcm_token 
FROM users 
WHERE fcm_token IS NOT NULL;

-- Check specific user
SELECT id, username, email, fcm_token 
FROM users 
WHERE id = 1;  -- Replace with your user ID
```

### Step 4: Test Token Registration Manually

**Using curl:**
```bash
# Get your auth token first (from app logs or login)
TOKEN="your_jwt_token_here"
FCM_TOKEN="your_fcm_token_from_flutter_logs"

curl -X POST http://localhost:8000/api/v1/notifications/token \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"fcm_token\": \"$FCM_TOKEN\"}"
```

**Expected response:**
```json
{
  "success": true,
  "message": "FCM token registered successfully"
}
```

---

## 🐛 Common Issues & Solutions

### Issue 1: "User is not logged in" Warning

**Symptom:**
```
⚠️ User not logged in, FCM token will be registered after login
```

**Solution:**
- This is normal if you start the app before logging in
- Token will be registered automatically after you log in
- Check logs after login to confirm registration

---

### Issue 2: "FCM token is null"

**Symptom:**
```
⚠️ FCM token is null - Firebase might not be properly configured
```

**Possible Causes:**
1. **Firebase not initialized properly**
   - Check `google-services.json` exists in `android/app/`
   - Check `GoogleService-Info.plist` exists in `ios/Runner/`
   - Verify Firebase project is set up correctly

2. **Missing Firebase configuration**
   - Make sure Firebase is initialized in `main.dart`
   - Check for Firebase initialization errors in logs

3. **Device/Emulator issues**
   - Real device: Check Google Play Services is installed
   - Emulator: May not support FCM properly

**Solution:**
- Check Firebase setup in Firebase Console
- Verify `google-services.json` is correct
- Try on a real device instead of emulator

---

### Issue 3: "401 Unauthorized" Error

**Symptom:**
```
❌ Failed to register FCM token with backend: 401 Unauthorized
```

**Possible Causes:**
1. Auth token expired
2. Auth token not set properly
3. User logged out

**Solution:**
- Re-login to get fresh token
- Check that `AuthService.getToken()` returns a valid token
- Verify token is being set in `ApiClient`

---

### Issue 4: "Firebase credentials file not found"

**Symptom (Backend logs):**
```
WARNING: Firebase credentials file not found at [path]. FCM notifications will not work.
```

**Solution:**
1. Check `.env` file has correct path:
   ```bash
   FIREBASE_CREDENTIALS_PATH=backend/firebase-service-account.json
   ```
2. Verify file exists at that path
3. Check file permissions (should be readable)

---

### Issue 5: "Firebase Admin SDK initialization failed"

**Symptom (Backend logs):**
```
ERROR: Failed to initialize Firebase Admin SDK: [error]
```

**Possible Causes:**
1. Invalid service account JSON
2. Wrong file path
3. Missing Firebase Admin package

**Solution:**
1. Re-download service account JSON from Firebase Console
2. Verify JSON file is valid (not corrupted)
3. Check `pip install firebase-admin` was successful
4. Verify path in `.env` is correct

---

## ✅ Verification Checklist

- [ ] Flutter logs show "FCM Token obtained"
- [ ] Flutter logs show "FCM token registered with backend successfully" (after login)
- [ ] Backend logs show successful POST to `/api/v1/notifications/token`
- [ ] Database query shows `fcm_token` is NOT NULL for logged-in users
- [ ] No Firebase initialization errors in backend logs
- [ ] No 401 errors when registering token

---

## 🧪 Manual Testing Steps

1. **Start the app** (not logged in)
   - Should see: "User not logged in" warning (this is OK)

2. **Login to the app**
   - Should see: "FCM token registered with backend successfully"

3. **Check database:**
   ```sql
   SELECT id, username, fcm_token FROM users WHERE id = YOUR_USER_ID;
   ```
   - `fcm_token` should NOT be NULL

4. **Check backend logs:**
   - Should see successful POST request

5. **Test notification:**
   - Send friend request from another user
   - Should receive push notification

---

## 📝 Debug Commands

### Check if Firebase is initialized (Backend)
```python
# In Python shell or add to a test endpoint
from app.core.firebase_admin import get_firebase_app
app = get_firebase_app()
print("Firebase app:", app)
```

### Check FCM token in database
```sql
SELECT id, username, LEFT(fcm_token, 20) as token_preview 
FROM users 
WHERE fcm_token IS NOT NULL;
```

### Check backend environment
```bash
cd backend
source venv/bin/activate
python -c "from app.core.config import settings; print('FIREBASE_CREDENTIALS_PATH:', settings.FIREBASE_CREDENTIALS_PATH)"
```

---

## 🚨 If Still Not Working

1. **Check Firebase Console:**
   - Verify project is active
   - Check Cloud Messaging API is enabled
   - Verify service account has proper permissions

2. **Check Google Cloud Console:**
   - Go to IAM & Admin → Service Accounts
   - Verify service account exists
   - Check it has "Firebase Cloud Messaging API" enabled

3. **Test Firebase Admin directly:**
   ```python
   import firebase_admin
   from firebase_admin import credentials, messaging
   
   cred = credentials.Certificate("path/to/service-account.json")
   app = firebase_admin.initialize_app(cred)
   
   # Try sending a test message
   message = messaging.Message(
       notification=messaging.Notification(
           title="Test",
           body="Test message"
       ),
       token="your_fcm_token_here"
   )
   response = messaging.send(message)
   print("Success:", response)
   ```

---

## 💡 Pro Tips

1. **Always check logs in order:**
   - Flutter console first (frontend)
   - Backend console second (API)
   - Database third (storage)

2. **Token registration happens:**
   - On app start (if logged in)
   - After login
   - On token refresh

3. **If token is NULL in database:**
   - Check Flutter logs for errors
   - Verify user is logged in
   - Check backend endpoint is accessible
   - Verify Firebase is configured correctly

