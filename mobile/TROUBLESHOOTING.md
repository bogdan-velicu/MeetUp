# Troubleshooting Guide

## Android v1 Embedding Error

If you get "Build failed due to use of deleted Android v1 embedding":

1. **Verify MainActivity**: Should extend `FlutterActivity` (v2 embedding)
   - File: `android/app/src/main/kotlin/com/meetup/meetup_app/MainActivity.kt`
   - Should be: `class MainActivity : FlutterActivity()`

2. **Check AndroidManifest.xml**:
   - `flutterEmbedding` should be set to `"2"`
   - Location: `android/app/src/main/AndroidManifest.xml`

3. **Clean and Rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Check GeneratedPluginRegistrant**:
   - Should use `FlutterEngine` (v2 embedding)
   - File: `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
   - This file is auto-generated, but if it has issues, clean and rebuild

5. **Firebase Configuration**:
   - Ensure `google-services.json` is in `android/app/` directory
   - Google Services plugin should be in `build.gradle.kts` files

6. **If issue persists**:
   - Check if any plugin is outdated: `flutter pub outdated`
   - Update Flutter: `flutter upgrade`
   - Check plugin compatibility with Flutter version

