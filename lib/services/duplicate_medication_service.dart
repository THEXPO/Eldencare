import '../models/medication.dart';
import '../utils/string_utils.dart';

class DuplicateMedicationMatch {
  const DuplicateMedicationMatch({
    required this.existing,
    required this.reason,
  });

  final Medication existing;
  final String reason;
}

class DuplicateMedicationService {
  const DuplicateMedicationService();

  List<DuplicateMedicationMatch> findPotentialDuplicates({
    required Medication candidate,
    required List<Medication> existing,
  }) {
    final name = StringUtils.normalize(candidate.name);
    final strength = StringUtils.normalize(candidate.strength);
    final form = candidate.dosageForm;

    return existing
        .where((med) => med.id != candidate.id && med.isActive)
        .where((med) {
          final sameName = StringUtils.normalize(med.name) == name;
          final sameStrength = StringUtils.normalize(med.strength) == strength;
          final sameForm = med.dosageForm == form;
          return sameName && sameStrength && sameForm;
        })
        .map((med) {
          return DuplicateMedicationMatch(
            existing: med,
            reason:
                'An active prescription for ${med.name} ${med.strength} '
                '(${med.dosageForm.name}) is already on file. Review it before adding another.',
          );
        })
        .toList();
  }
}
