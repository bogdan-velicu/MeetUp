import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class ApiClient {
  late final Dio _dio;
  static ApiClient? _instance;
  
  // Singleton pattern
  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }
  
  ApiClient._internal() {
    _initializeDioSync();
  }
  
  void _initializeDioSync() {
    // Start with default URL, will be updated async if custom URL exists
    final baseUrl = AppConstants.baseUrl;
    final fullBaseUrl = '$baseUrl${AppConstants.apiVersion}';
    
    _dio = Dio(BaseOptions(
      baseUrl: fullBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors for auth token, logging, etc.
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
    
    // Load custom URL asynchronously and update if needed
    _loadCustomUrl();
  }
  
  Future<void> _loadCustomUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString(AppConstants.customBackendUrlKey);
      if (customUrl != null && customUrl.isNotEmpty) {
        final fullBaseUrl = '$customUrl${AppConstants.apiVersion}';
        _dio.options.baseUrl = fullBaseUrl;
        print('🔧 Using custom backend URL: $customUrl');
      } else {
        print('🌐 Using default backend URL: ${AppConstants.baseUrl}');
      }
    } catch (e) {
      print('⚠️ Error loading custom URL: $e');
    }
  }
  
  // Reinitialize Dio with new base URL
  Future<void> updateBaseUrl(String? customUrl) async {
    final prefs = await SharedPreferences.getInstance();
    if (customUrl != null && customUrl.isNotEmpty) {
      // Validate URL format
      if (!customUrl.startsWith('http://') && !customUrl.startsWith('https://')) {
        throw Exception('URL must start with http:// or https://');
      }
      await prefs.setString(AppConstants.customBackendUrlKey, customUrl);
    } else {
      await prefs.remove(AppConstants.customBackendUrlKey);
    }
    
    // Update Dio base URL
    final baseUrl = customUrl ?? AppConstants.baseUrl;
    final fullBaseUrl = '$baseUrl${AppConstants.apiVersion}';
    _dio.options.baseUrl = fullBaseUrl;
    
    print('🌐 API Base URL updated to: $fullBaseUrl');
    
    // Preserve auth token if it exists
    final token = await _getStoredToken();
    if (token != null) {
      setAuthToken(token);
    }
  }
  
  Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }
  
  // Get current base URL (for display)
  Future<String> getCurrentBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(AppConstants.customBackendUrlKey);
    return customUrl ?? AppConstants.baseUrl;
  }
  
  Dio get dio => _dio;
  
  // Helper methods for common operations
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }
  
  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }
  
  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }
  
  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }
  
  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
  
  // Set auth token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  // Clear auth token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}

