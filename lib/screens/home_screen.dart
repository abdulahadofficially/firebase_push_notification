import 'package:firebase_notification_practice/utils/notification_services.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  Future<void> initializeNotifications() async {
    if (await NotificationServices.permissionRequest() == true) {
      NotificationServices.getFCMToken().then((value) {
        // ignore: use_build_context_synchronously
        NotificationServices.firebaseInit(context);
        // ignore: use_build_context_synchronously
        NotificationServices.setupInteractMessage(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Firebase Notifications'),
      ),
    );
  }
}
