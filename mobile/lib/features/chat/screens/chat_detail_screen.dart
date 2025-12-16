import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/chat/chat_provider.dart';
import '../../../services/auth/auth_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

class ChatDetailScreen extends StatefulWidget {
  final int conversationId;
  final Map<String, dynamic> otherUser;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ChatProvider>(context, listen: false);
    
    // Load messages and connect WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await provider.loadMessages(widget.conversationId, refresh: true);
      await provider.connectWebSocket(widget.conversationId);
      await provider.markAsRead(widget.conversationId);
      
      // Scroll to bottom after messages load
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _stopTyping();

    final provider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?['id'] as int?;

    if (currentUserId == null) return;

    // Get friend ID from other user
    final friendId = widget.otherUser['id'] as int?;
    if (friendId == null) return;

    final success = await provider.sendMessage(
      friendId: friendId,
      content: content,
      conversationId: widget.conversationId,
    );

    if (success && mounted) {
      _scrollToBottom();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onTextChanged(String text) {
    if (text.trim().isNotEmpty && !_isTyping) {
      _isTyping = true;
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.sendTyping(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _stopTyping();
    });
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.sendTyping(false);
    }
    _typingTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final otherUserName = widget.otherUser['full_name'] as String? ??
        widget.otherUser['username'] as String? ??
        'Unknown';
    final profilePhotoUrl = widget.otherUser['profile_photo_url'] as String?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                  ? NetworkImage(profilePhotoUrl)
                  : null,
              child: profilePhotoUrl == null || profilePhotoUrl.isEmpty
                  ? Text(
                      otherUserName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Consumer<ChatProvider>(
                    builder: (context, provider, child) {
                      final isTyping = provider.isTyping[widget.conversationId] ?? false;
                      final isConnected = provider.isWebSocketConnected;
                      if (isTyping) {
                        return const Text(
                          'typing...',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                        );
                      } else if (isConnected) {
                        return const Text(
                          'online',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final messages = provider.getMessagesForConversation(widget.conversationId);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final currentUserId = authProvider.currentUser?['id'] as int?;

                if (provider.isLoading && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final senderId = message['sender_id'] as int?;
                    final isMe = senderId == currentUserId;

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
            onChanged: _onTextChanged,
          ),
        ],
      ),
    );
  }
}

