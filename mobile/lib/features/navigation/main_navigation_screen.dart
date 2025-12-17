import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../chat/chat_screen.dart';
import '../friends/friends_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../meetings/meetings_list_screen.dart';
import '../../services/chat/chat_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/animated_bottom_nav_item.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // Start at Map (center)
  final GlobalKey<MapScreenState> _mapScreenKey = GlobalKey<MapScreenState>();
  final PageController _pageController = PageController(initialPage: 2);
  double _pageOffset = 2.0; // Track page scroll position for parallax

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
    
    // Listen to page controller for parallax effect
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _pageOffset = _pageController.page ?? _currentIndex.toDouble();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  MapScreenState? getMapScreenState() {
    return _mapScreenKey.currentState;
  }

  void switchToMapAndFocusFriend(int friendId) {
    debugPrint('=== switchToMapAndFocusFriend START ===');
    debugPrint('switchToMapAndFocusFriend called for friendId: $friendId');
    debugPrint('Current tab index: $_currentIndex');
    debugPrint('Map screen key current state: ${_mapScreenKey.currentState}');
    
    // Switch to map tab first with animation
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
          // Continuous gradient background with parallax effect
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              // Calculate current page and progress
              final currentPage = _pageOffset.floor();
              final progress = _pageOffset - currentPage;
              
              // Get interpolated gradient based on page position
              LinearGradient gradient;
              if (progress > 0 && currentPage < _screens.length - 1) {
                gradient = AppTheme.getInterpolatedGradient(
                  progress,
                  currentPage,
                  currentPage + 1,
                );
              } else {
                gradient = AppTheme.pageGradients[
                  currentPage.clamp(0, _screens.length - 1)
                ];
              }
              
              return Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                ),
              );
            },
          ),
          // Full screen content with horizontal slide animation
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable manual swipe
            itemCount: _screens.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  // Calculate scale and opacity based on distance from current page
                  final pageOffset = _pageController.hasClients
                      ? (_pageController.page ?? index.toDouble())
                      : index.toDouble();
                  final distance = (pageOffset - index).abs();
                  final scale = (1 - distance * 0.05).clamp(0.95, 1.0);
                  final opacity = (1 - distance * 0.3).clamp(0.7, 1.0);
                  
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  );
                },
                child: _screens[index],
              );
            },
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
    final inactiveColor = AppTheme.textTertiary;

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
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
                spreadRadius: 0,
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
      // Animate to the new page with smooth horizontal slide
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }
}

