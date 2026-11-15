import { ConfirmationRecord } from '../types';

export type TaskStatus = 'awaiting_confirmation' | 'verified' | 'discrepancy' | 'completed';

export interface DualStatusResult {
  status: TaskStatus;
  isDiscrepancy: boolean;
  patientResponse?: 'completed' | 'not_completed';
  caretakerResponse?: 'completed' | 'not_completed';
}

export class DualConfirmationService {
  /**
   * Calculates the overall verification status based on independent patient and caretaker responses.
   */
  static calculateStatus(
    confirmations: ConfirmationRecord[],
    dualConfirmationEnabled: boolean = true
  ): DualStatusResult {
    const patientConf = confirmations.find((c) => c.actor_role === 'patient');
    const caretakerConf = confirmations.find((c) => c.actor_role === 'caretaker');

    if (!dualConfirmationEnabled) {
      const single = patientConf || caretakerConf;
      if (!single) return { status: 'awaiting_confirmation', isDiscrepancy: false };
      return {
        status: single.response === 'completed' ? 'completed' : 'awaiting_confirmation',
        isDiscrepancy: false,
        patientResponse: patientConf?.response,
        caretakerResponse: caretakerConf?.response,
      };
    }

    // Both parties have submitted
    if (patientConf && caretakerConf) {
      if (patientConf.response === caretakerConf.response) {
        return {
          status: patientConf.response === 'completed' ? 'verified' : 'awaiting_confirmation',
          isDiscrepancy: false,
          patientResponse: patientConf.response,
          caretakerResponse: caretakerConf.response,
        };
      } else {
        // Conflicting responses -> Discrepancy!
        return {
          status: 'discrepancy',
          isDiscrepancy: true,
          patientResponse: patientConf.response,
          caretakerResponse: caretakerConf.response,
        };
      }
    }

    // Pending response from one or both
    return {
      status: 'awaiting_confirmation',
      isDiscrepancy: false,
      patientResponse: patientConf?.response,
      caretakerResponse: caretakerConf?.response,
    };
  }
}
