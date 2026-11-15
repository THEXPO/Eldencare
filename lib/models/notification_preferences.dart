class NotificationPreferences {
  const NotificationPreferences({
    this.medicationRemindersEnabled = true,
    this.dietRemindersEnabled = true,
    this.exerciseRemindersEnabled = true,
    this.appointmentRemindersEnabled = true,
    this.caretakerAlertsEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.timezone = 'UTC',
  });

  final bool medicationRemindersEnabled;
  final bool dietRemindersEnabled;
  final bool exerciseRemindersEnabled;
  final bool appointmentRemindersEnabled;
  final bool caretakerAlertsEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final String timezone;

  NotificationPreferences copyWith({
    bool? medicationRemindersEnabled,
    bool? dietRemindersEnabled,
    bool? exerciseRemindersEnabled,
    bool? appointmentRemindersEnabled,
    bool? caretakerAlertsEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? timezone,
  }) {
    return NotificationPreferences(
      medicationRemindersEnabled:
          medicationRemindersEnabled ?? this.medicationRemindersEnabled,
      dietRemindersEnabled: dietRemindersEnabled ?? this.dietRemindersEnabled,
      exerciseRemindersEnabled:
          exerciseRemindersEnabled ?? this.exerciseRemindersEnabled,
      appointmentRemindersEnabled:
          appointmentRemindersEnabled ?? this.appointmentRemindersEnabled,
      caretakerAlertsEnabled:
          caretakerAlertsEnabled ?? this.caretakerAlertsEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      timezone: timezone ?? this.timezone,
    );
  }

  Map<String, dynamic> toJson() => {
    'medication_reminders_enabled': medicationRemindersEnabled,
    'diet_reminders_enabled': dietRemindersEnabled,
    'exercise_reminders_enabled': exerciseRemindersEnabled,
    'appointment_reminders_enabled': appointmentRemindersEnabled,
    'caretaker_alerts_enabled': caretakerAlertsEnabled,
    'quiet_hours_enabled': quietHoursEnabled,
    'quiet_hours_start': quietHoursStart,
    'quiet_hours_end': quietHoursEnd,
    'timezone': timezone,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      medicationRemindersEnabled:
          json['medication_reminders_enabled'] as bool? ?? true,
      dietRemindersEnabled: json['diet_reminders_enabled'] as bool? ?? true,
      exerciseRemindersEnabled:
          json['exercise_reminders_enabled'] as bool? ?? true,
      appointmentRemindersEnabled:
          json['appointment_reminders_enabled'] as bool? ?? true,
      caretakerAlertsEnabled:
          json['caretaker_alerts_enabled'] as bool? ?? true,
      quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? false,
      quietHoursStart: json['quiet_hours_start'] as String? ?? '22:00',
      quietHoursEnd: json['quiet_hours_end'] as String? ?? '07:00',
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }
}
