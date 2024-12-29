import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_notification_practice/screens/message_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationServices {
  NotificationServices._();

  // Step 1: Initialize Notification Instances
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Step 2: Request Notification Permissions
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

    if (settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('Permission Accepted');
      return true;
    } else {
      debugPrint('Permission Denied');
      AppSettings.openAppSettings(type: AppSettingsType.notification);
      return false;
    }
  }

  // Step 3: Retrieve FCM Token
  static Future<String> getFCMToken() async {
    String? token = await messaging.getToken();
    debugPrint('Device Token: $token');
    return token ?? '';
  }

  // Step 4: Configure Local Notifications
  static void initFlutterLocalNotification(BuildContext context, RemoteMessage message) {
    var android = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var ios = const DarwinInitializationSettings();

    var initializationSettings = InitializationSettings(android: android, iOS: ios);

    notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        handleMessage(context, message);
      },
    );
  }

  // Step 5: Listen for Foreground Notifications
  static void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Received message: ${message.data}');
      // ignore: use_build_context_synchronously
      initFlutterLocalNotification(context, message);
      showNotification(message);
    });
  }

  // Step 6: Display Notifications
  static Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel androidNotificationChannel =
        AndroidNotificationChannel(Random.secure().nextInt(10).toString(), 'High Importance Notification', importance: Importance.max);

    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      androidNotificationChannel.id,
      androidNotificationChannel.name,
      channelDescription: 'Channel Description',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );

    DarwinNotificationDetails iosNotificationDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentList: true,
      presentSound: true,
      presentBanner: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails, iOS: iosNotificationDetails);

    Future.delayed(Duration.zero, () {
      notificationsPlugin.show(1, message.notification?.title, message.notification?.body, notificationDetails);
    });
  }

  // Step 7: Handle Notification Clicks
  static void handleMessage(BuildContext context, RemoteMessage message) {
    if (message.data['type'] == 'message') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const MessageScreen()));
    }
  }

  // Step 8: Handle Background and Terminated States
  static Future<void> setupInteractMessage(BuildContext context) async {
    // When the app is terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      // ignore: use_build_context_synchronously
      handleMessage(context, initialMessage);
    }

    // When the app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      // ignore: use_build_context_synchronously
      handleMessage(context, event);
    });
  }
}
