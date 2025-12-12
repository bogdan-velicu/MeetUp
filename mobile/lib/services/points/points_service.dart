import '../api/api_client.dart';
import '../auth/auth_service.dart';

class PointsService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  Future<void> _ensureTokenIsSet() async {
    final token = await _authService.getToken();
    if (token != null) {
      _apiClient.setAuthToken(token);
    }
  }

  /// Get user's points summary
  Future<Map<String, dynamic>> getPointsSummary() async {
    try {
      await _ensureTokenIsSet();

      final response = await _apiClient.get('/points/summary');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load points summary: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error getting points summary: $e');
    }
  }

  /// Get user's points history
  Future<Map<String, dynamic>> getPointsHistory({
    int limit = 50,
    int offset = 0,
    String? transactionType,
  }) async {
    try {
      await _ensureTokenIsSet();

      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (transactionType != null) {
        queryParams['transaction_type'] = transactionType;
      }

      final response = await _apiClient.get(
        '/points/history',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load points history: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error getting points history: $e');
    }
  }

  /// Confirm a meeting and receive points
  Future<Map<String, dynamic>> confirmMeeting(int meetingId) async {
    try {
      await _ensureTokenIsSet();

      final response = await _apiClient.post(
        '/points/meetings/$meetingId/confirm',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to confirm meeting: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error confirming meeting: $e');
    }
  }
}

