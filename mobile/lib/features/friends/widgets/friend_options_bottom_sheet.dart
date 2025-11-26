import 'package:flutter/material.dart';
import '../../../models/friend.dart';
import '../../../services/friends/friends_service.dart';

class FriendOptionsBottomSheet extends StatelessWidget {
  final Friend friend;

  const FriendOptionsBottomSheet({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Friend info header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            friend.fullName.isNotEmpty 
                                ? friend.fullName[0].toUpperCase()
                                : friend.username[0].toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getStatusColor(friend.availabilityStatus),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.fullName.isNotEmpty ? friend.fullName : friend.username,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '@${friend.username}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatLastSeen(friend.updatedAt),
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(friend.availabilityStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        friend.availabilityStatus.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(friend.availabilityStatus),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              _buildActionTile(
                context,
                icon: Icons.chat_bubble_outline,
                title: 'Send Message',
                color: Theme.of(context).primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to chat screen
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.location_on_outlined,
                title: 'View on Map',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to map and focus on friend's location
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.event_outlined,
                title: 'Invite to Meet',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Create meeting invitation
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(),
              ),
              _buildActionTile(
                context,
                icon: Icons.person_remove_outlined,
                title: 'Remove Friend',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveFriendDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: title == 'Remove Friend' ? Colors.red : null,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _showRemoveFriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text('Remove Friend'),
            ],
          ),
          content: Text(
            'Are you sure you want to remove ${friend.fullName.isNotEmpty ? friend.fullName : friend.username} from your friends?\n\nThis action cannot be undone.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _removeFriend(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeFriend(BuildContext context) async {
    try {
      final friendsService = FriendsService();
      await friendsService.removeFriend(friend.userId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('${friend.fullName.isNotEmpty ? friend.fullName : friend.username} removed from friends'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to remove friend: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'busy':
        return Colors.red;
      case 'away':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatLastSeen(DateTime updatedAt) {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inMinutes < 1) {
      return 'Active now';
    } else if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours}h ago';
    } else {
      return 'Active ${difference.inDays}d ago';
    }
  }
}
