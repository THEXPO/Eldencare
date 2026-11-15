import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/care_provider.dart';
import '../../utils/date_utils.dart';
import '../../widgets/ec_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';

class PatientHealthScreen extends StatelessWidget {
  const PatientHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final bp = [...care.snapshot.bloodPressureReadings]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final glucose = [...care.snapshot.glucoseReadings]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final nextAppt = care.nextAppointment();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text('Health', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Recent readings recorded at home. These are records only.'),
        const SectionHeader(title: 'Blood pressure'),
        if (bp.isEmpty)
          const EmptyState(message: 'No blood pressure readings yet.')
        else
          ...bp
              .take(8)
              .map(
                (reading) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EcCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reading.systolic} / ${reading.diastolic} mmHg',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(AppDateUtils.formatDateTime(reading.recordedAt)),
                        Text('Recorded by ${reading.recordedBy}'),
                      ],
                    ),
                  ),
                ),
              ),
        const SectionHeader(title: 'Blood sugar'),
        if (glucose.isEmpty)
          const EmptyState(message: 'No blood sugar readings yet.')
        else
          ...glucose
              .take(8)
              .map(
                (reading) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EcCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reading.value.toStringAsFixed(0)} ${reading.unit.label}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(AppDateUtils.formatDateTime(reading.recordedAt)),
                        Text('Recorded by ${reading.recordedBy}'),
                      ],
                    ),
                  ),
                ),
              ),
        const SectionHeader(title: 'Upcoming appointment'),
        if (nextAppt == null)
          const EmptyState(message: 'No upcoming appointments.')
        else
          EcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextAppt.doctorName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(nextAppt.speciality),
                Text(AppDateUtils.formatDateTime(nextAppt.dateTime)),
                Text(nextAppt.location),
                if (nextAppt.notes != null) Text(nextAppt.notes!),
              ],
            ),
          ),
      ],
    );
  }
}
