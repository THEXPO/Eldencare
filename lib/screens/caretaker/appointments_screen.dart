import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment.dart';
import '../../providers/care_provider.dart';
import '../../utils/date_utils.dart';
import '../../widgets/ec_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import 'appointment_form_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final upcoming =
        care.snapshot.appointments.where((a) => a.isUpcoming).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final past = care.snapshot.appointments.where((a) => !a.isUpcoming).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          'Appointments',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppointmentFormScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add appointment'),
          ),
        ),
        const SectionHeader(title: 'Upcoming'),
        if (upcoming.isEmpty)
          const EmptyState(message: 'No upcoming appointments.')
        else
          ...upcoming.map((a) => _AppointmentCard(appointment: a)),
        const SectionHeader(title: 'Past'),
        if (past.isEmpty)
          const EmptyState(message: 'No past appointments.')
        else
          ...past.map((a) => _AppointmentCard(appointment: a)),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final care = context.read<CareProvider>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EcCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appointment.doctorName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(appointment.speciality),
            Text(AppDateUtils.formatDateTime(appointment.dateTime)),
            Text(appointment.location),
            if (appointment.notes != null) Text(appointment.notes!),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          AppointmentFormScreen(existing: appointment),
                    ),
                  ),
                  child: const Text('Edit'),
                ),
                TextButton(
                  onPressed: () => care.deleteAppointment(appointment.id),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
