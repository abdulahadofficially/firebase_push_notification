import 'dart:math';
import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_notification_practice/screens/message_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationServices {
  NotificationServices._();

  // Step 1: Define required instances
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Step 2: Initialize Firebase Messaging
  /// Sets up listeners for incoming messages
  static void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message received: ${message.data}');
      // Initialize and show the notification
      // ignore: use_build_context_synchronously
      initFlutterLocalNotification(context, message);
      showNotification(message);
    });
  }

  /// Step 3: Initialize Local Notifications
  /// Configures Android and iOS-specific notification settings
  static void initFlutterLocalNotification(BuildContext context, RemoteMessage message) {
    var android = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var ios = const DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(android: android, iOS: ios);

    // Set up notification tap handler
    notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        handleMessage(context, message);
      },
    );
  }

  /// Step 4: Request Notification Permissions
  /// Prompts the user to grant notification permissions
  static Future<bool> permissionRequest() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('Notification Permission Granted');
      return true;
    } else {
      debugPrint('Notification Permission Denied');
      AppSettings.openAppSettings(type: AppSettingsType.notification);
      return false;
    }
  }

  /// Step 5: Retrieve Firebase Cloud Messaging Token
  /// Fetches the device's FCM token for use in server-side notifications
  static Future<String> getFCMToken() async {
    String? token = await messaging.getToken();
    debugPrint('Device Token: $token');
    return token ?? '';
  }

  /// Step 6: Show Notifications
  /// Displays a notification with custom details based on the received message
  static Future<void> showNotification(RemoteMessage message) async {
    // Define Android-specific notification settings
    AndroidNotificationChannel androidNotificationChannel = AndroidNotificationChannel(
      Random.secure().nextInt(10).toString(),
      'High Importance Notifications',
      importance: Importance.max,
    );
    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      androidNotificationChannel.id,
      androidNotificationChannel.name,
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );

    // Define iOS-specific notification settings
    DarwinNotificationDetails iosNotificationDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentList: true,
      presentSound: true,
      presentBanner: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    // Show the notification
    notificationsPlugin.show(
      1,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
    );
  }

  /// Step 7: Handle Notification Taps
  /// Navigates to specific screens based on notification data
  static void handleMessage(BuildContext context, RemoteMessage message) {
    if (message.data['type'] == 'message') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MessageScreen()),
      );
    }
  }

  /// Step 8: Setup Interaction for Background and Terminated States
  /// Configures how notifications are handled when the app is in the background or terminated
  static Future<void> setupInteractMessage(BuildContext context) async {
    // Handle notification when the app is terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // ignore: use_build_context_synchronously
      handleMessage(context, initialMessage);
    }

    // Handle notification when the app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      // ignore: use_build_context_synchronously
      handleMessage(context, event);
    });
  }
}
