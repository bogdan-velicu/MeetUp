# Production Deployment Guide

This guide will help you deploy the MeetUp app for testing with friends over the internet.

## Prerequisites

- Router with DDNS configured: `zotrix.ddns.net`
- Backend server running on your local machine
- Port forwarding configured on your router

## Step 1: Port Forwarding Setup

You need to forward port **9000** (or your backend port) from your router to your local machine.

### Router Configuration:

1. **Access your router admin panel** (usually `192.168.1.1` or `192.168.0.1`)
2. **Navigate to Port Forwarding/Virtual Server settings**
3. **Add a new port forwarding rule:**
   - **Service Name**: MeetUp Backend
   - **External Port**: `9000`
   - **Internal IP**: Your computer's local IP (e.g., `192.168.1.143`)
   - **Internal Port**: `9000`
   - **Protocol**: TCP (or Both)
   - **Status**: Enabled

4. **Save the configuration**

### Verify Port Forwarding:

Test if the port is accessible from outside:
```bash
# From an external network (or use an online port checker)
curl http://zotrix.ddns.net:9000/health
```

You should see: `{"status":"healthy"}`

## Step 2: Backend Configuration

### Update CORS Settings

The backend is already configured to allow all origins (`CORS_ORIGINS: ["*"]`), which is fine for testing. For production, you should restrict this.

### Start Backend Server

Make sure your backend is running and accessible:
```bash
cd backend
uvicorn app.main:app --host 0.0.0.0 --port 9000 --reload
```

**Important**: Use `--host 0.0.0.0` to bind to all interfaces, not just localhost.

### Test Backend Access

From your phone (on mobile data, not WiFi), test:
```
http://zotrix.ddns.net:9000/health
```

## Step 3: Android Production Build

### Option A: Debug APK (Quick Testing)

For quick testing with friends, you can build a debug APK:

```bash
cd mobile
flutter build apk --debug
```

The APK will be at: `mobile/build/app/outputs/flutter-apk/app-debug.apk`

**Note**: Debug APKs are larger and not optimized, but work fine for testing.

### Option B: Release APK (Recommended)

For a production-ready APK:

1. **Create a keystore** (if you don't have one):
```bash
cd mobile/android
keytool -genkey -v -keystore meetup-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias meetup
```

2. **Create `mobile/android/key.properties`**:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=meetup
storeFile=../meetup-keystore.jks
```

3. **Update `mobile/android/app/build.gradle.kts`** to use the keystore (see below)

4. **Build the release APK**:
```bash
cd mobile
flutter build apk --release
```

The APK will be at: `mobile/build/app/outputs/flutter-apk/app-release.apk`

### Build App Bundle (for Google Play Store)

If you plan to publish:
```bash
flutter build appbundle --release
```

## Step 4: Install APK on Devices

### Transfer APK to Android Devices

1. **Option 1**: Email the APK to yourself and download on the device
2. **Option 2**: Use ADB:
```bash
adb install mobile/build/app/outputs/flutter-apk/app-release.apk
```
3. **Option 3**: Upload to Google Drive/Dropbox and share the link

### Enable Unknown Sources

On Android devices:
1. Go to **Settings** → **Security** (or **Apps** → **Special Access**)
2. Enable **Install Unknown Apps** (or **Unknown Sources**)
3. Select the app you'll use to install (Chrome, Files, etc.)

### Install the APK

1. Open the APK file on the device
2. Tap **Install**
3. Tap **Open** when done

## Step 5: Testing Checklist

### Backend Tests

- [ ] Backend accessible via `http://zotrix.ddns.net:9000/health`
- [ ] CORS allows requests from mobile app
- [ ] Database is accessible and running
- [ ] Firebase credentials are configured (for FCM)

### Mobile App Tests

- [ ] App installs successfully
- [ ] User can register/login
- [ ] Location services work
- [ ] Friends list loads
- [ ] Map view shows friends
- [ ] Meeting creation works
- [ ] Notifications work (FCM)
- [ ] Shake to MeetUp works

### Network Tests

- [ ] App connects to backend on mobile data
- [ ] App connects to backend on different WiFi networks
- [ ] Location updates work over internet
- [ ] Real-time features work (shake matching, etc.)

## Troubleshooting

### "Cannot connect to server"

1. **Check port forwarding**: Verify port 9000 is forwarded correctly
2. **Check firewall**: Ensure your computer's firewall allows port 9000
3. **Check backend**: Make sure backend is running with `--host 0.0.0.0`
4. **Test from external network**: Use mobile data to test, not local WiFi

### "Connection timeout"

- Backend might not be running
- Port forwarding might not be active
- Router might be blocking the connection
- Check if your ISP blocks incoming connections (some do)

### "CORS error"

- Verify `CORS_ORIGINS: ["*"]` in backend `.env`
- Check backend logs for CORS errors

### APK won't install

- Enable "Unknown Sources" in Android settings
- Check if device has enough storage
- Try downloading the APK again (might be corrupted)

## Security Notes

⚠️ **For Production Use:**

1. **Use HTTPS**: Set up SSL/TLS certificate (Let's Encrypt is free)
2. **Restrict CORS**: Don't use `["*"]`, specify your app's domain
3. **Use proper signing**: Always use release keystore for production
4. **Secure database**: Use strong passwords, limit access
5. **Environment variables**: Don't commit `.env` files with secrets
6. **Firewall rules**: Only open necessary ports

## Next Steps

- Set up SSL/HTTPS for secure connections
- Configure proper domain name (instead of DDNS)
- Set up monitoring and logging
- Create automated backups
- Set up CI/CD for deployments

