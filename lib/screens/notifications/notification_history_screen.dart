import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ec_card.dart';
import 'notification_preferences_screen.dart';

class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;

    return Scaffold(
      backgroundColor: EldenColors.background,
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        actions: [
          IconButton(
            tooltip: 'Notification Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationPreferencesScreen(),
                ),
              );
            },
          ),
          if (notifProvider.unreadCount > 0)
            TextButton(
              onPressed: () => notifProvider.markAllAsRead(),
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: EldenColors.muted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: EldenColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Reminders and alerts will appear here.',
                    style: TextStyle(fontSize: 13, color: EldenColors.muted),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NotificationCard(
                    notification: item,
                    onTap: () {
                      if (!item.isRead) {
                        notifProvider.markAsRead(item.id);
                      }
                      _showDetailDialog(context, item);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showDetailDialog(BuildContext context, AppNotification item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            _buildTypeIcon(item.notificationType),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.body, style: const TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Received:', style: TextStyle(fontSize: 12, color: EldenColors.muted)),
                Text(
                  DateFormat.yMMMd().add_jm().format(item.createdAt),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'medication':
        icon = Icons.medication_rounded;
        color = EldenColors.teal;
        break;
      case 'diet':
        icon = Icons.restaurant_rounded;
        color = EldenColors.tealDark;
        break;
      case 'exercise':
        icon = Icons.directions_walk_rounded;
        color = EldenColors.success;
        break;
      case 'appointment':
        icon = Icons.calendar_today_rounded;
        color = EldenColors.warning;
        break;
      case 'dual_confirmation':
      case 'caretaker_alert':
        icon = Icons.warning_amber_rounded;
        color = EldenColors.discrepancy;
        break;
      default:
        icon = Icons.notifications_active_rounded;
        color = EldenColors.teal;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EcCard(
      onTap: onTap,
      borderColor: notification.isRead ? null : EldenColors.teal.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NotificationHistoryScreen._buildTypeIcon(notification.notificationType),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 15,
                            color: EldenColors.text,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: EldenColors.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: notification.isRead ? EldenColors.muted : EldenColors.text,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatRelativeTime(notification.createdAt),
                    style: const TextStyle(fontSize: 11, color: EldenColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat.MMMd().format(dt);
  }
}
