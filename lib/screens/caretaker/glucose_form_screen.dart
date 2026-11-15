import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/enums.dart';
import '../../models/health_reading.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';

class GlucoseFormScreen extends StatefulWidget {
  const GlucoseFormScreen({super.key});

  @override
  State<GlucoseFormScreen> createState() => _GlucoseFormScreenState();
}

class _GlucoseFormScreenState extends State<GlucoseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _notes = TextEditingController();
  late DateTime _when;
  late String _recordedBy;
  // Standard clinical measurement unit in India is mg/dL
  static const GlucoseUnit _unit = GlucoseUnit.mgDl;

  @override
  void initState() {
    super.initState();
    _when = DateTime.now();
    _recordedBy = context.read<CareProvider>().snapshot.patient.caretakerName;
  }

  @override
  void dispose() {
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<CareProvider>().addGlucose(
      GlucoseReading(
        id: const Uuid().v4(),
        value: double.parse(_value.text.trim()),
        unit: _unit,
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
      appBar: AppBar(title: const Text('Add blood sugar')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Blood sugar / Glucose reading',
                hintText: 'e.g. 110',
                suffixText: 'mg/dL',
                prefixIcon: Icon(
                  Icons.water_drop_rounded,
                  color: EldenColors.teal,
                ),
                helperText:
                    'Standard unit in India: mg/dL (Normal fasting: 70–99 mg/dL)',
              ),
              validator: (v) {
                final val = double.tryParse(v?.trim() ?? '');
                if (val == null) return 'Enter a blood sugar number';
                if (val < 20 || val > 700) {
                  return 'Reading looks out of typical range (20–700 mg/dL)';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: EldenColors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: EldenColors.teal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unit locked to mg/dL (standard on all Indian glucometers & labs)',
                      style: TextStyle(
                        fontSize: 12,
                        color: EldenColors.tealDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
