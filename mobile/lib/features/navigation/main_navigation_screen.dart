import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../chat/chat_screen.dart';
import '../friends/friends_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../meetings/meetings_list_screen.dart';
import '../../services/chat/chat_provider.dart';
import 'widgets/animated_bottom_nav_item.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // Start at Map (center)
  final GlobalKey<MapScreenState> _mapScreenKey = GlobalKey<MapScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const ChatScreen(),
      const FriendsScreen(),
      MapScreen(key: _mapScreenKey),
      const MeetingsListScreen(),
      const ProfileScreen(),
    ];
  }

  MapScreenState? getMapScreenState() {
    return _mapScreenKey.currentState;
  }

  void switchToMapAndFocusFriend(int friendId) {
    debugPrint('=== switchToMapAndFocusFriend START ===');
    debugPrint('switchToMapAndFocusFriend called for friendId: $friendId');
    debugPrint('Current tab index: $_currentIndex');
    debugPrint('Map screen key current state: ${_mapScreenKey.currentState}');
    
    // Switch to map tab first
    setState(() {
      _currentIndex = 2; // Switch to map tab
    });
    debugPrint('Tab switched to map (index 2)');
    
    // Function to actually call focusOnFriend
    void callFocusOnFriend() {
      final mapState = _mapScreenKey.currentState;
      debugPrint('Attempting to call focusOnFriend, mapState: $mapState');
      if (mapState != null) {
        debugPrint('Calling focusOnFriend on map state for friendId: $friendId');
        mapState.focusOnFriend(friendId).then((_) {
          debugPrint('focusOnFriend future completed');
        }).catchError((e, stackTrace) {
          debugPrint('Error in focusOnFriend: $e');
          debugPrint('Stack trace: $stackTrace');
        });
      } else {
        debugPrint('ERROR: Map screen state is null!');
      }
    }
    
    // Event-based: wait for tab switch to complete, then call focus
    // No artificial delays - just wait for the frame to render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callFocusOnFriend();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full screen content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Floating bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFloatingBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomNav() {
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = Colors.grey.withOpacity(0.6);

    return SafeArea(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      return AnimatedBottomNavItem(
                        icon: Icons.chat_outlined,
                        activeIcon: Icons.chat,
                        label: 'Chat',
                        isActive: _currentIndex == 0,
                        isCenter: false,
                        onTap: () {
                          _onTabTapped(0);
                          // Refresh unread count when opening chat tab
                          chatProvider.loadUnreadCount();
                        },
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        badgeCount: chatProvider.unreadCount > 0 ? chatProvider.unreadCount : null,
                      );
                    },
                  ),
                  AnimatedBottomNavItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: 'Friends',
                    isActive: _currentIndex == 1,
                    isCenter: false,
                    onTap: () => _onTabTapped(1),
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  AnimatedBottomNavItem(
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map,
                    label: 'Map',
                    isActive: _currentIndex == 2,
                    isCenter: true,
                    onTap: () => _onTabTapped(2),
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  AnimatedBottomNavItem(
                    icon: Icons.event_outlined,
                    activeIcon: Icons.event,
                    label: 'Events',
                    isActive: _currentIndex == 3,
                    isCenter: false,
                    onTap: () => _onTabTapped(3),
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                  AnimatedBottomNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    isActive: _currentIndex == 4,
                    isCenter: false,
                    onTap: () => _onTabTapped(4),
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }
}

