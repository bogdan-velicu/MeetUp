import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }
  
  static String get googleMapsApiKey => dotenv.env['GOOGLE_CLOUD_KEY'] ?? '';
  
  static String get apiBaseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url != null && url.isNotEmpty) {
      return url;
    }
    // Fallback - you can change this to your computer's IP for testing
    return 'http://192.168.1.143:8000';
  }
}

