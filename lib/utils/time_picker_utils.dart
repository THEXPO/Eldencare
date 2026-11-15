import 'package:flutter/material.dart';

int timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

TimeOfDay minutesToTimeOfDay(int minutes) =>
    TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);

Future<int?> pickMinutes(
  BuildContext context, {
  int initialMinutes = 480,
}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: minutesToTimeOfDay(initialMinutes),
  );
  if (picked == null) return null;
  return timeOfDayToMinutes(picked);
}
