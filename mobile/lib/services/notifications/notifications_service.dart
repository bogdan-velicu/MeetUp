import '../api/api_client.dart';
import '../auth/auth_service.dart';

class NotificationsService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  Future<void> _ensureTokenIsSet() async {
    final token = await _authService.getToken();
    if (token != null) {
      _apiClient.setAuthToken(token);
    } else {
      throw Exception('User is not logged in - cannot register FCM token');
    }
  }

  /// Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  /// Register or update user's FCM token with the backend
  Future<void> registerFCMToken(String fcmToken) async {
    try {
      // Check if user is logged in first
      final isLoggedIn = await isUserLoggedIn();
      if (!isLoggedIn) {
        print('⚠️ Cannot register FCM token: User is not logged in');
        return;
      }

      await _ensureTokenIsSet();

      print('📤 Registering FCM token with backend...');
      final response = await _apiClient.post(
        '/notifications/token',
        data: {'fcm_token': fcmToken},
      );

      if (response.statusCode == 200) {
        print('✅ FCM token registered successfully');
        return;
      } else {
        throw Exception('Failed to register FCM token: ${response.statusMessage}');
      }
    } catch (e, stackTrace) {
      // Log error with details
      print('❌ Error registering FCM token: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

