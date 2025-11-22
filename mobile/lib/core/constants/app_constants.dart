class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://192.168.1.143:8000';
  static const String apiVersion = '/api/v1';

  // App Info
  static const String appName = 'MeetUp!';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  // Location
  static const int defaultLocationUpdateInterval = 15; // minutes
  static const List<int> locationUpdateIntervals = [5, 15, 30, 0]; // 0 = manual
}
