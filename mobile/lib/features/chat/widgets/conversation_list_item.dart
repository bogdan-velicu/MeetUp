import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConversationListItem extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback onTap;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return DateFormat('HH:mm').format(date);
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE').format(date);
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = conversation['other_user'] as Map<String, dynamic>? ?? {};
    final lastMessagePreview = conversation['last_message_preview'] as String?;
    final lastMessageAt = conversation['last_message_at'] as String?;
    final unreadCount = conversation['unread_count'] as int? ?? 0;
    final fullName = otherUser['full_name'] as String?;
    final username = otherUser['username'] as String? ?? 'Unknown';
    final profilePhotoUrl = otherUser['profile_photo_url'] as String?;

    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
            ? NetworkImage(profilePhotoUrl)
            : null,
        child: profilePhotoUrl == null || profilePhotoUrl.isEmpty
            ? Text(
                (fullName ?? username).substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              fullName ?? username,
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lastMessageAt != null)
            Text(
              _formatTimestamp(lastMessageAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessagePreview ?? 'No messages yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

