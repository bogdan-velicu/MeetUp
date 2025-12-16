import 'package:flutter/foundation.dart';
import 'chat_service.dart';
import 'websocket_service.dart';
import 'dart:async';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final WebSocketService _webSocketService = WebSocketService();

  // State
  List<Map<String, dynamic>> _conversations = [];
  Map<int, List<Map<String, dynamic>>> _messages = {}; // conversation_id -> messages
  Map<int, bool> _isTyping = {}; // conversation_id -> is_typing
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  int? _currentConversationId;

  // Getters
  List<Map<String, dynamic>> get conversations => _conversations;
  Map<int, List<Map<String, dynamic>>> get messages => _messages;
  Map<int, bool> get isTyping => _isTyping;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get currentConversationId => _currentConversationId;
  bool get isWebSocketConnected => _webSocketService.isConnected;

  // Stream subscriptions
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _connectionSubscription;

  ChatProvider() {
    _initializeWebSocketListeners();
    loadConversations();
    loadUnreadCount();
  }

  void _initializeWebSocketListeners() {
    // Listen for new messages
    _messageSubscription = _webSocketService.messageStream.listen((message) {
      final conversationId = message['conversation_id'] as int?;
      if (conversationId != null) {
        _addMessageToConversation(conversationId, message);
        notifyListeners();
      }
    });

    // Listen for typing indicators
    _typingSubscription = _webSocketService.typingStream.listen((data) {
      final conversationId = _currentConversationId;
      final isTyping = data['is_typing'] as bool? ?? false;
      if (conversationId != null) {
        _isTyping[conversationId] = isTyping;
        notifyListeners();
      }
    });

    // Listen for connection status
    _connectionSubscription = _webSocketService.connectionStream.listen((connected) {
      notifyListeners();
    });
  }

  /// Load all conversations
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load messages for a conversation
  Future<void> loadMessages(int conversationId, {bool refresh = false}) async {
    if (!refresh && _messages.containsKey(conversationId)) {
      return; // Already loaded
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _chatService.getMessages(
        conversationId: conversationId,
        limit: 50,
        offset: 0,
      );

      _messages[conversationId] = List<Map<String, dynamic>>.from(result['messages'] ?? []);
      _isLoading = false;
      notifyListeners();

      // Mark as read when loading messages
      await markAsRead(conversationId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get or create conversation with a friend
  Future<Map<String, dynamic>?> getOrCreateConversation(int friendId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversation = await _chatService.getConversation(friendId);
      _isLoading = false;
      
      // Update conversations list
      await loadConversations();
      
      // Connect WebSocket if not already connected
      final conversationId = conversation['id'] as int?;
      if (conversationId != null && _currentConversationId != conversationId) {
        await connectWebSocket(conversationId);
      }
      
      notifyListeners();
      return conversation;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Send a message
  Future<bool> sendMessage({
    required int friendId,
    required String content,
    int? conversationId,
  }) async {
    if (content.trim().isEmpty) {
      return false;
    }

    try {
      final message = await _chatService.sendMessage(
        friendId: friendId,
        content: content.trim(),
      );

      final msgConversationId = message['conversation_id'] as int?;
      if (msgConversationId != null) {
        // Add message to local state
        _addMessageToConversation(msgConversationId, message);
        
        // Connect WebSocket if not connected
        if (_currentConversationId != msgConversationId) {
          await connectWebSocket(msgConversationId);
        }
        
        // Refresh conversations list to update last message preview
        await loadConversations();
        
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Add message to conversation (used for WebSocket messages)
  void _addMessageToConversation(int conversationId, Map<String, dynamic> message) {
    if (!_messages.containsKey(conversationId)) {
      _messages[conversationId] = [];
    }
    
    // Check if message already exists (avoid duplicates)
    final messageId = message['id'] as int?;
    if (messageId != null) {
      final exists = _messages[conversationId]!.any((m) => m['id'] == messageId);
      if (!exists) {
        _messages[conversationId]!.add(message);
        // Sort by created_at
        _messages[conversationId]!.sort((a, b) {
          final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
          final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
          return aTime.compareTo(bTime);
        });
      }
    }
  }

  /// Mark conversation as read
  Future<void> markAsRead(int conversationId) async {
    try {
      await _chatService.markAsRead(conversationId);
      await loadUnreadCount();
      await loadConversations(); // Refresh to update unread counts
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  /// Load unread count
  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _chatService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  /// Connect WebSocket for a conversation
  Future<void> connectWebSocket(int conversationId) async {
    if (_currentConversationId == conversationId && _webSocketService.isConnected) {
      return; // Already connected
    }

    try {
      await _webSocketService.connect(conversationId);
      _currentConversationId = conversationId;
      notifyListeners();
    } catch (e) {
      debugPrint('Error connecting WebSocket: $e');
    }
  }

  /// Disconnect WebSocket
  Future<void> disconnectWebSocket() async {
    await _webSocketService.disconnect();
    _currentConversationId = null;
    notifyListeners();
  }

  /// Send typing indicator
  void sendTyping(bool isTyping) {
    if (_currentConversationId != null) {
      _webSocketService.sendTyping(isTyping);
    }
  }

  /// Get messages for a conversation
  List<Map<String, dynamic>> getMessagesForConversation(int conversationId) {
    return _messages[conversationId] ?? [];
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _connectionSubscription?.cancel();
    _webSocketService.dispose();
    super.dispose();
  }
}

