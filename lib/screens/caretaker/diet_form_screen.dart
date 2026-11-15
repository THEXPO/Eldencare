import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/diet_entry.dart';
import '../../models/enums.dart';
import '../../providers/care_provider.dart';
import '../../utils/date_utils.dart';
import '../../utils/time_picker_utils.dart';

class DietFormScreen extends StatefulWidget {
  const DietFormScreen({super.key, this.existing});

  final DietEntry? existing;

  @override
  State<DietFormScreen> createState() => _DietFormScreenState();
}

class _DietFormScreenState extends State<DietFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _instructions;
  late MealSlot _slot;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _instructions = TextEditingController(text: existing?.instructions ?? '');
    _slot = existing?.slot ?? MealSlot.breakfast;
    _minutes = existing?.scheduledTimeMinutes ?? 480;
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
    await context.read<CareProvider>().upsertDiet(
      DietEntry(
        id: widget.existing?.id ?? const Uuid().v4(),
        slot: _slot,
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
        title: Text(widget.existing == null ? 'Add meal' : 'Edit meal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<MealSlot>(
              initialValue: _slot,
              items: MealSlot.values
                  .map(
                    (slot) =>
                        DropdownMenuItem(value: slot, child: Text(slot.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _slot = value ?? _slot),
              decoration: const InputDecoration(labelText: 'Meal'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
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
              decoration: const InputDecoration(
                labelText: 'Doctor-approved instructions',
              ),
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
            FilledButton(onPressed: _save, child: const Text('Save meal')),
          ],
        ),
      ),
    );
  }
}
