import '../../domain/entities/daily_schedule.dart';
import 'meal_order_model.dart';

class DailyScheduleModel {
  final DateTime date;
  final String dayOfWeek;
  final int dayNumber;
  final List<MealOrderModel> orders;

  const DailyScheduleModel({
    required this.date,
    required this.dayOfWeek,
    required this.dayNumber,
    required this.orders,
  });

  factory DailyScheduleModel.fromJson(Map<String, dynamic> json) {
    return DailyScheduleModel(
      date: DateTime.parse(json['date'] as String),
      dayOfWeek: json['dayOfWeek'] as String,
      dayNumber: json['dayNumber'] as int,
      orders: (json['orders'] as List<dynamic>)
          .map((e) => MealOrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'dayOfWeek': dayOfWeek,
      'dayNumber': dayNumber,
      'orders': orders.map((e) => e.toJson()).toList(),
    };
  }

  DailySchedule toEntity() {
    return DailySchedule(
      date: date,
      dayOfWeek: dayOfWeek,
      dayNumber: dayNumber,
      orders: orders.map((e) => e.toEntity()).toList(),
    );
  }

  factory DailyScheduleModel.fromEntity(DailySchedule entity) {
    return DailyScheduleModel(
      date: entity.date,
      dayOfWeek: entity.dayOfWeek,
      dayNumber: entity.dayNumber,
      orders: entity.orders.map((e) => MealOrderModel.fromEntity(e)).toList(),
    );
  }
}
