import '../api/api_client.dart';
import '../../models/friend.dart';

class FriendsService {
  final ApiClient _apiClient = ApiClient();

  // Get friends locations for map display
  Future<List<Friend>> getFriendsLocations({bool closeFriendsOnly = false}) async {
    try {
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
      final response = await _apiClient.delete('/friends/$friendId');

      if (response.statusCode != 204) {
        throw Exception('Failed to remove friend');
      }
    } catch (e) {
      throw Exception('Error removing friend: $e');
    }
  }
}
