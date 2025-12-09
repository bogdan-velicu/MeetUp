import '../api/api_client.dart';
import '../auth/auth_service.dart';
import '../../models/invitation.dart';

class InvitationsService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  Future<void> _ensureTokenIsSet() async {
    final token = await _authService.getToken();
    if (token != null) {
      _apiClient.setAuthToken(token);
    }
  }

  Future<List<Invitation>> getInvitations() async {
    try {
      await _ensureTokenIsSet();

      final response = await _apiClient.get('/invitations');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Invitation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load invitations');
      }
    } catch (e) {
      throw Exception('Error getting invitations: $e');
    }
  }

  Future<Invitation> getInvitationById(int invitationId) async {
    try {
      await _ensureTokenIsSet();

      final response = await _apiClient.get('/invitations/$invitationId');

      if (response.statusCode == 200) {
        return Invitation.fromJson(response.data);
      } else {
        throw Exception('Failed to load invitation');
      }
    } catch (e) {
      throw Exception('Error getting invitation: $e');
    }
  }

  Future<Invitation> acceptInvitation(int invitationId) async {
    try {
      await _ensureTokenIsSet();

      final response = await _apiClient.patch('/invitations/$invitationId/accept');

      if (response.statusCode == 200) {
        return Invitation.fromJson(response.data);
      } else {
        throw Exception('Failed to accept invitation: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error accepting invitation: $e');
    }
  }

  Future<Invitation> declineInvitation(int invitationId) async {
    try {
      await _ensureTokenIsSet();

      final response = await _apiClient.patch('/invitations/$invitationId/decline');

      if (response.statusCode == 200) {
        return Invitation.fromJson(response.data);
      } else {
        throw Exception('Failed to decline invitation: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error declining invitation: $e');
    }
  }
}

