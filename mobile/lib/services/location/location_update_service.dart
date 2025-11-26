import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../api/api_client.dart';
import '../auth/auth_service.dart';
import 'location_service.dart';

class LocationUpdateService {
  final LocationService _locationService = LocationService();
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();
  
  // Ensure auth token is set before making requests
  Future<void> _ensureTokenIsSet() async {
    final token = await _authService.getToken();
    if (token != null) {
      _apiClient.setAuthToken(token);
    }
  }
  
  StreamSubscription<Position>? _locationSubscription;
  Timer? _updateTimer;
  bool _isUpdating = false;
  
  // Settings
  int _updateIntervalSeconds = 30; // Default: 30 seconds
  int _distanceFilterMeters = 10; // Default: 10 meters
  bool _backgroundUpdatesEnabled = true;
  
  // Getters for settings
  int get updateIntervalSeconds => _updateIntervalSeconds;
  int get distanceFilterMeters => _distanceFilterMeters;
  bool get backgroundUpdatesEnabled => _backgroundUpdatesEnabled;
  bool get isUpdating => _isUpdating;

  // Update settings
  void updateSettings({
    int? intervalSeconds,
    int? distanceFilter,
    bool? backgroundEnabled,
  }) {
    if (intervalSeconds != null) _updateIntervalSeconds = intervalSeconds;
    if (distanceFilter != null) _distanceFilterMeters = distanceFilter;
    if (backgroundEnabled != null) _backgroundUpdatesEnabled = backgroundEnabled;
    
    // Restart location updates with new settings if currently running
    if (_isUpdating) {
      stopLocationUpdates();
      startLocationUpdates();
    }
  }

  // Start continuous location updates
  Future<void> startLocationUpdates() async {
    if (_isUpdating) return;

    try {
      // Check if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('User not logged in');
      }

      // Set auth token
      final token = await _authService.getToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
      }

      _isUpdating = true;

      // Start location stream
      _locationSubscription = _locationService.getLocationStream(
        accuracy: LocationAccuracy.high,
        distanceFilter: _distanceFilterMeters,
        intervalDuration: _updateIntervalSeconds * 1000,
      ).listen(
        _onLocationUpdate,
        onError: (error) {
          debugPrint('Location stream error: $error');
          // Try to restart after a delay
          Future.delayed(const Duration(seconds: 10), () {
            if (_isUpdating) {
              stopLocationUpdates();
              startLocationUpdates();
            }
          });
        },
      );

      // Also set up a timer for regular updates (backup)
      _updateTimer = Timer.periodic(
        Duration(seconds: _updateIntervalSeconds),
        (_) => _sendCurrentLocation(),
      );

      debugPrint('Location updates started');
    } catch (e) {
      _isUpdating = false;
      throw Exception('Failed to start location updates: $e');
    }
  }

  // Stop location updates
  void stopLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    
    _updateTimer?.cancel();
    _updateTimer = null;
    
    _isUpdating = false;
    debugPrint('Location updates stopped');
  }

  // Handle location updates from stream
  void _onLocationUpdate(Position position) {
    _sendLocationToBackend(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }

  // Send current location (for timer-based updates)
  Future<void> _sendCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        await _sendLocationToBackend(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        );
      }
    } catch (e) {
      debugPrint('Error sending current location: $e');
    }
  }

  // Send location to backend
  Future<void> _sendLocationToBackend({
    required double latitude,
    required double longitude,
    required double accuracy,
    bool saveHistory = true,
  }) async {
    try {
      await _ensureTokenIsSet();
      
      await _apiClient.patch('/location/update', data: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'accuracy_m': accuracy.toString(),
        'save_history': saveHistory,
      });
      
      debugPrint('Location updated: $latitude, $longitude (±${accuracy.toStringAsFixed(1)}m)');
    } catch (e) {
      debugPrint('Error updating location: $e');
      
      // If unauthorized, stop updates
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        stopLocationUpdates();
      }
    }
  }

  // Manual location update
  Future<bool> updateLocationNow() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        await _sendLocationToBackend(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error in manual location update: $e');
      return false;
    }
  }

  // Dispose resources
  void dispose() {
    stopLocationUpdates();
  }
}

// Singleton instance
final locationUpdateService = LocationUpdateService();
