import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/consultation_note.dart';
import '../../models/patient.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';

class ConsultationNoteDialog extends StatefulWidget {
  const ConsultationNoteDialog({super.key, required this.patient});

  final Patient patient;

  static Future<void> show(BuildContext context, Patient patient) {
    return showDialog(
      context: context,
      builder: (_) => ConsultationNoteDialog(patient: patient),
    );
  }

  @override
  State<ConsultationNoteDialog> createState() => _ConsultationNoteDialogState();
}

class _ConsultationNoteDialogState extends State<ConsultationNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _observations = TextEditingController();
  final _instructions = TextEditingController();
  late DateTime _consultationDate;
  DateTime? _suggestedFollowUp;
  final String _doctorName = 'Dr. Sarah Nguyen, MD';

  @override
  void initState() {
    super.initState();
    _consultationDate = DateTime.now();
  }

  @override
  void dispose() {
    _observations.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final note = ConsultationNote(
      id: const Uuid().v4(),
      patientId: widget.patient.id,
      doctorName: _doctorName,
      date: _consultationDate,
      observations: _observations.text.trim(),
      followUpInstructions: _instructions.text.trim(),
      suggestedFollowUpDate: _suggestedFollowUp,
    );

    await context.read<CareProvider>().addConsultationNote(note);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Consultation note saved for ${widget.patient.preferredName}',
          ),
          backgroundColor: EldenColors.teal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: EldenColors.teal,
            child: Icon(Icons.note_alt_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Consultation Note',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Patient: ${widget.patient.fullName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: EldenColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.event_rounded,
                    color: EldenColors.teal,
                  ),
                  title: const Text('Consultation date'),
                  subtitle: Text(
                    AppDateUtils.formatDateTime(_consultationDate),
                  ),
                  trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _consultationDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _consultationDate = date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observations,
                  decoration: const InputDecoration(
                    labelText: 'Clinical observations',
                    hintText:
                        'e.g. Patient appears oriented. Blood pressure stable...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter observations'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instructions,
                  decoration: const InputDecoration(
                    labelText: 'Follow-up instructions & care plan notes',
                    hintText:
                        'e.g. Continue Lisinopril 10 mg. Monitor fasting sugars...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter instructions'
                      : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.update_rounded,
                    color: EldenColors.teal,
                  ),
                  title: const Text('Suggested follow-up date'),
                  subtitle: Text(
                    _suggestedFollowUp == null
                        ? 'Not set'
                        : AppDateUtils.formatDateTime(_suggestedFollowUp!),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_suggestedFollowUp != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () =>
                              setState(() => _suggestedFollowUp = null),
                        ),
                      const Icon(Icons.calendar_today_rounded, size: 18),
                    ],
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          _suggestedFollowUp ??
                          DateTime.now().add(const Duration(days: 14)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _suggestedFollowUp = date);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save Note'),
        ),
      ],
    );
  }
}
