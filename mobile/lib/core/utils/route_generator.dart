import 'package:flutter/material.dart';
import 'route_names.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/navigation/main_navigation_screen.dart';
import '../../features/friends/add_friend_screen.dart';
import '../../features/friends/friend_requests_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      
      case '/add-friend':
        return MaterialPageRoute(builder: (_) => const AddFriendScreen());
      
      case '/friend-requests':
        return MaterialPageRoute(builder: (_) => const FriendRequestsScreen());
      
      default:
        return _errorRoute();
    }
  }
  
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Page not found'),
        ),
      ),
    );
  }
}

