import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'notifications_service.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final NotificationsService _notificationsService = NotificationsService();

  // Initialize FCM
  Future<void> initialize() async {
    // Request permission for iOS
    if (Platform.isIOS) {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        throw Exception('Notification permissions not granted');
      }
    }
    
    // Request permission for Android 13+ (API 33+)
    if (Platform.isAndroid) {
      final androidInfo = await _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidInfo != null) {
        final granted = await androidInfo.requestNotificationsPermission();
        if (granted == true) {
          debugPrint('✅ Android notification permission granted');
        } else {
          debugPrint('⚠️ Android notification permission denied');
        }
      }
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token and register with backend (only if user is logged in)
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint('FCM Token obtained: ${token.substring(0, 20)}...');
      // Register token with backend (only if user is logged in)
      try {
        final isLoggedIn = await _notificationsService.isUserLoggedIn();
        if (isLoggedIn) {
          await _notificationsService.registerFCMToken(token);
          debugPrint('✅ FCM token registered with backend successfully');
        } else {
          debugPrint('⚠️ User not logged in, FCM token will be registered after login');
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Failed to register FCM token with backend: $e');
        debugPrint('Stack trace: $stackTrace');
        // Continue - token registration will be retried on next login
      }
    } else {
      debugPrint('⚠️ FCM token is null - Firebase might not be properly configured');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      debugPrint('New FCM Token: $newToken');
      // Update token in backend
      try {
        await _notificationsService.registerFCMToken(newToken);
        debugPrint('FCM token updated in backend');
      } catch (e) {
        debugPrint('Failed to update FCM token in backend: $e');
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Create notification channel for Android
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'meetup_channel', // id
      'MeetUp Notifications', // name
      description: 'Notifications for MeetUp app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Initialize Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the notification channel for Android
    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(channel);
        debugPrint('✅ Notification channel created: ${channel.id}');
      }
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  // Handle background messages
  void _handleBackgroundMessage(RemoteMessage message) {
    // Navigate to appropriate screen based on message data
    debugPrint('Background message: ${message.data}');
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'meetup_channel',
      'MeetUp Notifications',
      channelDescription: 'Notifications for MeetUp app',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'MeetUp',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on notification payload
    debugPrint('Notification tapped: ${response.payload}');
  }

  // Get FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

// Background message handler is defined in main.dart

