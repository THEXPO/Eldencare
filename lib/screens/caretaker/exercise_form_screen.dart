import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/exercise_entry.dart';
import '../../providers/care_provider.dart';
import '../../utils/date_utils.dart';
import '../../utils/time_picker_utils.dart';

class ExerciseFormScreen extends StatefulWidget {
  const ExerciseFormScreen({super.key, this.existing});

  final ExerciseEntry? existing;

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _instructions;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _instructions = TextEditingController(text: existing?.instructions ?? '');
    _minutes = existing?.scheduledTimeMinutes ?? 450;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<CareProvider>().upsertExercise(
      ExerciseEntry(
        id: widget.existing?.id ?? const Uuid().v4(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        scheduledTimeMinutes: _minutes,
        instructions: _instructions.text.trim().isEmpty
            ? null
            : _instructions.text.trim(),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add activity' : 'Edit activity'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Activity name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructions,
              decoration: const InputDecoration(labelText: 'Instructions'),
              maxLines: 2,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Scheduled time'),
              subtitle: Text(AppDateUtils.formatTimeMinutes(_minutes)),
              onTap: () async {
                final value = await pickMinutes(
                  context,
                  initialMinutes: _minutes,
                );
                if (value != null) setState(() => _minutes = value);
              },
            ),
            FilledButton(onPressed: _save, child: const Text('Save activity')),
          ],
        ),
      ),
    );
  }
}
