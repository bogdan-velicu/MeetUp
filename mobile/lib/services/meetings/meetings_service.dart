import '../api/api_client.dart';
import '../auth/auth_service.dart';
import '../../models/meeting.dart';

class MeetingsService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  Future<void> _ensureTokenIsSet() async {
    final token = await _authService.getToken();
    if (token != null) {
      _apiClient.setAuthToken(token);
    }
  }

  Future<Meeting> createMeeting({
    String? title,
    String? description,
    int? locationId,
    String? latitude,
    String? longitude,
    String? address,
    required DateTime scheduledAt,
    required List<int> participantIds,
  }) async {
    try {
      await _ensureTokenIsSet();

      final response = await _apiClient.post(
        '/meetings',
        data: {
          'title': title,
          'description': description,
          'location_id': locationId,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'scheduled_at': scheduledAt.toIso8601String(),
          'participant_ids': participantIds,
        },
      );

      if (response.statusCode == 201) {
        return Meeting.fromJson(response.data);
      } else {
        throw Exception('Failed to create meeting: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error creating meeting: $e');
    }
  }

  Future<List<Meeting>> getMeetings({String filterType = 'all'}) async {
    try {
      await _ensureTokenIsSet();

      final response = await _apiClient.get(
        '/meetings',
        queryParameters: {'filter_type': filterType},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Meeting.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load meetings');
      }
    } catch (e) {
      throw Exception('Error getting meetings: $e');
    }
  }

  Future<Meeting> getMeetingById(int meetingId) async {
    try {
      await _ensureTokenIsSet();

      final response = await _apiClient.get('/meetings/$meetingId');

      if (response.statusCode == 200) {
        return Meeting.fromJson(response.data);
      } else {
        throw Exception('Failed to load meeting');
      }
    } catch (e) {
      throw Exception('Error getting meeting: $e');
    }
  }

  Future<Meeting> updateMeeting(
    int meetingId, {
    String? title,
    String? description,
    int? locationId,
    String? latitude,
    String? longitude,
    String? address,
    DateTime? scheduledAt,
    String? status,
  }) async {
    try {
      await _ensureTokenIsSet();

      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (locationId != null) data['location_id'] = locationId;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (address != null) data['address'] = address;
      if (scheduledAt != null) data['scheduled_at'] = scheduledAt.toIso8601String();
      if (status != null) data['status'] = status;

      final response = await _apiClient.patch(
        '/meetings/$meetingId',
        data: data,
      );

      if (response.statusCode == 200) {
        return Meeting.fromJson(response.data);
      } else {
        throw Exception('Failed to update meeting: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error updating meeting: $e');
    }
  }

  Future<void> deleteMeeting(int meetingId) async {
    try {
      await _ensureTokenIsSet();

      final response = await _apiClient.delete('/meetings/$meetingId');

      if (response.statusCode != 204) {
        throw Exception('Failed to delete meeting: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error deleting meeting: $e');
    }
  }

  Future<Meeting> addParticipantsToMeeting(int meetingId, List<int> participantIds) async {
    try {
      await _ensureTokenIsSet();

      final response = await _apiClient.post(
        '/meetings/$meetingId/participants',
        data: participantIds,
      );

      if (response.statusCode == 200) {
        return Meeting.fromJson(response.data);
      } else {
        throw Exception('Failed to add participants: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error adding participants: $e');
    }
  }
}

