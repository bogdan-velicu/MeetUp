import 'package:dio/dio.dart';
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
    // Always use AppConstants.baseUrl for production builds
    // This ensures consistent behavior and avoids .env file issues
    final baseUrl = AppConstants.baseUrl;
    final fullBaseUrl = '$baseUrl${AppConstants.apiVersion}';
    
    // Debug: Log the API URL being used (remove in production if needed)
    print('🌐 API Base URL: $fullBaseUrl');
    
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

