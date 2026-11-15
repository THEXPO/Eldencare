import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/enums.dart';
import '../../models/medication.dart';
import '../../providers/care_provider.dart';
import '../../utils/date_utils.dart';
import '../../utils/time_picker_utils.dart';

class MedicationFormScreen extends StatefulWidget {
  const MedicationFormScreen({super.key, this.existing});

  final Medication? existing;

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _strength;
  late final TextEditingController _dosage;
  late final TextEditingController _meal;
  late final TextEditingController _notes;
  late DosageForm _form;
  late List<int> _times;
  late DateTime _start;
  DateTime? _end;
  late bool _active;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _strength = TextEditingController(text: existing?.strength ?? '');
    _dosage = TextEditingController(text: existing?.dosage ?? '');
    _meal = TextEditingController(text: existing?.mealInstruction ?? '');
    _notes = TextEditingController(
      text: existing?.additionalInstructions ?? '',
    );
    _form = existing?.dosageForm ?? DosageForm.tablet;
    _times = [
      ...(existing?.scheduledTimesMinutes ?? [480]),
    ];
    _start = existing?.startDate ?? DateTime.now();
    _end = existing?.endDate;
    _active = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _strength.dispose();
    _dosage.dispose();
    _meal.dispose();
    _notes.dispose();
    super.dispose();
  }

  Medication _draft() {
    return Medication(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      strength: _strength.text.trim(),
      dosage: _dosage.text.trim(),
      dosageForm: _form,
      scheduledTimesMinutes: [..._times]..sort(),
      mealInstruction: _meal.text.trim(),
      startDate: _start,
      endDate: _end,
      additionalInstructions: _notes.text.trim().isEmpty
          ? null
          : _notes.text.trim(),
      isActive: _active,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one scheduled time.')),
      );
      return;
    }
    final care = context.read<CareProvider>();
    final draft = _draft();
    final duplicates = care.checkMedicationDuplicates(draft);
    if (duplicates.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Possible duplicate prescription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'An active medication already looks similar. Review it, then decide whether to continue. Nothing will be merged automatically.',
              ),
              const SizedBox(height: 12),
              ...duplicates.map(
                (match) => Text(
                  '• ${match.existing.name} ${match.existing.strength} '
                  '(${match.existing.dosageForm.label}) — ${match.existing.dosage}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Review first'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _saving = true);
    await care.upsertMedication(draft);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Add medication' : 'Edit medication',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Medicine name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _strength,
              decoration: const InputDecoration(labelText: 'Strength'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dosage,
              decoration: const InputDecoration(labelText: 'Dosage'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DosageForm>(
              initialValue: _form,
              items: DosageForm.values
                  .map(
                    (form) =>
                        DropdownMenuItem(value: form, child: Text(form.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _form = value ?? _form),
              decoration: const InputDecoration(labelText: 'Dosage form'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _meal,
              decoration: const InputDecoration(
                labelText: 'Before / after meals or other timing',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(
                labelText: 'Additional instructions',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Scheduled times',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Wrap(
              spacing: 8,
              children: [
                ..._times.map(
                  (minutes) => InputChip(
                    label: Text(AppDateUtils.formatTimeMinutes(minutes)),
                    onDeleted: () => setState(() => _times.remove(minutes)),
                  ),
                ),
                ActionChip(
                  label: const Text('Add time'),
                  onPressed: () async {
                    final minutes = await pickMinutes(context);
                    if (minutes != null && !_times.contains(minutes)) {
                      setState(() => _times.add(minutes));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(AppDateUtils.formatShortDate(_start)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _start,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _start = picked);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End date (optional)'),
              subtitle: Text(
                _end == null ? 'None' : AppDateUtils.formatShortDate(_end!),
              ),
              trailing: _end == null
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => _end = null),
                      icon: const Icon(Icons.clear),
                    ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _end ?? _start,
                  firstDate: _start,
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _end = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active prescription'),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save medication'),
            ),
          ],
        ),
      ),
    );
  }
}
