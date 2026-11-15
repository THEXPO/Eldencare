import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../models/notification_preferences.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ec_card.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  Future<void> _pickTime({
    required BuildContext context,
    required String currentTime,
    required ValueChanged<String> onSelected,
  }) async {
    final parts = currentTime.split(':');
    final initialHour = int.tryParse(parts.first) ?? 22;
    final initialMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onSelected(formatted);
    }
  }

  String _formatTimeString(String time24) {
    final parts = time24.split(':');
    if (parts.length < 2) return time24;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h12:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final prefs = provider.preferences;
    final fcmToken = NotificationService.instance.currentToken;

    return Scaffold(
      backgroundColor: EldenColors.background,
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Section 1: Reminder Categories
          _buildSectionHeader(
            context,
            'Reminder Categories',
            'Choose the notifications you want to receive on this device.',
            Icons.notifications_active_outlined,
          ),
          const SizedBox(height: 12),
          EcCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.medication_outlined,
                  iconColor: EldenColors.teal,
                  title: 'Medication Reminders',
                  subtitle: 'Scheduled dosage alerts, timing, and dosage notes',
                  value: prefs.medicationRemindersEnabled,
                  onChanged: (val) {
                    provider.updatePreferences(
                      prefs.copyWith(medicationRemindersEnabled: val),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.restaurant_outlined,
                  iconColor: Colors.orange.shade700,
                  title: 'Diet & Meal Reminders',
                  subtitle: 'Scheduled meal times and dietary recommendations',
                  value: prefs.dietRemindersEnabled,
                  onChanged: (val) {
                    provider.updatePreferences(
                      prefs.copyWith(dietRemindersEnabled: val),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.fitness_center_outlined,
                  iconColor: Colors.blue.shade700,
                  title: 'Exercise & Activity Reminders',
                  subtitle: 'Gentle mobility and routine physical therapy alerts',
                  value: prefs.exerciseRemindersEnabled,
                  onChanged: (val) {
                    provider.updatePreferences(
                      prefs.copyWith(exerciseRemindersEnabled: val),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.calendar_today_outlined,
                  iconColor: Colors.purple.shade700,
                  title: 'Appointment Reminders',
                  subtitle: 'Doctor clinic visits: 24-hour and 1-hour prior alerts',
                  value: prefs.appointmentRemindersEnabled,
                  onChanged: (val) {
                    provider.updatePreferences(
                      prefs.copyWith(appointmentRemindersEnabled: val),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.security_outlined,
                  iconColor: EldenColors.discrepancy,
                  title: 'Caregiver & Discrepancy Alerts',
                  subtitle:
                      'Missed routines, dual confirmation updates, and vital warnings',
                  value: prefs.caretakerAlertsEnabled,
                  onChanged: (val) {
                    provider.updatePreferences(
                      prefs.copyWith(caretakerAlertsEnabled: val),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Quiet Hours
          _buildSectionHeader(
            context,
            'Quiet Hours',
            'Silence routine push reminders during resting and sleeping hours.',
            Icons.bedtime_outlined,
          ),
          const SizedBox(height: 12),
          EcCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Enable Quiet Hours',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Suppress non-urgent alerts during scheduled hours',
                    style: TextStyle(fontSize: 13, color: EldenColors.muted),
                  ),
                  value: prefs.quietHoursEnabled,
                  onChanged: (val) {
                    provider.updatePreferences(
                      prefs.copyWith(quietHoursEnabled: val),
                    );
                  },
                ),
                if (prefs.quietHoursEnabled) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TimePickerButton(
                          label: 'Starts At',
                          timeText: _formatTimeString(prefs.quietHoursStart),
                          onTap: () => _pickTime(
                            context: context,
                            currentTime: prefs.quietHoursStart,
                            onSelected: (newTime) {
                              provider.updatePreferences(
                                prefs.copyWith(quietHoursStart: newTime),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimePickerButton(
                          label: 'Ends At',
                          timeText: _formatTimeString(prefs.quietHoursEnd),
                          onTap: () => _pickTime(
                            context: context,
                            currentTime: prefs.quietHoursEnd,
                            onSelected: (newTime) {
                              provider.updatePreferences(
                                prefs.copyWith(quietHoursEnd: newTime),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.amber.shade900,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Emergency vital warnings and critical discrepancy alerts will bypass quiet hours for patient safety.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Registered Device & FCM Status
          _buildSectionHeader(
            context,
            'Device & Push Notification Status',
            'Firebase Cloud Messaging connection state.',
            Icons.phonelink_setup_outlined,
          ),
          const SizedBox(height: 12),
          EcCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: EldenColors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.cloud_done_outlined,
                        color: EldenColors.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FCM Registration Token',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fcmToken != null
                                ? 'Active (${fcmToken.length > 24 ? "${fcmToken.substring(0, 20)}..." : fcmToken})'
                                : 'Token pending or registered locally',
                            style: TextStyle(
                              fontSize: 12,
                              color: fcmToken != null
                                  ? EldenColors.success
                                  : EldenColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    // Send demo test notification
                    final testItem = AppNotification(
                      id: 'test-${DateTime.now().millisecondsSinceEpoch}',
                      title: 'Test Notification Delivered',
                      body:
                          'Your EldenCare push notification service is working properly.',
                      notificationType: 'general',
                      createdAt: DateTime.now(),
                    );
                    provider.addNotification(testItem);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification sent to history!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Send Test Notification'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: EldenColors.teal),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: EldenColors.ink,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: EldenColors.muted),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: EldenColors.muted),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  const _TimePickerButton({
    required this.label,
    required this.timeText,
    required this.onTap,
  });

  final String label;
  final String timeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: EldenColors.muted),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: EldenColors.teal),
                const SizedBox(width: 6),
                Text(
                  timeText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: EldenColors.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
