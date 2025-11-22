import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }
  
  static String get googleMapsApiKey => dotenv.env['GOOGLE_CLOUD_KEY'] ?? '';
  
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';
}

