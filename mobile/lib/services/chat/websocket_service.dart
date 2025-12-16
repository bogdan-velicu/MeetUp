import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async' show Timer;
import '../auth/auth_service.dart';
import '../../core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final AuthService _authService = AuthService();
  bool _isConnected = false;
  int? _currentConversationId;
  
  // Stream controllers for different message types
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;
  int? get currentConversationId => _currentConversationId;

  /// Get the WebSocket URL base
  Future<String> _getWebSocketBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(AppConstants.customBackendUrlKey);
    final baseUrl = customUrl ?? AppConstants.baseUrl;
    
    // Convert http:// to ws:// or https:// to wss://
    if (baseUrl.startsWith('http://')) {
      return baseUrl.replaceFirst('http://', 'ws://');
    } else if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://');
    }
    return 'ws://$baseUrl';
  }

  /// Connect to WebSocket for a conversation
  Future<void> connect(int conversationId) async {
    if (_isConnected && _currentConversationId == conversationId) {
      return; // Already connected to this conversation
    }

    // Disconnect from previous conversation if any
    if (_isConnected) {
      await disconnect();
    }

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final wsBaseUrl = await _getWebSocketBaseUrl();
      final wsUrl = '$wsBaseUrl${AppConstants.apiVersion}/chat/ws/$conversationId?token=$token';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _currentConversationId = conversationId;
      _isConnected = true;
      _connectionController.add(true);

      // Listen for messages
      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final message = json.decode(data as String) as Map<String, dynamic>;
            _handleMessage(message);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleDisconnection();
        },
      );

      // Send ping to keep connection alive
      _startPingTimer();
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _isConnected = false;
      _connectionController.add(false);
      rethrow;
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    _stopPingTimer();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _subscription = null;
    _isConnected = false;
    _currentConversationId = null;
    _connectionController.add(false);
  }

  /// Send a message via WebSocket (for typing indicators, etc.)
  void send(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(json.encode(message));
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    }
  }

  /// Send typing indicator
  void sendTyping(bool isTyping) {
    send({
      'type': 'typing',
      'is_typing': isTyping,
    });
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;

    switch (type) {
      case 'new_message':
        _messageController.add(message['data'] as Map<String, dynamic>);
        break;
      case 'typing':
        _typingController.add(message);
        break;
      case 'pong':
        // Ping response, connection is alive
        break;
      default:
        print('Unknown WebSocket message type: $type');
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _isConnected = false;
    _currentConversationId = null;
    _connectionController.add(false);
  }

  // Ping timer to keep connection alive
  Timer? _pingTimer;

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        send({'type': 'ping'});
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _connectionController.close();
    _pingTimer?.cancel();
  }
}

