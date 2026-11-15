import { MedicationRecord } from '../types';

export interface DuplicateWarning {
  isDuplicate: boolean;
  matchedMedication?: MedicationRecord;
  reasons: string[];
}

export class DuplicateMedicationService {
  /**
   * Evaluates a candidate medication against a patient's existing active medications.
   * Checks normalized name, dosage form, strength, and scheduled timing overlap.
   */
  static checkDuplicate(
    candidate: { name: string; strength: string; dosage_form: string; scheduled_times_minutes?: number[] },
    existing: MedicationRecord[]
  ): DuplicateWarning {
    const normCandName = normalize(candidate.name);

    for (const med of existing) {
      if (!med.is_active) continue;

      const normExistingName = normalize(med.name);
      const reasons: string[] = [];

      // 1. Exact or high-similarity name match
      if (normCandName === normExistingName) {
        reasons.push(`Exact medicine name match: "${med.name}"`);
      } else if (normCandName.includes(normExistingName) || normExistingName.includes(normCandName)) {
        reasons.push(`Brand or generic formulation overlap with "${med.name}"`);
      }

      if (reasons.length > 0) {
        // 2. Strength match
        if (candidate.strength.toLowerCase() === med.strength.toLowerCase()) {
          reasons.push(`Identical strength: ${med.strength}`);
        }

        // 3. Form match
        if (candidate.dosage_form.toLowerCase() === med.dosage_form.toLowerCase()) {
          reasons.push(`Same dosage form: ${med.dosage_form}`);
        }

        // 4. Scheduled timing conflict
        if (candidate.scheduled_times_minutes && med.scheduled_times_minutes) {
          const overlap = candidate.scheduled_times_minutes.filter((t) =>
            med.scheduled_times_minutes.includes(t)
          );
          if (overlap.length > 0) {
            reasons.push(`Conflicting scheduled administration times`);
          }
        }

        return {
          isDuplicate: true,
          matchedMedication: med,
          reasons,
        };
      }
    }

    return { isDuplicate: false, reasons: [] };
  }
}

function normalize(str: string): string {
  return str.toLowerCase().replace(/[^a-z0-9]/g, '');
}
