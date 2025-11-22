import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/route_names.dart';
import '../utils/navigation_service.dart';
import '../../services/auth/auth_provider.dart';

class ProtectedRoute extends StatelessWidget {
  final Widget child;

  const ProtectedRoute({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading while checking auth status
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Redirect to login if not authenticated
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NavigationService.navigateToAndRemoveUntil(RouteNames.login);
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show protected content
        return child;
      },
    );
  }
}

