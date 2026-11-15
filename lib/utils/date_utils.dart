import 'package:intl/intl.dart';

class AppDateUtils {
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String dateKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(dateOnly(date));

  static String formatDate(DateTime date) =>
      DateFormat('EEEE, d MMMM y').format(date);

  static String formatShortDate(DateTime date) =>
      DateFormat('d MMM y').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('d MMM y, h:mm a').format(date);

  static String formatTimeMinutes(int minutes) {
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(dt);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
