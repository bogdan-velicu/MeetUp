import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../api/api_client.dart';
import '../notifications/fcm_service.dart';
import '../notifications/notifications_service.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  
  // Expose apiClient for token initialization
  ApiClient get apiClient => _apiClient;
  
  // Store tokens
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    _apiClient.setAuthToken(token);
  }
  
  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }
  
  // Clear tokens
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userIdKey);
    _apiClient.clearAuthToken();
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  // Register user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _apiClient.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      });
      
      if (response.statusCode == 201) {
        final data = response.data;
        final token = data['token']['access_token'];
        final user = data['user'];
        
        // Save token and user ID
        await saveToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(AppConstants.userIdKey, user['id']);
        
        // Register FCM token after successful registration
        try {
          final fcmService = FCMService();
          final fcmToken = await fcmService.getToken();
          if (fcmToken != null) {
            final notificationsService = NotificationsService();
            await notificationsService.registerFCMToken(fcmToken);
          }
        } catch (e) {
          // Log but don't fail registration if FCM registration fails
          print('Warning: Failed to register FCM token after registration: $e');
        }
        
        return {'success': true, 'user': user, 'token': token};
      } else {
        return {'success': false, 'error': 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Login user (accepts email or username)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Determine if identifier is email or username
      final isEmail = email.contains('@');
      final data = {
        'password': password,
      };
      
      if (isEmail) {
        data['email'] = email;
      } else {
        data['username'] = email;
      }
      
      final response = await _apiClient.post('/auth/login', data: data);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token']['access_token'];
        final user = data['user'];
        
        // Save token and user ID
        await saveToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(AppConstants.userIdKey, user['id']);
        
        return {'success': true, 'user': user, 'token': token};
      } else {
        return {'success': false, 'error': 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      
      _apiClient.setAuthToken(token);
      final response = await _apiClient.get('/auth/me');
      
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Logout
  Future<void> logout() async {
    await clearTokens();
  }
  
  // Demo mode - bypass login with demo user data
  Future<Map<String, dynamic>> enableDemoMode() async {
    // Create demo user data with arbitrary values
    final demoUser = {
      'id': 999,
      'username': 'demo_user',
      'email': 'demo@meetup.app',
      'full_name': 'Demo User',
      'phone_number': '+1234567890',
      'profile_photo_url': null,
      'points': 150,
      'is_demo': true,
    };
    
    // Save a demo token (just a placeholder string)
    final demoToken = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
    await saveToken(demoToken);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.userIdKey, demoUser['id'] as int);
    
    return {'success': true, 'user': demoUser, 'token': demoToken};
  }
}

