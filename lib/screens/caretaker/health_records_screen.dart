import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/health_reading.dart';
import '../../providers/care_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/ec_card.dart';
import '../../widgets/section_header.dart';
import 'bp_form_screen.dart';
import 'glucose_form_screen.dart';

class HealthRecordsScreen extends StatelessWidget {
  const HealthRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final bp = [...care.snapshot.bloodPressureReadings]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final glucose = [...care.snapshot.glucoseReadings]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          'Health records',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Text('Home readings only. No diagnosis is generated.'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const BpFormScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Blood pressure'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GlucoseFormScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Glucose'),
              ),
            ),
          ],
        ),
        const SectionHeader(title: 'Blood pressure trend'),
        if (bp.length >= 2) _BpChart(readings: bp),
        ...bp.reversed.map(
          (reading) => _ReadingTile(
            title: '${reading.systolic}/${reading.diastolic} mmHg',
            subtitle:
                '${AppDateUtils.formatDateTime(reading.recordedAt)} · ${reading.recordedBy}',
            notes: reading.notes,
          ),
        ),
        const SectionHeader(title: 'Glucose trend'),
        if (glucose.length >= 2) _GlucoseChart(readings: glucose),
        ...glucose.reversed.map(
          (reading) => _ReadingTile(
            title: '${reading.value.toStringAsFixed(0)} ${reading.unit.label}',
            subtitle:
                '${AppDateUtils.formatDateTime(reading.recordedAt)} · ${reading.recordedBy}',
            notes: reading.notes,
          ),
        ),
      ],
    );
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.title, required this.subtitle, this.notes});

  final String title;
  final String subtitle;
  final String? notes;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(notes == null ? subtitle : '$subtitle\n$notes'),
    );
  }
}

class _BpChart extends StatelessWidget {
  const _BpChart({required this.readings});

  final List<BloodPressureReading> readings;

  @override
  Widget build(BuildContext context) {
    return EcCard(
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: 60,
            maxY: 160,
            titlesData: const FlTitlesData(show: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < readings.length; i++)
                    FlSpot(i.toDouble(), readings[i].systolic.toDouble()),
                ],
                color: EldenColors.teal,
                isCurved: true,
                dotData: const FlDotData(show: true),
              ),
              LineChartBarData(
                spots: [
                  for (var i = 0; i < readings.length; i++)
                    FlSpot(i.toDouble(), readings[i].diastolic.toDouble()),
                ],
                color: EldenColors.warning,
                isCurved: true,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlucoseChart extends StatelessWidget {
  const _GlucoseChart({required this.readings});

  final List<GlucoseReading> readings;

  @override
  Widget build(BuildContext context) {
    return EcCard(
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            titlesData: const FlTitlesData(show: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < readings.length; i++)
                    FlSpot(i.toDouble(), readings[i].value),
                ],
                color: EldenColors.tealDark,
                isCurved: true,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
