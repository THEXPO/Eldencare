import 'package:eldencare/models/enums.dart';
import 'package:eldencare/services/dual_confirmation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = DualConfirmationService();

  test(
    'status moves from awaiting to awaiting after only one confirmation',
    () {
      const start = ConfirmationResponse.pending;
      final afterPatient = service.calculate(
        patient: ConfirmationResponse.completed,
        caretaker: start,
        dualEnabled: true,
      );
      expect(afterPatient, OverallTaskStatus.awaitingConfirmation);
    },
  );

  test('status moves to verified after matching completions', () {
    final status = service.calculate(
      patient: ConfirmationResponse.completed,
      caretaker: ConfirmationResponse.completed,
      dualEnabled: true,
    );
    expect(status, OverallTaskStatus.verified);
  });

  test('status moves to discrepancy after conflicting completions', () {
    final status = service.calculate(
      patient: ConfirmationResponse.completed,
      caretaker: ConfirmationResponse.notCompleted,
      dualEnabled: true,
    );
    expect(status, OverallTaskStatus.discrepancy);
    expect(service.isDiscrepancy(status), isTrue);
  });

  test('changing a matching pair into conflict records discrepancy', () {
    final agreed = service.calculate(
      patient: ConfirmationResponse.completed,
      caretaker: ConfirmationResponse.completed,
      dualEnabled: true,
    );
    expect(agreed, OverallTaskStatus.verified);

    final changed = service.calculate(
      patient: ConfirmationResponse.completed,
      caretaker: ConfirmationResponse.notCompleted,
      dualEnabled: true,
    );
    expect(changed, OverallTaskStatus.discrepancy);
  });
}
