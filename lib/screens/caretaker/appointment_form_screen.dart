import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/appointment.dart';
import '../../providers/care_provider.dart';
import '../../utils/date_utils.dart';

class AppointmentFormScreen extends StatefulWidget {
  const AppointmentFormScreen({super.key, this.existing});

  final Appointment? existing;

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _doctor;
  late final TextEditingController _speciality;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late DateTime _when;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _doctor = TextEditingController(text: existing?.doctorName ?? '');
    _speciality = TextEditingController(text: existing?.speciality ?? '');
    _location = TextEditingController(text: existing?.location ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _when = existing?.dateTime ?? DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _doctor.dispose();
    _speciality.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<CareProvider>().upsertAppointment(
      Appointment(
        id: widget.existing?.id ?? const Uuid().v4(),
        doctorName: _doctor.text.trim(),
        speciality: _speciality.text.trim(),
        dateTime: _when,
        location: _location.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Add appointment' : 'Edit appointment',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _doctor,
              decoration: const InputDecoration(labelText: "Doctor's name"),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _speciality,
              decoration: const InputDecoration(labelText: 'Speciality'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Hospital / clinic'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date and time'),
              subtitle: Text(AppDateUtils.formatDateTime(_when)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _when,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date == null || !context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_when),
                );
                if (time == null) return;
                setState(() {
                  _when = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                });
              },
            ),
            FilledButton(
              onPressed: _save,
              child: const Text('Save appointment'),
            ),
          ],
        ),
      ),
    );
  }
}
