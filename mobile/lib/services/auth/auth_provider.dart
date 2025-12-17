import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../location/location_update_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  Map<String, dynamic>? _currentUser;
  String? _error;
  
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get error => _error;
  
  AuthProvider() {
    _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        
        // Start location updates if user is already authenticated
        try {
          await locationUpdateService.startLocationUpdates();
        } catch (e) {
          debugPrint('Failed to start location updates on auth check: $e');
        }
      } else {
        // Token might be invalid, clear it
        await _authService.logout();
        _isAuthenticated = false;
      }
    } else {
      _isAuthenticated = false;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    final result = await _authService.login(email: email, password: password);
    
    _isLoading = false;
    
    if (result['success'] == true) {
      _currentUser = result['user'];
      _isAuthenticated = true;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result['error'] ?? 'Login failed';
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    final result = await _authService.register(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
    
    _isLoading = false;
    
    if (result['success'] == true) {
      _currentUser = result['user'];
      _isAuthenticated = true;
      _error = null;
      notifyListeners();
      
      // Start location updates after successful registration
      try {
        await locationUpdateService.startLocationUpdates();
      } catch (e) {
        debugPrint('Failed to start location updates after registration: $e');
      }
      
      return true;
    } else {
      _error = result['error'] ?? 'Registration failed';
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    // Stop location updates before logout
    locationUpdateService.stopLocationUpdates();
    
    await _authService.logout();
    _isAuthenticated = false;
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
  
  Future<void> refreshUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }
  
  // Enable demo mode - bypass login with demo user
  Future<bool> enableDemoMode() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    final result = await _authService.enableDemoMode();
    
    _isLoading = false;
    
    if (result['success'] == true) {
      _currentUser = result['user'];
      _isAuthenticated = true;
      _error = null;
      notifyListeners();
      
      // Note: We skip location updates in demo mode to avoid errors
      
      return true;
    } else {
      _error = result['error'] ?? 'Failed to enable demo mode';
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }
}

