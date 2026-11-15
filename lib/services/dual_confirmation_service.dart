import '../models/enums.dart';

class DualConfirmationService {
  const DualConfirmationService();

  OverallTaskStatus calculate({
    required ConfirmationResponse patient,
    required ConfirmationResponse caretaker,
    required bool dualEnabled,
  }) {
    if (!dualEnabled) {
      if (patient == ConfirmationResponse.pending &&
          caretaker == ConfirmationResponse.pending) {
        return OverallTaskStatus.awaitingConfirmation;
      }
      final resolved = patient != ConfirmationResponse.pending
          ? patient
          : caretaker;
      return resolved == ConfirmationResponse.completed
          ? OverallTaskStatus.completed
          : OverallTaskStatus.notCompleted;
    }

    if (patient == ConfirmationResponse.pending ||
        caretaker == ConfirmationResponse.pending) {
      return OverallTaskStatus.awaitingConfirmation;
    }

    if (patient == ConfirmationResponse.completed &&
        caretaker == ConfirmationResponse.completed) {
      return OverallTaskStatus.verified;
    }

    if (patient == ConfirmationResponse.notCompleted &&
        caretaker == ConfirmationResponse.notCompleted) {
      return OverallTaskStatus.verifiedNotCompleted;
    }

    return OverallTaskStatus.discrepancy;
  }

  bool isDiscrepancy(OverallTaskStatus status) =>
      status == OverallTaskStatus.discrepancy;
}
