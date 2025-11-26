import '../api/api_client.dart';
import '../auth/auth_service.dart';
import '../../models/friend.dart';

class FriendsService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  // Ensure auth token is set before making requests
  Future<void> _ensureTokenIsSet() async {
    final token = await _authService.getToken();
    if (token != null) {
      _apiClient.setAuthToken(token);
    }
  }

  // Get friends locations for map display
  Future<List<Friend>> getFriendsLocations({bool closeFriendsOnly = false}) async {
    try {
      // Ensure token is set before making request
      await _ensureTokenIsSet();
      
      final response = await _apiClient.get(
        '/location/friends/locations',
        queryParameters: {'close_friends_only': closeFriendsOnly},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Friend.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load friends locations');
      }
    } catch (e) {
      throw Exception('Error getting friends locations: $e');
    }
  }

  // Get friends list
  Future<List<Map<String, dynamic>>> getFriends({bool closeFriendsOnly = false}) async {
    try {
      await _ensureTokenIsSet();
      
      final response = await _apiClient.get(
        '/friends',
        queryParameters: {'close_friends_only': closeFriendsOnly},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to load friends');
      }
    } catch (e) {
      throw Exception('Error getting friends: $e');
    }
  }

  // Send friend request
  Future<Map<String, dynamic>> sendFriendRequest(int friendId) async {
    try {
      await _ensureTokenIsSet();
      
      final response = await _apiClient.post('/friends/$friendId/request');

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to send friend request');
      }
    } catch (e) {
      throw Exception('Error sending friend request: $e');
    }
  }

  // Accept friend request
  Future<Map<String, dynamic>> acceptFriendRequest(int friendId) async {
    try {
      await _ensureTokenIsSet();
      
      final response = await _apiClient.patch('/friends/$friendId/accept');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to accept friend request');
      }
    } catch (e) {
      throw Exception('Error accepting friend request: $e');
    }
  }

  // Remove friend
  Future<void> removeFriend(int friendId) async {
    try {
      await _ensureTokenIsSet();
      
      final response = await _apiClient.delete('/friends/$friendId');

      if (response.statusCode != 204) {
        throw Exception('Failed to remove friend');
      }
    } catch (e) {
      throw Exception('Error removing friend: $e');
    }
  }

  // Get pending friend requests
  Future<List<Map<String, dynamic>>> getPendingFriendRequests() async {
    try {
      await _ensureTokenIsSet(); // Ensure token is set
      final response = await _apiClient.get('/friends/requests/pending');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to load pending requests: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting pending requests: $e');
    }
  }

  // Decline friend request
  Future<void> declineFriendRequest(int friendId) async {
    try {
      await _ensureTokenIsSet();
      
      final response = await _apiClient.patch('/friends/$friendId/decline');

      if (response.statusCode != 204) {
        throw Exception('Failed to decline friend request');
      }
    } catch (e) {
      throw Exception('Error declining friend request: $e');
    }
  }

  // Search users for adding friends
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      await _ensureTokenIsSet();
      final response = await _apiClient.get(
        '/users/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to search users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }
}
