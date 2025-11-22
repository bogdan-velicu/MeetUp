import 'package:flutter/material.dart';
import '../chat/chat_screen.dart';
import '../friends/friends_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../events/events_screen.dart';
import 'widgets/animated_bottom_nav_item.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // Start at Map (center)

  final List<Widget> _screens = [
    const ChatScreen(),
    const FriendsScreen(),
    const MapScreen(),
    const EventsScreen(),
    const ProfileScreen(),
  ];

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
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AnimatedBottomNavItem(
                    icon: Icons.chat_outlined,
                    activeIcon: Icons.chat,
                    label: 'Chat',
                    isActive: _currentIndex == 0,
                    isCenter: false,
                    onTap: () => _onTabTapped(0),
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
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

