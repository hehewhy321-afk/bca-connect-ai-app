import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _firebaseMessaging;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        const androidChannel = AndroidNotificationChannel(
          'bca_notifications',
          'BCA Notifications',
          description: 'Notifications for BCA Connect AI',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidChannel);

        // Request notification permission for Android 13+
        final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      }

      // Initialize Firebase if available
      try {
        _firebaseMessaging = FirebaseMessaging.instance;

        // Request permission
        NotificationSettings settings = await _firebaseMessaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        debugPrint('Notification permission status: ${settings.authorizationStatus}');

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Get FCM token
        final token = await _firebaseMessaging!.getToken();
        debugPrint('FCM Token: $token');
      } catch (e) {
        debugPrint('Firebase messaging initialization error: $e');
      }

      _initialized = true;
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Notification service initialization error: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.messageId}');
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await showNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        payload: data['route'],
      );
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('Showing notification: $title - $body');

    final androidDetails = AndroidNotificationDetails(
      'bca_notifications',
      'BCA Notifications',
      channelDescription: 'Notifications for BCA Connect AI',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFDA7809),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
      ticker: 'New notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
      debugPrint('Notification shown successfully with ID: $id');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('Notification tapped with payload: $payload');
    if (payload != null) {
      // Handle navigation based on payload
      // You can use a global navigator key or event bus here
    }
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging?.getToken();
  }

  Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.areNotificationsEnabled() ?? false;
      debugPrint('Android notifications enabled: $granted');
      return granted;
    }
    return true;
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  
  // Show notification even when app is in background
  final notification = message.notification;
  if (notification != null) {
    await NotificationService().showNotification(
      title: notification.title ?? 'New Notification',
      body: notification.body ?? '',
      payload: message.data['route'],
    );
  }
}
