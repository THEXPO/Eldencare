import 'package:uuid/uuid.dart';

import '../models/appointment.dart';
import '../models/care_plan_version.dart';
import '../models/care_snapshot.dart';
import '../models/confirmation.dart';
import '../models/consultation_note.dart';
import '../models/daily_task.dart';
import '../models/diet_entry.dart';
import '../models/doctor_notification.dart';
import '../models/enums.dart';
import '../models/exercise_entry.dart';
import '../models/health_reading.dart';
import '../models/medication.dart';
import '../models/patient.dart';

class SeedData {
  static const _uuid = Uuid();

  static CareSnapshot build({DateTime? now}) {
    final today = now ?? DateTime.now();
    final day = DateTime(today.year, today.month, today.day);

    final patient = Patient(
      id: 'patient-eleanor-hart',
      fullName: 'Eleanor Margaret Hart',
      preferredName: 'Ellie',
      dateOfBirth: DateTime(1948, 4, 12),
      conditions: ['Hypertension', 'Type 2 diabetes', 'Mild osteoarthritis'],
      caretakerName: 'Priya Hart',
      caretakerRelation: 'Daughter',
      notes:
          'Prefers morning walks in the garden. Sensitive to very spicy food.',
    );

    final lisinopril = Medication(
      id: 'med-lisinopril',
      name: 'Lisinopril',
      strength: '10 mg',
      dosage: '1 tablet',
      dosageForm: DosageForm.tablet,
      scheduledTimesMinutes: const [480],
      mealInstruction: 'After breakfast',
      startDate: day.subtract(const Duration(days: 120)),
      additionalInstructions: 'Take with a full glass of water.',
    );
    final metformin = Medication(
      id: 'med-metformin',
      name: 'Metformin',
      strength: '500 mg',
      dosage: '1 tablet',
      dosageForm: DosageForm.tablet,
      scheduledTimesMinutes: const [480, 1200],
      mealInstruction: 'With meals',
      startDate: day.subtract(const Duration(days: 200)),
      additionalInstructions: 'Take with food to reduce stomach upset.',
    );
    final atorvastatin = Medication(
      id: 'med-atorvastatin',
      name: 'Atorvastatin',
      strength: '20 mg',
      dosage: '1 tablet',
      dosageForm: DosageForm.tablet,
      scheduledTimesMinutes: const [1260],
      mealInstruction: 'After dinner',
      startDate: day.subtract(const Duration(days: 90)),
    );
    final amlodipine = Medication(
      id: 'med-amlodipine',
      name: 'Amlodipine',
      strength: '5 mg',
      dosage: '1 tablet',
      dosageForm: DosageForm.tablet,
      scheduledTimesMinutes: const [480],
      mealInstruction: 'After breakfast',
      startDate: day.subtract(const Duration(days: 60)),
    );

    const breakfast = DietEntry(
      id: 'diet-breakfast',
      slot: MealSlot.breakfast,
      title: 'Oatmeal with berries',
      description:
          'Half cup oats, a handful of blueberries, and unsweetened almond milk.',
      scheduledTimeMinutes: 480,
      instructions: 'Doctor-approved low-sodium breakfast.',
    );
    const lunch = DietEntry(
      id: 'diet-lunch',
      slot: MealSlot.lunch,
      title: 'Grilled fish and vegetables',
      description:
          'Baked salmon, steamed broccoli, and a small portion of rice.',
      scheduledTimeMinutes: 750,
      instructions: 'Limit added salt.',
    );
    const snack = DietEntry(
      id: 'diet-snack',
      slot: MealSlot.eveningSnack,
      title: 'Apple and a handful of almonds',
      description: 'One small apple with 6 unsalted almonds.',
      scheduledTimeMinutes: 960,
    );
    const dinner = DietEntry(
      id: 'diet-dinner',
      slot: MealSlot.dinner,
      title: 'Vegetable lentil soup',
      description:
          'Warm lentil soup with mixed vegetables and a slice of whole-grain bread.',
      scheduledTimeMinutes: 1140,
      instructions: 'Finish eating at least two hours before bedtime.',
    );

    const walk = ExerciseEntry(
      id: 'ex-walk',
      title: 'Morning walk',
      description: '20-minute gentle walk around the garden or corridor.',
      scheduledTimeMinutes: 450,
      instructions: 'Wear supportive shoes. Rest if dizzy.',
    );
    const breathing = ExerciseEntry(
      id: 'ex-breathing',
      title: 'Breathing exercises',
      description: 'Five minutes of slow belly breathing while seated.',
      scheduledTimeMinutes: 600,
    );
    const physio = ExerciseEntry(
      id: 'ex-physio',
      title: 'Physiotherapy exercises',
      description:
          'Knee and hip mobility set recommended by the physiotherapist.',
      scheduledTimeMinutes: 1020,
      instructions: 'Stop if pain is sharp. Mild stiffness is expected.',
    );

    final appointments = [
      Appointment(
        id: 'apt-cardio',
        doctorName: 'Dr. Sarah Nguyen',
        speciality: 'Cardiology',
        dateTime: day.add(const Duration(days: 3, hours: 10, minutes: 30)),
        location: 'Riverside Heart Clinic, Room 214',
        notes: 'Bring the home blood-pressure log.',
      ),
      Appointment(
        id: 'apt-endo',
        doctorName: 'Dr. Arjun Patel',
        speciality: 'Endocrinology',
        dateTime: day.add(const Duration(days: 12, hours: 14)),
        location: 'Greenfield Medical Centre',
        notes: 'Review glucose readings and Metformin dose.',
      ),
      Appointment(
        id: 'apt-past',
        doctorName: 'Dr. Helen Cho',
        speciality: 'General practice',
        dateTime: day.subtract(const Duration(days: 8, hours: 4)),
        location: 'Harbour Family Clinic',
        notes: 'Annual review completed.',
      ),
    ];

    final bp = List<BloodPressureReading>.generate(6, (index) {
      final when = day
          .subtract(Duration(days: 5 - index))
          .add(const Duration(hours: 8, minutes: 15));
      return BloodPressureReading(
        id: 'bp-$index',
        systolic: 128 + (index % 3) * 4,
        diastolic: 78 + (index % 2) * 3,
        recordedAt: when,
        recordedBy: index.isEven ? 'Priya Hart' : 'Ellie Hart',
        notes: index == 5 ? 'Taken after morning medication.' : null,
      );
    });

    final glucose = List<GlucoseReading>.generate(6, (index) {
      final when = day
          .subtract(Duration(days: 5 - index))
          .add(const Duration(hours: 7, minutes: 40));
      return GlucoseReading(
        id: 'glu-$index',
        value: 108 + (index % 4) * 6,
        unit: GlucoseUnit.mgDl,
        recordedAt: when,
        recordedBy: index.isOdd ? 'Priya Hart' : 'Ellie Hart',
      );
    });

    String instance({
      required TaskType type,
      required String templateId,
      required int minutes,
      DateTime? on,
    }) {
      return DailyTask.buildInstanceId(
        type: type,
        templateId: templateId,
        date: on ?? day,
        scheduledTimeMinutes: minutes,
      );
    }

    final confirmations = [
      ConfirmationRecord(
        id: _uuid.v4(),
        taskInstanceId: instance(
          type: TaskType.exercise,
          templateId: walk.id,
          minutes: 450,
        ),
        actor: AppRole.patient,
        response: ConfirmationResponse.completed,
        timestamp: day.add(const Duration(hours: 7, minutes: 40)),
        actorName: patient.preferredName,
      ),
      ConfirmationRecord(
        id: _uuid.v4(),
        taskInstanceId: instance(
          type: TaskType.exercise,
          templateId: walk.id,
          minutes: 450,
        ),
        actor: AppRole.caretaker,
        response: ConfirmationResponse.completed,
        timestamp: day.add(const Duration(hours: 8, minutes: 5)),
        actorName: patient.caretakerName,
      ),
      ConfirmationRecord(
        id: _uuid.v4(),
        taskInstanceId: instance(
          type: TaskType.medication,
          templateId: lisinopril.id,
          minutes: 480,
        ),
        actor: AppRole.patient,
        response: ConfirmationResponse.completed,
        timestamp: day.add(const Duration(hours: 8, minutes: 10)),
        actorName: patient.preferredName,
      ),
      ConfirmationRecord(
        id: _uuid.v4(),
        taskInstanceId: instance(
          type: TaskType.medication,
          templateId: metformin.id,
          minutes: 480,
        ),
        actor: AppRole.patient,
        response: ConfirmationResponse.completed,
        timestamp: day.add(const Duration(hours: 8, minutes: 12)),
        actorName: patient.preferredName,
      ),
      ConfirmationRecord(
        id: _uuid.v4(),
        taskInstanceId: instance(
          type: TaskType.medication,
          templateId: metformin.id,
          minutes: 480,
        ),
        actor: AppRole.caretaker,
        response: ConfirmationResponse.notCompleted,
        timestamp: day.add(const Duration(hours: 9, minutes: 20)),
        actorName: patient.caretakerName,
      ),
      ConfirmationRecord(
        id: _uuid.v4(),
        taskInstanceId: instance(
          type: TaskType.diet,
          templateId: breakfast.id,
          minutes: 480,
        ),
        actor: AppRole.patient,
        response: ConfirmationResponse.completed,
        timestamp: day.add(const Duration(hours: 8, minutes: 25)),
        actorName: patient.preferredName,
      ),
    ];

    final discrepancies = [
      DiscrepancyEvent(
        id: _uuid.v4(),
        taskInstanceId: instance(
          type: TaskType.medication,
          templateId: metformin.id,
          minutes: 480,
        ),
        taskTitle: 'Metformin 500 mg',
        occurredAt: day.add(const Duration(hours: 9, minutes: 20)),
        patientResponse: ConfirmationResponse.completed,
        caretakerResponse: ConfirmationResponse.notCompleted,
        patientActorName: patient.preferredName,
        caretakerActorName: patient.caretakerName,
      ),
    ];

    final initialPlanVersion = CarePlanVersion(
      id: 'plan-eleanor-v1',
      patientId: patient.id,
      versionNumber: 1,
      title: 'Cardiometabolic & Mobility Regimen',
      doctorName: 'Dr. Sarah Nguyen',
      createdAt: day.subtract(const Duration(days: 30)),
      status: CarePlanStatus.active,
      summaryOfChanges:
          'Baseline geriatric plan: dual anti-hypertensive therapy, Metformin for glycemic control, and low-sodium daily meals.',
      medications: [lisinopril, metformin, atorvastatin, amlodipine],
      dietEntries: [breakfast, lunch, snack, dinner],
      exercises: [walk, breathing, physio],
    );

    final initialNote = ConsultationNote(
      id: 'note-eleanor-1',
      patientId: patient.id,
      doctorName: 'Dr. Sarah Nguyen',
      date: day.subtract(const Duration(days: 7)),
      observations:
          'Ellie appears comfortable and in good spirits. Blood pressure has stabilized well around 128/78 mmHg. Morning blood sugar is well regulated.',
      followUpInstructions:
          'Continue Lisinopril 10 mg and Amlodipine 5 mg daily. Remember to take Metformin with meals to avoid mild GI symptoms. Keep up morning walks.',
      suggestedFollowUpDate: day.add(const Duration(days: 14)),
    );

    final notifications = [
      DoctorNotification(
        id: 'notif-1',
        title: 'Discrepancy Detected',
        message:
            'Metformin 500 mg has conflicting confirmations for Eleanor Hart.',
        timestamp: day.add(const Duration(hours: 9, minutes: 25)),
        category: 'discrepancy',
        patientId: patient.id,
        patientName: patient.fullName,
      ),
      DoctorNotification(
        id: 'notif-2',
        title: 'Health Log Updated',
        message: 'New blood pressure reading (132/81 mmHg) logged by Priya.',
        timestamp: day.subtract(const Duration(hours: 4)),
        category: 'healthReading',
        patientId: patient.id,
        patientName: patient.fullName,
      ),
      DoctorNotification(
        id: 'notif-3',
        title: 'Care Plan Active',
        message:
            'Dr. Sarah Nguyen activated Care Plan v1 for Eleanor Margaret Hart.',
        timestamp: day.subtract(const Duration(days: 30)),
        category: 'carePlan',
        patientId: patient.id,
        patientName: patient.fullName,
      ),
    ];

    // Patient 2: Arthur James Vance
    final arthur = Patient(
      id: 'patient-arthur-vance',
      fullName: 'Arthur James Vance',
      preferredName: 'Arthur',
      dateOfBirth: DateTime(1946, 8, 15),
      conditions: [
        'Coronary artery disease',
        'Mild cognitive impairment',
        'Hypertension',
      ],
      caretakerName: 'Robert Vance',
      caretakerRelation: 'Son',
      notes:
          'Enjoys listening to classical music in afternoons. Needs memory cues for hydration.',
    );
    final arthurDonepezil = Medication(
      id: 'med-arthur-donepezil',
      name: 'Donepezil',
      strength: '5 mg',
      dosage: '1 tablet',
      dosageForm: DosageForm.tablet,
      scheduledTimesMinutes: const [1260],
      mealInstruction: 'At bedtime',
      startDate: day.subtract(const Duration(days: 180)),
      additionalInstructions: 'Take right before sleep.',
    );
    final arthurAspirin = Medication(
      id: 'med-arthur-aspirin',
      name: 'Aspirin (Cardio)',
      strength: '75 mg',
      dosage: '1 tablet',
      dosageForm: DosageForm.tablet,
      scheduledTimesMinutes: const [510],
      mealInstruction: 'After breakfast',
      startDate: day.subtract(const Duration(days: 300)),
    );
    final arthurBp = List<BloodPressureReading>.generate(4, (index) {
      return BloodPressureReading(
        id: 'arthur-bp-$index',
        systolic: 132 + index * 2,
        diastolic: 82 + index,
        recordedAt: day.subtract(Duration(days: 4 - index)),
        recordedBy: 'Robert Vance',
      );
    });
    final arthurGlu = List<GlucoseReading>.generate(4, (index) {
      return GlucoseReading(
        id: 'arthur-glu-$index',
        value: 96 + index * 3,
        unit: GlucoseUnit.mgDl,
        recordedAt: day.subtract(Duration(days: 4 - index)),
        recordedBy: 'Robert Vance',
      );
    });
    final arthurSnapshot = CareSnapshot(
      patient: arthur,
      medications: [arthurDonepezil, arthurAspirin],
      dietEntries: [
        const DietEntry(
          id: 'arthur-breakfast',
          slot: MealSlot.breakfast,
          title: 'Porridge with banana slices',
          description: 'Whole grain oats with sliced fresh banana.',
          scheduledTimeMinutes: 510,
        ),
        const DietEntry(
          id: 'arthur-lunch',
          slot: MealSlot.lunch,
          title: 'Steamed chicken and brown rice',
          description: 'Lightly seasoned chicken breast with steamed greens.',
          scheduledTimeMinutes: 780,
        ),
      ],
      exercises: [
        const ExerciseEntry(
          id: 'arthur-walk',
          title: 'Garden walk with caretaker',
          description: '15-minute guided stroll in the garden.',
          scheduledTimeMinutes: 600,
        ),
      ],
      appointments: [
        Appointment(
          id: 'apt-arthur-cardio',
          doctorName: 'Dr. Sarah Nguyen',
          speciality: 'Cardiology',
          dateTime: day.add(const Duration(days: 5, hours: 11)),
          location: 'Riverside Heart Clinic, Room 214',
          notes: 'Routine 6-month coronary review.',
        ),
      ],
      bloodPressureReadings: arthurBp,
      glucoseReadings: arthurGlu,
      confirmations: const [],
      discrepancies: const [],
      dualSettings: const DualConfirmationSettings(),
      carePlanVersions: [
        CarePlanVersion(
          id: 'plan-arthur-v1',
          patientId: arthur.id,
          versionNumber: 1,
          title: 'Vascular & Cognitive Support Plan',
          doctorName: 'Dr. Sarah Nguyen',
          createdAt: day.subtract(const Duration(days: 60)),
          status: CarePlanStatus.active,
          summaryOfChanges:
              'Initial regimen prioritizing cardiovascular protection and bedtime memory support.',
          medications: [arthurDonepezil, arthurAspirin],
          dietEntries: const [],
          exercises: const [],
        ),
      ],
      consultationNotes: [
        ConsultationNote(
          id: 'note-arthur-1',
          patientId: arthur.id,
          doctorName: 'Dr. Sarah Nguyen',
          date: day.subtract(const Duration(days: 20)),
          observations:
              'Cognitive status stable. Blood pressure consistently within target (approx 134/84). Son reports good adherence.',
          followUpInstructions:
              'Continue Donepezil and low-dose Aspirin. Encourage gentle physical activity.',
          suggestedFollowUpDate: day.add(const Duration(days: 10)),
        ),
      ],
    );

    // Patient 3: Kamala Devi Sharma
    final kamala = Patient(
      id: 'patient-kamala-sharma',
      fullName: 'Kamala Devi Sharma',
      preferredName: 'Kamala',
      dateOfBirth: DateTime(1952, 11, 20),
      conditions: ['Osteoarthritis', 'Type 2 Diabetes mellitus'],
      caretakerName: 'Sunita Sharma',
      caretakerRelation: 'Daughter-in-law',
      notes:
          'Practices light morning pranayama. Prefers warm herbal tea with meals.',
    );
    final kamalaGlimepiride = Medication(
      id: 'med-kamala-glimepiride',
      name: 'Glimepiride',
      strength: '1 mg',
      dosage: '1 tablet',
      dosageForm: DosageForm.tablet,
      scheduledTimesMinutes: const [480],
      mealInstruction: 'Before breakfast',
      startDate: day.subtract(const Duration(days: 150)),
    );
    final kamalaCalcium = Medication(
      id: 'med-kamala-calcium',
      name: 'Calcium + Vit D3',
      strength: '500 mg',
      dosage: '1 tablet',
      dosageForm: DosageForm.tablet,
      scheduledTimesMinutes: const [1200],
      mealInstruction: 'With dinner',
      startDate: day.subtract(const Duration(days: 150)),
    );
    final kamalaBp = List<BloodPressureReading>.generate(4, (index) {
      return BloodPressureReading(
        id: 'kamala-bp-$index',
        systolic: 122 + index * 2,
        diastolic: 76 + index,
        recordedAt: day.subtract(Duration(days: 4 - index)),
        recordedBy: 'Sunita Sharma',
      );
    });
    final kamalaGlu = List<GlucoseReading>.generate(4, (index) {
      return GlucoseReading(
        id: 'kamala-glu-$index',
        value: 134 + index * 4,
        unit: GlucoseUnit.mgDl,
        recordedAt: day.subtract(Duration(days: 4 - index)),
        recordedBy: 'Sunita Sharma',
      );
    });
    final kamalaSnapshot = CareSnapshot(
      patient: kamala,
      medications: [kamalaGlimepiride, kamalaCalcium],
      dietEntries: [
        const DietEntry(
          id: 'kamala-breakfast',
          slot: MealSlot.breakfast,
          title: 'Moong dal chilla with mint chutney',
          description: 'Protein-rich savory crepe prepared with minimal oil.',
          scheduledTimeMinutes: 480,
        ),
      ],
      exercises: [
        const ExerciseEntry(
          id: 'kamala-yoga',
          title: 'Gentle joint mobility & chair yoga',
          description: 'Knee and ankle rotations while seated.',
          scheduledTimeMinutes: 540,
        ),
      ],
      appointments: [
        Appointment(
          id: 'apt-kamala-endo',
          doctorName: 'Dr. Sarah Nguyen',
          speciality: 'Geriatric Medicine',
          dateTime: day.add(const Duration(days: 7, hours: 15)),
          location: 'Riverside Heart Clinic, Room 214',
          notes: 'Review glycemic control and joint comfort.',
        ),
      ],
      bloodPressureReadings: kamalaBp,
      glucoseReadings: kamalaGlu,
      confirmations: const [],
      discrepancies: const [],
      dualSettings: const DualConfirmationSettings(),
      carePlanVersions: [
        CarePlanVersion(
          id: 'plan-kamala-v1',
          patientId: kamala.id,
          versionNumber: 1,
          title: 'Metabolic & Osteo-Care Protocol',
          doctorName: 'Dr. Sarah Nguyen',
          createdAt: day.subtract(const Duration(days: 45)),
          status: CarePlanStatus.active,
          summaryOfChanges:
              'Focus on glycemic regulation and joint preservation.',
          medications: [kamalaGlimepiride, kamalaCalcium],
          dietEntries: const [],
          exercises: const [],
        ),
      ],
      consultationNotes: [
        ConsultationNote(
          id: 'note-kamala-1',
          patientId: kamala.id,
          doctorName: 'Dr. Sarah Nguyen',
          date: day.subtract(const Duration(days: 14)),
          observations:
              'Fasting blood sugar slightly elevated (138 mg/dL). Joint stiffness in cold weather.',
          followUpInstructions:
              'Keep monitoring pre-breakfast glucose. Emphasize low glycemic diet.',
          suggestedFollowUpDate: day.add(const Duration(days: 7)),
        ),
      ],
    );

    return CareSnapshot(
      patient: patient,
      medications: [lisinopril, metformin, atorvastatin, amlodipine],
      dietEntries: [breakfast, lunch, snack, dinner],
      exercises: [walk, breathing, physio],
      appointments: appointments,
      bloodPressureReadings: bp,
      glucoseReadings: glucose,
      confirmations: confirmations,
      discrepancies: discrepancies,
      dualSettings: const DualConfirmationSettings(),
      carePlanVersions: [initialPlanVersion],
      consultationNotes: [initialNote],
      notifications: notifications,
      patientSnapshots: {
        patient.id: CareSnapshot(
          patient: patient,
          medications: [lisinopril, metformin, atorvastatin, amlodipine],
          dietEntries: [breakfast, lunch, snack, dinner],
          exercises: [walk, breathing, physio],
          appointments: appointments,
          bloodPressureReadings: bp,
          glucoseReadings: glucose,
          confirmations: confirmations,
          discrepancies: discrepancies,
          dualSettings: const DualConfirmationSettings(),
          carePlanVersions: [initialPlanVersion],
          consultationNotes: [initialNote],
          notifications: notifications,
        ),
        arthur.id: arthurSnapshot,
        kamala.id: kamalaSnapshot,
      },
    );
  }
}
