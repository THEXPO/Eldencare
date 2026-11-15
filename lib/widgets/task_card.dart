import 'package:flutter/material.dart';

import '../models/daily_task.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import 'status_badge.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.status,
    required this.large,
    this.onCompleted,
    this.onNotCompleted,
    this.showBothResponses = false,
    this.completedLabel = 'Completed',
    this.notCompletedLabel = 'Not done',
  });

  final DailyTask task;
  final OverallTaskStatus status;
  final bool large;
  final VoidCallback? onCompleted;
  final VoidCallback? onNotCompleted;
  final bool showBothResponses;
  final String completedLabel;
  final String notCompletedLabel;

  IconData get _icon => switch (task.type) {
    TaskType.medication => Icons.medication_rounded,
    TaskType.diet => Icons.restaurant_rounded,
    TaskType.exercise => Icons.directions_walk_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = StatusPalette.color(status);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.4),
      ),
      child: Padding(
        padding: EdgeInsets.all(large ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: large ? 26 : 22,
                  backgroundColor: EldenColors.teal.withValues(alpha: 0.12),
                  child: Icon(
                    _icon,
                    color: EldenColors.teal,
                    size: large ? 28 : 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppDateUtils.formatTimeMinutes(
                          task.scheduledTimeMinutes,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: large ? 20 : 16,
                          color: EldenColors.tealDark,
                        ),
                      ),
                      Text(
                        task.type.label,
                        style: TextStyle(
                          color: EldenColors.muted,
                          fontSize: large ? 16 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: status, large: large),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.title,
              style: TextStyle(
                fontSize: large ? 22 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(task.subtitle, style: TextStyle(fontSize: large ? 18 : 14)),
            const SizedBox(height: 6),
            Text(
              task.description,
              style: TextStyle(
                fontSize: large ? 17 : 14,
                color: EldenColors.muted,
              ),
            ),
            if (task.instructions != null) ...[
              const SizedBox(height: 8),
              Text(
                task.instructions!,
                style: TextStyle(
                  fontSize: large ? 16 : 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (showBothResponses ||
                status == OverallTaskStatus.discrepancy) ...[
              const SizedBox(height: 12),
              _ResponseRow(
                label: 'Patient',
                value: task.patientConfirmation.label,
                at: task.patientConfirmedAt,
                large: large,
              ),
              const SizedBox(height: 4),
              _ResponseRow(
                label: 'Caretaker',
                value: switch (task.caretakerConfirmation) {
                  ConfirmationResponse.completed => 'Verified',
                  ConfirmationResponse.notCompleted => 'Not done',
                  ConfirmationResponse.pending => 'Pending',
                },
                at: task.caretakerConfirmedAt,
                large: large,
              ),
            ],
            if (status == OverallTaskStatus.discrepancy) ...[
              const SizedBox(height: 10),
              Text(
                'The two confirmations do not match. This is a discrepancy to review together — it does not by itself prove that care was missed.',
                style: TextStyle(
                  color: EldenColors.discrepancy,
                  fontSize: large ? 16 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (onCompleted != null || onNotCompleted != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onCompleted,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(completedLabel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onNotCompleted,
                      icon: const Icon(Icons.close_rounded),
                      label: Text(notCompletedLabel),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResponseRow extends StatelessWidget {
  const _ResponseRow({
    required this.label,
    required this.value,
    required this.at,
    required this.large,
  });

  final String label;
  final String value;
  final DateTime? at;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Text(
      at == null
          ? '$label: $value'
          : '$label: $value · ${AppDateUtils.formatDateTime(at!)}',
      style: TextStyle(fontSize: large ? 16 : 13),
    );
  }
}
