import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: const Center(
        child: Text(
          'No notifications yet.',
          style: TextStyle(color: AppTheme.lightTextColor, fontSize: 16),
        ),
      ),
    );
  }
}