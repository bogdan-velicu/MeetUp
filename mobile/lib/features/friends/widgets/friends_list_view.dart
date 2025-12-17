import 'package:flutter/material.dart';
import '../../../models/friend.dart';
import '../../../services/friends/friends_service.dart';
import 'friend_options_bottom_sheet.dart';

class FriendsListView extends StatefulWidget {
  final Function(int)? onViewFriendOnMap;
  final VoidCallback? onRefreshRequested;
  
  const FriendsListView({super.key, this.onViewFriendOnMap, this.onRefreshRequested});

  @override
  State<FriendsListView> createState() => _FriendsListViewState();
}

class _FriendsListViewState extends State<FriendsListView> {
  final FriendsService _friendsService = FriendsService();
  List<Friend> _friends = [];
  List<Friend> _closeFriends = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh friends list when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFriends();
      }
    });
  }

  @override
  void didUpdateWidget(FriendsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh if refresh was requested
    if (widget.onRefreshRequested != oldWidget.onRefreshRequested && widget.onRefreshRequested != null) {
      _loadFriends();
    }
  }

  // Public method to refresh friends list
  void refresh() {
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load both all friends and close friends
      final allFriends = await _friendsService.getFriendsLocations(closeFriendsOnly: false);
      final closeFriends = await _friendsService.getFriendsLocations(closeFriendsOnly: true);
      
      setState(() {
        _friends = allFriends;
        _closeFriends = closeFriends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadFriends,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadFriends,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Close Friends Section
                    if (_closeFriends.isNotEmpty) ...[
                      _buildSectionHeader('Close Friends', _closeFriends.length),
                      const SizedBox(height: 8),
                      ..._closeFriends.map((friend) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: _FriendListItem(
                              friend: friend,
                              onTap: () => _onFriendTap(friend),
                            ),
                          )),
                      const SizedBox(height: 24),
                    ],
                    // My Friends Section
                    _buildSectionHeader('My Friends', _friends.length),
                    const SizedBox(height: 8),
                    if (_friends.isEmpty)
                      Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.people_outline,
                                size: 48,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No friends yet',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start connecting with people around you!',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/add-friend');
                              },
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add Friends'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._friends.map((friend) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: _FriendListItem(
                              friend: friend,
                              onTap: () => _onFriendTap(friend),
                            ),
                          )),
                    const SizedBox(height: 80), // Extra space for bottom nav
                  ],
                ),
              );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _onFriendTap(Friend friend) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FriendOptionsBottomSheet(
        friend: friend,
        onViewOnMap: widget.onViewFriendOnMap != null 
            ? () => widget.onViewFriendOnMap!(friend.userId)
            : null,
      ),
    ).then((_) {
      // Refresh friends list when bottom sheet is closed
      _loadFriends();
    });
  }
}

class _FriendListItem extends StatelessWidget {
  final Friend friend;
  final VoidCallback onTap;

  const _FriendListItem({
    required this.friend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                friend.fullName.isNotEmpty 
                    ? friend.fullName[0].toUpperCase()
                    : friend.username[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
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
        title: Text(
          friend.fullName.isNotEmpty ? friend.fullName : friend.username,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '@${friend.username}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatLastSeen(friend.updatedAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
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
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

