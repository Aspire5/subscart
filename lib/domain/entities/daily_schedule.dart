import 'meal_order.dart';

class DailySchedule {
  final DateTime date;
  final String dayOfWeek;
  final int dayNumber;
  final List<MealOrder> orders;

  const DailySchedule({
    required this.date,
    required this.dayOfWeek,
    required this.dayNumber,
    required this.orders,
  });

  DailySchedule copyWith({
    DateTime? date,
    String? dayOfWeek,
    int? dayNumber,
    List<MealOrder>? orders,
  }) {
    return DailySchedule(
      date: date ?? this.date,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayNumber: dayNumber ?? this.dayNumber,
      orders: orders ?? this.orders,
    );
  }
}
