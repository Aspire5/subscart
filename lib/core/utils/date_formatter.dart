import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatShortDay(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  static String formatDayNumber(DateTime date) {
    return DateFormat('d').format(date);
  }

  static String formatFullDate(DateTime date) {
    return DateFormat('EEEE, MMM d').format(date);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
