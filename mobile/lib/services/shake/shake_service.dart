import '../api/api_client.dart';
import '../auth/auth_service.dart';
import '../location/location_service.dart';

class ShakeService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();

  Future<void> _ensureTokenIsSet() async {
    final token = await _authService.getToken();
    if (token != null) {
      _apiClient.setAuthToken(token);
    }
  }

  /// Initiate a shake session
  Future<Map<String, dynamic>> initiateShake() async {
    try {
      await _ensureTokenIsSet();

      // Get current location
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Could not get current location');
      }

      final response = await _apiClient.post(
        '/shake/initiate',
        data: {
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
          'accuracy_m': position.accuracy.toString(),
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to initiate shake: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error initiating shake: $e');
    }
  }

  /// Get nearby friends who are shaking
  Future<List<Map<String, dynamic>>> getNearbyShakingFriends(
    double latitude,
    double longitude,
  ) async {
    try {
      await _ensureTokenIsSet();

      final response = await _apiClient.get(
        '/shake/nearby-friends',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data['nearby_friends'] ?? []);
      } else {
        throw Exception('Failed to get nearby friends: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error getting nearby friends: $e');
    }
  }

  /// Get active shake session
  Future<Map<String, dynamic>?> getActiveSession() async {
    try {
      await _ensureTokenIsSet();

      final response = await _apiClient.get('/shake/active-session');

      if (response.statusCode == 200) {
        return response.data;
      } else if (response.statusCode == 404) {
        return null; // No active session
      } else {
        throw Exception('Failed to get active session: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error getting active session: $e');
    }
  }
}

