import 'package:eldencare/models/enums.dart';
import 'package:eldencare/services/dual_confirmation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = DualConfirmationService();

  group('dual confirmation enabled', () {
    test('completed + completed = verified', () {
      expect(
        service.calculate(
          patient: ConfirmationResponse.completed,
          caretaker: ConfirmationResponse.completed,
          dualEnabled: true,
        ),
        OverallTaskStatus.verified,
      );
    });

    test('not completed + not completed = verified not completed', () {
      expect(
        service.calculate(
          patient: ConfirmationResponse.notCompleted,
          caretaker: ConfirmationResponse.notCompleted,
          dualEnabled: true,
        ),
        OverallTaskStatus.verifiedNotCompleted,
      );
    });

    test('completed + not completed = discrepancy', () {
      expect(
        service.calculate(
          patient: ConfirmationResponse.completed,
          caretaker: ConfirmationResponse.notCompleted,
          dualEnabled: true,
        ),
        OverallTaskStatus.discrepancy,
      );
    });

    test('not completed + completed = discrepancy', () {
      expect(
        service.calculate(
          patient: ConfirmationResponse.notCompleted,
          caretaker: ConfirmationResponse.completed,
          dualEnabled: true,
        ),
        OverallTaskStatus.discrepancy,
      );
    });

    test('pending + any = awaiting confirmation', () {
      expect(
        service.calculate(
          patient: ConfirmationResponse.pending,
          caretaker: ConfirmationResponse.completed,
          dualEnabled: true,
        ),
        OverallTaskStatus.awaitingConfirmation,
      );
      expect(
        service.calculate(
          patient: ConfirmationResponse.completed,
          caretaker: ConfirmationResponse.pending,
          dualEnabled: true,
        ),
        OverallTaskStatus.awaitingConfirmation,
      );
    });
  });

  group('dual confirmation disabled', () {
    test('both pending stays awaiting', () {
      expect(
        service.calculate(
          patient: ConfirmationResponse.pending,
          caretaker: ConfirmationResponse.pending,
          dualEnabled: false,
        ),
        OverallTaskStatus.awaitingConfirmation,
      );
    });

    test('patient completed is enough', () {
      expect(
        service.calculate(
          patient: ConfirmationResponse.completed,
          caretaker: ConfirmationResponse.pending,
          dualEnabled: false,
        ),
        OverallTaskStatus.completed,
      );
    });
  });
}
