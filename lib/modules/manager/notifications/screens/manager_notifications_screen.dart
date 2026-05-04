import 'package:flutter/material.dart';

import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/repositories/notification_repository.dart';
import 'package:guardgrey/features/notifications/screens/notifications_screen.dart';
import 'package:guardgrey/modules/manager/common/services/manager_session_service.dart';

class ManagerNotificationsScreen extends StatelessWidget {
  const ManagerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ManagerModel?>(
      stream: ManagerSessionService.instance.watchCurrentManager(),
      builder: (context, snapshot) {
        final manager = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting &&
            manager == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (manager == null) {
          return const Scaffold(
            body: Center(child: Text('Unable to load notifications.')),
          );
        }

        return NotificationsScreen(
          title: 'Notifications',
          recipientKey: NotificationRepository.userRecipientKey(manager.id),
        );
      },
    );
  }
}
