import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/navigation_service.dart';
import 'core/utils/route_generator.dart';
import 'core/utils/route_names.dart';
import 'core/config/env_config.dart';
import 'services/auth/auth_provider.dart';
import 'services/auth/auth_service.dart';
import 'services/notifications/fcm_service.dart';

// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ignore: avoid_print
  print('Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await EnvConfig.load();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialize FCM
    final fcmService = FCMService();
    await fcmService.initialize();
  } catch (e) {
    // ignore: avoid_print
    print('Firebase initialization error: $e');
    // Continue without Firebase if initialization fails
  }
  
  // Initialize auth service to check for stored token
  final authService = AuthService();
  authService.getToken().then((token) {
    if (token != null) {
      authService.apiClient.setAuthToken(token);
    }
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'MeetUp!',
        theme: AppTheme.lightTheme,
        navigatorKey: NavigationService.navigatorKey,
        initialRoute: RouteNames.splash,
        onGenerateRoute: RouteGenerator.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
