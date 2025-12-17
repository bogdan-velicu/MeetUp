import 'package:flutter/material.dart';
import 'widgets/friends_list_view.dart';
import 'add_friend_screen.dart';
import 'friend_requests_screen.dart';
import '../invitations/invitations_list_screen.dart';
import '../navigation/main_navigation_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with WidgetsBindingObserver {
  int _refreshKey = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app resumes
      _refreshFriendsList();
    }
  }

  void _refreshFriendsList() {
    setState(() {
      _refreshKey++; // Force rebuild to trigger refresh
    });
    
    // Also refresh map screen if it exists
    final mainNav = context.findAncestorStateOfType<MainNavigationScreenState>();
    if (mainNav != null) {
      final mapState = mainNav.getMapScreenState();
      mapState?.refreshFriendsLocations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendRequestsScreen(
                    onFriendRequestAccepted: _refreshFriendsList,
                  ),
                ),
              );
              // Refresh friends list when returning from requests screen
              _refreshFriendsList();
            },
          ),
          IconButton(
            icon: const Icon(Icons.event_available),
            tooltip: 'Invitations',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InvitationsListScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFriendScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FriendsListView(
        key: ValueKey(_refreshKey),
        onRefreshRequested: _refreshKey > 0 ? () {} : null,
        onViewFriendOnMap: (friendId) {
          // Find MainNavigationScreen from FriendsScreen context
          final mainNav = context
              .findAncestorStateOfType<MainNavigationScreenState>();
          if (mainNav != null) {
            mainNav.switchToMapAndFocusFriend(friendId);
          } else {
            debugPrint(
              'ERROR: Could not find MainNavigationScreen from FriendsScreen',
            );
          }
        },
      ),
    );
  }
}
