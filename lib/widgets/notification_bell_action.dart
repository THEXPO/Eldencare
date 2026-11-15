import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../screens/notifications/notification_history_screen.dart';
import '../theme/app_theme.dart';

class NotificationBellAction extends StatelessWidget {
  const NotificationBellAction({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final unreadCount = notifProvider.unreadCount;

    return IconButton(
      tooltip: 'Notifications',
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        backgroundColor: EldenColors.discrepancy,
        label: Text(
          unreadCount > 9 ? '9+' : '$unreadCount',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const NotificationHistoryScreen(),
          ),
        );
      },
    );
  }
}
