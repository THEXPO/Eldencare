import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/diet_entry.dart';
import '../../models/enums.dart';
import '../../models/exercise_entry.dart';
import '../../models/medication.dart';
import '../../models/patient.dart';
import '../../providers/care_provider.dart';
import '../../services/duplicate_medication_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/ec_card.dart';
import '../../widgets/section_header.dart';

class CarePlanEditorScreen extends StatefulWidget {
  const CarePlanEditorScreen({super.key, required this.patient});

  final Patient patient;

  @override
  State<CarePlanEditorScreen> createState() => _CarePlanEditorScreenState();
}

class _CarePlanEditorScreenState extends State<CarePlanEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();

  late List<Medication> _medications;
  late List<DietEntry> _dietEntries;
  late List<ExerciseEntry> _exercises;

  final String _doctorName = 'Dr. Sarah Nguyen, MD';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final care = context.read<CareProvider>();
    final snap = care.getSnapshotFor(widget.patient.id);

    final activePlan = care.activeCarePlanFor(widget.patient.id);
    _titleController.text =
        activePlan?.title ?? 'Personalized Geriatric Care Regimen';
    _summaryController.text =
        'Updated care plan reviewed by $_doctorName on ${AppDateUtils.formatDateTime(DateTime.now()).split("·").first.trim()}.';

    _medications = List.from(snap.medications);
    _dietEntries = List.from(snap.dietEntries);
    _exercises = List.from(snap.exercises);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _savePlan({required bool activate}) async {
    final title = _titleController.text.trim().isEmpty
        ? 'Care Plan for ${widget.patient.preferredName}'
        : _titleController.text.trim();
    final summary = _summaryController.text.trim().isEmpty
        ? (activate
              ? 'Activated by $_doctorName'
              : 'Draft saved by $_doctorName')
        : _summaryController.text.trim();

    await context.read<CareProvider>().saveCarePlanVersion(
      title: title,
      summaryOfChanges: summary,
      activate: activate,
      doctorName: _doctorName,
      medications: _medications,
      dietEntries: _dietEntries,
      exercises: _exercises,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activate
                ? 'Care plan activated! Shared immediately with ${widget.patient.preferredName} & ${widget.patient.caretakerName}.'
                : 'Care plan draft saved.',
          ),
          backgroundColor: activate ? EldenColors.teal : EldenColors.muted,
        ),
      );
    }
  }

  void _addMedicationDialog([Medication? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final strengthCtrl = TextEditingController(text: existing?.strength ?? '');
    final dosageCtrl = TextEditingController(
      text: existing?.dosage ?? '1 tablet',
    );
    DosageForm form = existing?.dosageForm ?? DosageForm.tablet;
    final timeCtrl = TextEditingController(
      text: existing != null && existing.scheduledTimesMinutes.isNotEmpty
          ? AppDateUtils.formatTimeMinutes(existing.scheduledTimesMinutes.first)
          : '8:00 AM',
    );
    int scheduledMinutes =
        existing?.scheduledTimesMinutes.firstOrNull ?? 480; // 8:00 AM
    final mealCtrl = TextEditingController(
      text: existing?.mealInstruction ?? 'With meals',
    );
    final notesCtrl = TextEditingController(
      text: existing?.additionalInstructions ?? '',
    );

    final dupService = const DuplicateMedicationService();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Check duplicates in real-time
            final candidate = Medication(
              id: existing?.id ?? 'temp',
              name: nameCtrl.text.trim(),
              strength: strengthCtrl.text.trim(),
              dosage: dosageCtrl.text.trim(),
              dosageForm: form,
              scheduledTimesMinutes: [scheduledMinutes],
              mealInstruction: mealCtrl.text.trim(),
              startDate: DateTime.now(),
            );
            final duplicates = dupService.findPotentialDuplicates(
              candidate: candidate,
              existing: _medications,
            );

            return AlertDialog(
              title: Text(
                existing == null ? 'Add Medication' : 'Edit Medication',
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (duplicates.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: EldenColors.discrepancy.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: EldenColors.discrepancy.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_rounded,
                                color: EldenColors.discrepancy,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Potential duplicate active prescription detected: "${duplicates.first.existing.name} ${duplicates.first.existing.strength}" (${duplicates.first.existing.dosageForm.label})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: EldenColors.discrepancy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Medicine name*',
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: strengthCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Strength (e.g. 10 mg)*',
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: dosageCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Dosage (e.g. 1 tablet)*',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<DosageForm>(
                        initialValue: form,
                        items: DosageForm.values
                            .map(
                              (f) => DropdownMenuItem(
                                value: f,
                                child: Text(f.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setModalState(() => form = v ?? form),
                        decoration: const InputDecoration(
                          labelText: 'Dosage form',
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.access_time_rounded,
                          color: EldenColors.teal,
                        ),
                        title: const Text('Scheduled timing'),
                        subtitle: Text(
                          AppDateUtils.formatTimeMinutes(scheduledMinutes),
                        ),
                        trailing: const Icon(Icons.timer_outlined, size: 20),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: scheduledMinutes ~/ 60,
                              minute: scheduledMinutes % 60,
                            ),
                          );
                          if (time != null) {
                            setModalState(() {
                              scheduledMinutes = time.hour * 60 + time.minute;
                              timeCtrl.text = AppDateUtils.formatTimeMinutes(
                                scheduledMinutes,
                              );
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: mealCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Meal instruction',
                          hintText: 'e.g. After breakfast, With meals',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Additional clinical instructions',
                          hintText: 'e.g. Take with a full glass of water',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty ||
                        strengthCtrl.text.trim().isEmpty) {
                      return;
                    }
                    final updatedMed = Medication(
                      id: existing?.id ?? const Uuid().v4(),
                      name: nameCtrl.text.trim(),
                      strength: strengthCtrl.text.trim(),
                      dosage: dosageCtrl.text.trim(),
                      dosageForm: form,
                      scheduledTimesMinutes: [scheduledMinutes],
                      mealInstruction: mealCtrl.text.trim(),
                      startDate: existing?.startDate ?? DateTime.now(),
                      additionalInstructions: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                      isActive: true,
                    );
                    setState(() {
                      if (existing != null) {
                        final idx = _medications.indexWhere(
                          (m) => m.id == existing.id,
                        );
                        if (idx >= 0) _medications[idx] = updatedMed;
                      } else {
                        _medications.add(updatedMed);
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    existing == null ? 'Add to Plan' : 'Update Medication',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addDietDialog([DietEntry? existing]) {
    MealSlot slot = existing?.slot ?? MealSlot.breakfast;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final instCtrl = TextEditingController(text: existing?.instructions ?? '');
    int timeMinutes = existing?.scheduledTimeMinutes ?? 480;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add Diet Meal' : 'Edit Diet Meal',
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<MealSlot>(
                        initialValue: slot,
                        items: MealSlot.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setModalState(() => slot = v ?? slot),
                        decoration: const InputDecoration(
                          labelText: 'Meal slot',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Meal title*',
                          hintText: 'e.g. Oatmeal with berries',
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.access_time_rounded,
                          color: EldenColors.teal,
                        ),
                        title: const Text('Scheduled time'),
                        subtitle: Text(
                          AppDateUtils.formatTimeMinutes(timeMinutes),
                        ),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: timeMinutes ~/ 60,
                              minute: timeMinutes % 60,
                            ),
                          );
                          if (time != null) {
                            setModalState(() {
                              timeMinutes = time.hour * 60 + time.minute;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Meal contents / Description*',
                          hintText:
                              'e.g. Half cup oats, unsweetened almond milk',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: instCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Clinical dietary instructions (optional)',
                          hintText: 'e.g. Doctor-approved low-sodium',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty ||
                        descCtrl.text.trim().isEmpty) {
                      return;
                    }
                    final entry = DietEntry(
                      id: existing?.id ?? const Uuid().v4(),
                      slot: slot,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      scheduledTimeMinutes: timeMinutes,
                      instructions: instCtrl.text.trim().isEmpty
                          ? null
                          : instCtrl.text.trim(),
                    );
                    setState(() {
                      if (existing != null) {
                        final idx = _dietEntries.indexWhere(
                          (d) => d.id == existing.id,
                        );
                        if (idx >= 0) _dietEntries[idx] = entry;
                      } else {
                        _dietEntries.add(entry);
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(existing == null ? 'Add Meal' : 'Update Meal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addExerciseDialog([ExerciseEntry? existing]) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final instCtrl = TextEditingController(text: existing?.instructions ?? '');
    int timeMinutes = existing?.scheduledTimeMinutes ?? 450;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? 'Add Physical Activity'
                    : 'Edit Physical Activity',
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Activity title*',
                          hintText: 'e.g. Gentle Morning Walk',
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.access_time_rounded,
                          color: EldenColors.teal,
                        ),
                        title: const Text('Scheduled time'),
                        subtitle: Text(
                          AppDateUtils.formatTimeMinutes(timeMinutes),
                        ),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: timeMinutes ~/ 60,
                              minute: timeMinutes % 60,
                            ),
                          );
                          if (time != null) {
                            setModalState(() {
                              timeMinutes = time.hour * 60 + time.minute;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Activity description*',
                          hintText:
                              'e.g. 20-minute gentle walk around the garden',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: instCtrl,
                        decoration: const InputDecoration(
                          labelText:
                              'Safety / Clinical instructions (optional)',
                          hintText:
                              'e.g. Wear supportive shoes. Rest if dizzy.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty ||
                        descCtrl.text.trim().isEmpty) {
                      return;
                    }
                    final entry = ExerciseEntry(
                      id: existing?.id ?? const Uuid().v4(),
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      scheduledTimeMinutes: timeMinutes,
                      instructions: instCtrl.text.trim().isEmpty
                          ? null
                          : instCtrl.text.trim(),
                    );
                    setState(() {
                      if (existing != null) {
                        final idx = _exercises.indexWhere(
                          (e) => e.id == existing.id,
                        );
                        if (idx >= 0) _exercises[idx] = entry;
                      } else {
                        _exercises.add(entry);
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    existing == null ? 'Add Activity' : 'Update Activity',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Care Plan: ${widget.patient.preferredName}'),
        actions: [
          TextButton(
            onPressed: () => _savePlan(activate: false),
            child: const Text('Save as Draft'),
          ),
          FilledButton.icon(
            onPressed: () => _confirmActivation(),
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            label: const Text('Activate Plan'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: EcCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Care Plan Title',
                        hintText: 'e.g. Cardiometabolic & Mobility Regimen',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _summaryController,
                      decoration: const InputDecoration(
                        labelText: 'Summary of clinical updates (audit trail)',
                        hintText:
                            'e.g. Adjusted morning Metformin; added physiotherapyMobility.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: EldenColors.tealDark,
            indicatorColor: EldenColors.tealDark,
            tabs: [
              Tab(
                icon: const Icon(Icons.medication_rounded),
                text: 'Medications (${_medications.length})',
              ),
              Tab(
                icon: const Icon(Icons.restaurant_rounded),
                text: 'Diet (${_dietEntries.length})',
              ),
              Tab(
                icon: const Icon(Icons.directions_walk_rounded),
                text: 'Exercises (${_exercises.length})',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Medications list
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SectionHeader(title: 'Prescribed Medications'),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Medication'),
                          onPressed: () => _addMedicationDialog(),
                        ),
                      ],
                    ),
                    if (_medications.isEmpty)
                      const EcCard(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No medications currently prescribed in this plan.',
                          ),
                        ),
                      )
                    else
                      ..._medications.map((m) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: EcCard(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: EldenColors.sand,
                                child: Icon(
                                  Icons.medication_rounded,
                                  color: EldenColors.teal,
                                ),
                              ),
                              title: Text(
                                '${m.name} ${m.strength}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${m.dosage} (${m.dosageForm.label}) · ${m.mealInstruction} · ${AppDateUtils.formatTimeMinutes(m.scheduledTimesMinutes.firstOrNull ?? 480)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => _addMedicationDialog(m),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: EldenColors.discrepancy,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _medications.removeWhere(
                                          (item) => item.id == m.id,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),

                // Diet list
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SectionHeader(title: 'Daily Meal Schedule'),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Meal'),
                          onPressed: () => _addDietDialog(),
                        ),
                      ],
                    ),
                    if (_dietEntries.isEmpty)
                      const EcCard(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No meal schedule configured in this plan.',
                          ),
                        ),
                      )
                    else
                      ..._dietEntries.map((d) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: EcCard(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: EldenColors.sand,
                                child: Icon(
                                  Icons.restaurant_rounded,
                                  color: EldenColors.teal,
                                ),
                              ),
                              title: Text('${d.slot.label}: ${d.title}'),
                              subtitle: Text(
                                '${AppDateUtils.formatTimeMinutes(d.scheduledTimeMinutes)} · ${d.description}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => _addDietDialog(d),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: EldenColors.discrepancy,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _dietEntries.removeWhere(
                                          (item) => item.id == d.id,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),

                // Exercises list
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SectionHeader(
                          title: 'Physical Activity Protocol',
                        ),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Activity'),
                          onPressed: () => _addExerciseDialog(),
                        ),
                      ],
                    ),
                    if (_exercises.isEmpty)
                      const EcCard(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No physical activities configured in this plan.',
                          ),
                        ),
                      )
                    else
                      ..._exercises.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: EcCard(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: EldenColors.sand,
                                child: Icon(
                                  Icons.directions_walk_rounded,
                                  color: EldenColors.teal,
                                ),
                              ),
                              title: Text(e.title),
                              subtitle: Text(
                                '${AppDateUtils.formatTimeMinutes(e.scheduledTimeMinutes)} · ${e.description}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => _addExerciseDialog(e),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: EldenColors.discrepancy,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _exercises.removeWhere(
                                          (item) => item.id == e.id,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmActivation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activate Care Plan?'),
        content: Text(
          'Activating this plan will record a new immutable version in the patient history, supersede the previous active plan, and immediately update the live schedules for ${widget.patient.preferredName} and caretaker ${widget.patient.caretakerName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            label: const Text('Confirm & Activate'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _savePlan(activate: true);
            },
          ),
        ],
      ),
    );
  }
}
