import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/health_reading.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';

class BpFormScreen extends StatefulWidget {
  const BpFormScreen({super.key});

  @override
  State<BpFormScreen> createState() => _BpFormScreenState();
}

class _BpFormScreenState extends State<BpFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _combined = TextEditingController();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _notes = TextEditingController();

  bool _isQuickMode = true;
  late DateTime _when;
  late String _recordedBy;

  static final _combinedRegex = RegExp(
    r'^\s*(\d{2,3})\s*[\s\/\,\-]\s*(\d{2,3})\s*$',
  );

  @override
  void initState() {
    super.initState();
    _when = DateTime.now();
    _recordedBy = context.read<CareProvider>().snapshot.patient.caretakerName;
  }

  @override
  void dispose() {
    _combined.dispose();
    _systolic.dispose();
    _diastolic.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _syncCombinedToSeparate(String val) {
    final match = _combinedRegex.firstMatch(val);
    if (match != null) {
      _systolic.text = match.group(1)!;
      _diastolic.text = match.group(2)!;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    int sys;
    int dia;

    if (_isQuickMode) {
      final match = _combinedRegex.firstMatch(_combined.text.trim());
      if (match == null) return;
      sys = int.parse(match.group(1)!);
      dia = int.parse(match.group(2)!);
    } else {
      sys = int.parse(_systolic.text.trim());
      dia = int.parse(_diastolic.text.trim());
    }

    await context.read<CareProvider>().addBloodPressure(
      BloodPressureReading(
        id: const Uuid().v4(),
        systolic: sys,
        diastolic: dia,
        recordedAt: _when,
        recordedBy: _recordedBy,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<CareProvider>().snapshot.patient;

    return Scaffold(
      appBar: AppBar(title: const Text('Add blood pressure')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Mode Selector
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.flash_on_rounded),
                  label: Text('Quick (120/80)'),
                ),
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.view_agenda_outlined),
                  label: Text('Separate fields'),
                ),
              ],
              selected: {_isQuickMode},
              onSelectionChanged: (set) {
                setState(() {
                  _isQuickMode = set.first;
                  if (_isQuickMode) {
                    if (_systolic.text.isNotEmpty &&
                        _diastolic.text.isNotEmpty) {
                      _combined.text =
                          '${_systolic.text.trim()}/${_diastolic.text.trim()}';
                    }
                  } else {
                    _syncCombinedToSeparate(_combined.text);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            if (_isQuickMode) ...[
              TextFormField(
                controller: _combined,
                keyboardType: TextInputType.text,
                onChanged: _syncCombinedToSeparate,
                decoration: const InputDecoration(
                  labelText: 'Blood pressure (e.g. 120/80)',
                  hintText: '120/80',
                  prefixIcon: Icon(
                    Icons.favorite_rounded,
                    color: EldenColors.teal,
                  ),
                  suffixText: 'mmHg',
                  helperText:
                      'Type top and bottom numbers with a slash, e.g. 120/80',
                ),
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return 'Enter blood pressure (e.g. 120/80)';
                  final match = _combinedRegex.firstMatch(text);
                  if (match == null) {
                    return 'Please enter in 120/80 format (e.g. 120/80)';
                  }
                  final s = int.tryParse(match.group(1)!);
                  final d = int.tryParse(match.group(2)!);
                  if (s == null || s < 40 || s > 300) {
                    return 'Top number (systolic) looks out of range';
                  }
                  if (d == null || d < 30 || d > 200) {
                    return 'Bottom number (diastolic) looks out of range';
                  }
                  return null;
                },
              ),
            ] else ...[
              TextFormField(
                controller: _systolic,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Top number — Systolic',
                  hintText: 'e.g. 120',
                  suffixText: 'mmHg',
                  helperText: 'Higher number when the heart pumps',
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null) return 'Enter top number';
                  if (n < 40 || n > 300) return 'Top number looks out of range';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _diastolic,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bottom number — Diastolic',
                  hintText: 'e.g. 80',
                  suffixText: 'mmHg',
                  helperText: 'Lower number when the heart rests',
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null) return 'Enter bottom number';
                  if (n < 30 || n > 200) {
                    return 'Bottom number looks out of range';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _recordedBy,
              items: [patient.caretakerName, patient.preferredName]
                  .map(
                    (name) => DropdownMenuItem(value: name, child: Text(name)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _recordedBy = value ?? _recordedBy),
              decoration: const InputDecoration(labelText: 'Recorded by'),
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
                  lastDate: DateTime.now(),
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
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save reading')),
          ],
        ),
      ),
    );
  }
}
