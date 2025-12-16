import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static bool _loaded = false;
  
  static Future<void> load() async {
    if (_loaded) return;
    try {
      await dotenv.load(fileName: ".env");
      _loaded = true;
    } catch (e) {
      // .env file not found or error loading - that's okay for production
      // We'll use AppConstants.baseUrl instead
      _loaded = true;
    }
  }
  
  static String get googleMapsApiKey => dotenv.env['GOOGLE_CLOUD_KEY'] ?? '';
  
  // Note: API base URL is now always taken from AppConstants.baseUrl
  // This ensures production builds use the correct DDNS URL
  // and avoids issues with .env files containing old IPs
}

