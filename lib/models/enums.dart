enum AppRole { patient, caretaker, doctor }

enum CarePlanStatus { draft, active, superseded }

enum TaskType { medication, diet, exercise }

enum MealSlot { breakfast, lunch, eveningSnack, dinner }

enum ConfirmationResponse { pending, completed, notCompleted }

enum OverallTaskStatus {
  awaitingConfirmation,
  verified,
  verifiedNotCompleted,
  discrepancy,
  completed,
  notCompleted,
}

enum DosageForm { tablet, capsule, liquid, injection, inhaler, cream, other }

enum GlucoseUnit { mgDl, mmolL }

extension MealSlotLabel on MealSlot {
  String get label => switch (this) {
    MealSlot.breakfast => 'Breakfast',
    MealSlot.lunch => 'Lunch',
    MealSlot.eveningSnack => 'Evening snack',
    MealSlot.dinner => 'Dinner',
  };
}

extension TaskTypeLabel on TaskType {
  String get label => switch (this) {
    TaskType.medication => 'Medication',
    TaskType.diet => 'Diet',
    TaskType.exercise => 'Exercise',
  };
}

extension DosageFormLabel on DosageForm {
  String get label => switch (this) {
    DosageForm.tablet => 'Tablet',
    DosageForm.capsule => 'Capsule',
    DosageForm.liquid => 'Liquid',
    DosageForm.injection => 'Injection',
    DosageForm.inhaler => 'Inhaler',
    DosageForm.cream => 'Cream',
    DosageForm.other => 'Other',
  };
}

extension GlucoseUnitLabel on GlucoseUnit {
  String get label => switch (this) {
    GlucoseUnit.mgDl => 'mg/dL',
    GlucoseUnit.mmolL => 'mmol/L',
  };
}

extension ConfirmationResponseLabel on ConfirmationResponse {
  String get label => switch (this) {
    ConfirmationResponse.pending => 'Pending',
    ConfirmationResponse.completed => 'Completed',
    ConfirmationResponse.notCompleted => 'Not completed',
  };
}

extension OverallTaskStatusLabel on OverallTaskStatus {
  String get label => switch (this) {
    OverallTaskStatus.awaitingConfirmation => 'Awaiting confirmation',
    OverallTaskStatus.verified => 'Verified',
    OverallTaskStatus.verifiedNotCompleted => 'Verified (not completed)',
    OverallTaskStatus.discrepancy => 'Discrepancy',
    OverallTaskStatus.completed => 'Completed',
    OverallTaskStatus.notCompleted => 'Not completed',
  };
}

extension CarePlanStatusLabel on CarePlanStatus {
  String get label => switch (this) {
    CarePlanStatus.draft => 'Draft',
    CarePlanStatus.active => 'Active',
    CarePlanStatus.superseded => 'Superseded',
  };
}
