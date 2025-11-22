# Google Maps & Firebase Setup

## Google Maps API Key Configuration

The Google Maps API key needs to be added to the AndroidManifest.xml file.

1. Open `android/app/src/main/AndroidManifest.xml`
2. Find the line with `YOUR_GOOGLE_MAPS_API_KEY`
3. Replace it with your actual API key from `.env` file

**Note**: The API key from `.env` is loaded at runtime, but Android requires it in the manifest for Google Maps to work. You can either:
- Manually update the manifest with your key
- Or use a build script to inject it during build

## Current Setup

- `.env` file contains `GOOGLE_CLOUD_KEY` (loaded at runtime)
- AndroidManifest.xml needs the key for Google Maps SDK
- The key should have access to:
  - Android Maps SDK
  - Firebase Cloud Messaging (FCM)

## Firebase Setup

1. Make sure you have `google-services.json` in `android/app/` directory
2. Add Firebase plugin to `android/build.gradle`:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```
3. Apply plugin in `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

## Testing

After setup, you can test:
- Google Maps should display in MapViewWidget
- FCM notifications should work
- Location services should request permissions

