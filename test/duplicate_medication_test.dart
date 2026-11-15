import 'package:eldencare/models/enums.dart';
import 'package:eldencare/models/medication.dart';
import 'package:eldencare/services/duplicate_medication_service.dart';
import 'package:flutter_test/flutter_test.dart';

Medication _med({
  required String id,
  required String name,
  String strength = '10 mg',
  DosageForm form = DosageForm.tablet,
  bool active = true,
}) {
  return Medication(
    id: id,
    name: name,
    strength: strength,
    dosage: '1 tablet',
    dosageForm: form,
    scheduledTimesMinutes: const [480],
    mealInstruction: 'After breakfast',
    startDate: DateTime(2026, 1, 1),
    isActive: active,
  );
}

void main() {
  const service = DuplicateMedicationService();

  test('detects active duplicate by normalized name, strength, and form', () {
    final existing = [
      _med(id: '1', name: 'Lisinopril'),
      _med(id: '2', name: 'Metformin', strength: '500 mg'),
    ];
    final matches = service.findPotentialDuplicates(
      candidate: _med(id: 'new', name: '  LISINOPRIL '),
      existing: existing,
    );
    expect(matches, hasLength(1));
    expect(matches.first.existing.id, '1');
  });

  test('ignores inactive prescriptions', () {
    final matches = service.findPotentialDuplicates(
      candidate: _med(id: 'new', name: 'Lisinopril'),
      existing: [_med(id: '1', name: 'Lisinopril', active: false)],
    );
    expect(matches, isEmpty);
  });

  test('different strength is not a duplicate', () {
    final matches = service.findPotentialDuplicates(
      candidate: _med(id: 'new', name: 'Lisinopril', strength: '20 mg'),
      existing: [_med(id: '1', name: 'Lisinopril', strength: '10 mg')],
    );
    expect(matches, isEmpty);
  });

  test('does not match the same record when editing', () {
    final med = _med(id: '1', name: 'Lisinopril');
    final matches = service.findPotentialDuplicates(
      candidate: med,
      existing: [med],
    );
    expect(matches, isEmpty);
  });
}
