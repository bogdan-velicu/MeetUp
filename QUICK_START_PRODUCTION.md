# Quick Start: Production Testing

## ✅ What's Done

1. **API URL Updated**: App now points to `http://zotrix.ddns.net:9000`
2. **APK Built**: Production APK ready at:
   ```
   mobile/build/app/outputs/flutter-apk/app-release.apk
   ```
   Size: ~28.8 MB

## 🔧 What You Need to Do

### 1. Port Forwarding (5 minutes)

**On your router admin panel:**

1. Go to **Port Forwarding** / **Virtual Server** settings
2. Add rule:
   - **External Port**: `9000`
   - **Internal IP**: Your computer's local IP (check with `ip addr` or `ifconfig`)
   - **Internal Port**: `9000`
   - **Protocol**: TCP
3. **Save**

**Test it:**
```bash
# From your phone (on mobile data, not WiFi):
curl http://zotrix.ddns.net:9000/health
```

Should return: `{"status":"healthy"}`

### 2. Start Backend (Important!)

```bash
cd backend
uvicorn app.main:app --host 0.0.0.0 --port 9000 --reload
```

**⚠️ Use `--host 0.0.0.0`** (not `127.0.0.1`) so it accepts external connections!

### 3. Share APK with Friends

**Option A: Email**
- Email `app-release.apk` to yourself
- Download on phone and install

**Option B: Cloud Storage**
- Upload to Google Drive/Dropbox
- Share link with friends

**Option C: Direct Transfer**
- Use ADB: `adb install mobile/build/app/outputs/flutter-apk/app-release.apk`
- Or transfer via USB/Bluetooth

### 4. Install on Android Devices

1. **Enable "Install Unknown Apps"**:
   - Settings → Security → Install Unknown Apps
   - Enable for your file manager/browser

2. **Open the APK file** and tap **Install**

3. **Open the app** and test!

## 🧪 Testing Checklist

- [ ] Backend accessible via `http://zotrix.ddns.net:9000/health`
- [ ] App installs on device
- [ ] User can register/login
- [ ] Location services work
- [ ] Friends list loads
- [ ] Map shows friends
- [ ] Meetings work
- [ ] Notifications work (FCM)
- [ ] Shake to MeetUp works

## 🐛 Troubleshooting

**"Cannot connect to server"**
- Check port forwarding is active
- Verify backend is running with `--host 0.0.0.0`
- Test from mobile data (not local WiFi)
- Check firewall allows port 9000

**"Connection timeout"**
- Backend might not be running
- Port forwarding might not be configured
- Router might be blocking connections

**APK won't install**
- Enable "Unknown Sources" in Android settings
- Check device has enough storage
- Try downloading APK again

## 📱 APK Location

```
/home/bogdan/Projects/MeetUp/mobile/build/app/outputs/flutter-apk/app-release.apk
```

## 🔄 Rebuild APK (if you make changes)

```bash
cd mobile
flutter build apk --release
```

## 📝 Notes

- **For production**: Consider setting up HTTPS (Let's Encrypt)
- **Security**: Current CORS allows all origins (`*`) - restrict for production
- **Signing**: Currently using debug keys - create proper keystore for production

