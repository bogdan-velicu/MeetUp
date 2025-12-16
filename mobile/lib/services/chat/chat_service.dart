import '../api/api_client.dart';
import '../auth/auth_service.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  // Ensure auth token is set before making requests
  Future<void> _ensureTokenIsSet() async {
    final token = await _authService.getToken();
    if (token != null) {
      _apiClient.setAuthToken(token);
    }
  }

  /// Get all conversations for the current user
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      await _ensureTokenIsSet();
      final response = await _apiClient.get('/chat/conversations');

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data['conversations'] ?? []);
      } else {
        throw Exception('Failed to load conversations: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error getting conversations: $e');
    }
  }

  /// Get or create a conversation with a friend
  Future<Map<String, dynamic>> getConversation(int friendId) async {
    try {
      await _ensureTokenIsSet();
      final response = await _apiClient.get('/chat/conversations/$friendId');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to get conversation: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error getting conversation: $e');
    }
  }

  /// Send a message to a friend
  Future<Map<String, dynamic>> sendMessage({
    required int friendId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      await _ensureTokenIsSet();
      final response = await _apiClient.post(
        '/chat/messages',
        data: {
          'friend_id': friendId,
          'content': content,
          'message_type': messageType,
        },
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to send message: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  /// Get message history for a conversation
  Future<Map<String, dynamic>> getMessages({
    required int conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      await _ensureTokenIsSet();
      final response = await _apiClient.get(
        '/chat/conversations/$conversationId/messages',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to load messages: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error getting messages: $e');
    }
  }

  /// Mark all messages in a conversation as read
  Future<void> markAsRead(int conversationId) async {
    try {
      await _ensureTokenIsSet();
      final response = await _apiClient.patch(
        '/chat/conversations/$conversationId/read',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark as read: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error marking as read: $e');
    }
  }

  /// Get total unread messages count
  Future<int> getUnreadCount() async {
    try {
      await _ensureTokenIsSet();
      final response = await _apiClient.get('/chat/unread-count');

      if (response.statusCode == 200) {
        final data = response.data;
        return data['unread_count'] ?? 0;
      } else {
        throw Exception('Failed to get unread count: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error getting unread count: $e');
    }
  }
}

