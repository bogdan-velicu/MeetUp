class AppConstants {
  // API Configuration
  // Production: Use DDNS for external access
  static const String baseUrl = 'http://zotrix.ddns.net:9000';
  // For local testing, use: 'http://192.168.1.143:9000'
  static const String apiVersion = '/api/v1';

  // App Info
  static const String appName = 'MeetUp!';
  static const String appVersion = '1.0.4';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  // Location
  static const int defaultLocationUpdateInterval = 15; // minutes
  static const List<int> locationUpdateIntervals = [5, 15, 30, 0]; // 0 = manual
}
