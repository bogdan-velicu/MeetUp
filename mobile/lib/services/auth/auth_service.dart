import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../api/api_client.dart';

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
        
        return {'success': true, 'user': user, 'token': token};
      } else {
        return {'success': false, 'error': 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
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
}

