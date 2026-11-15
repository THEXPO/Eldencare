import 'enums.dart';

class DailyTask {
  const DailyTask({
    required this.instanceId,
    required this.templateId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.scheduledTimeMinutes,
    required this.date,
    required this.dualConfirmationEnabled,
    required this.patientConfirmation,
    required this.caretakerConfirmation,
    this.instructions,
    this.patientConfirmedAt,
    this.caretakerConfirmedAt,
    this.patientActorName,
    this.caretakerActorName,
  });

  final String instanceId;
  final String templateId;
  final TaskType type;
  final String title;
  final String subtitle;
  final String description;
  final int scheduledTimeMinutes;
  final DateTime date;
  final bool dualConfirmationEnabled;
  final ConfirmationResponse patientConfirmation;
  final ConfirmationResponse caretakerConfirmation;
  final String? instructions;
  final DateTime? patientConfirmedAt;
  final DateTime? caretakerConfirmedAt;
  final String? patientActorName;
  final String? caretakerActorName;

  static String buildInstanceId({
    required TaskType type,
    required String templateId,
    required DateTime date,
    required int scheduledTimeMinutes,
  }) {
    final key =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '${type.name}|$templateId|$key|$scheduledTimeMinutes';
  }
}
