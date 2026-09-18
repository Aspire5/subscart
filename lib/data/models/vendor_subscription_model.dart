import '../../domain/entities/vendor_subscription.dart';
import 'daily_schedule_model.dart';

class VendorSubscriptionModel {
  final String vendorId;
  final String vendorName;
  final String vendorLogoUrl;
  final String planSummary;
  final String planName;
  final String timezone;
  final String timezoneDisplay;
  final bool isPaused;
  final List<DailyScheduleModel> schedules;

  const VendorSubscriptionModel({
    required this.vendorId,
    required this.vendorName,
    required this.vendorLogoUrl,
    required this.planSummary,
    required this.planName,
    this.timezone = 'Asia/Kolkata',
    this.timezoneDisplay = 'All times in IST (UTC+5:30)',
    required this.isPaused,
    required this.schedules,
  });

  factory VendorSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return VendorSubscriptionModel(
      vendorId: json['vendorId'] as String,
      vendorName: json['vendorName'] as String,
      vendorLogoUrl: json['vendorLogoUrl'] as String,
      planSummary: json['planSummary'] as String,
      planName: json['planName'] as String,
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      timezoneDisplay: json['timezoneDisplay'] as String? ?? 'All times in IST (UTC+5:30)',
      isPaused: json['isPaused'] as bool? ?? false,
      schedules: (json['schedules'] as List<dynamic>)
          .map((e) => DailyScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'vendorLogoUrl': vendorLogoUrl,
      'planSummary': planSummary,
      'planName': planName,
      'timezone': timezone,
      'timezoneDisplay': timezoneDisplay,
      'isPaused': isPaused,
      'schedules': schedules.map((e) => e.toJson()).toList(),
    };
  }

  VendorSubscription toEntity() {
    return VendorSubscription(
      vendorId: vendorId,
      vendorName: vendorName,
      vendorLogoUrl: vendorLogoUrl,
      planSummary: planSummary,
      planName: planName,
      timezone: timezone,
      timezoneDisplay: timezoneDisplay,
      isPaused: isPaused,
      schedules: schedules.map((e) => e.toEntity()).toList(),
    );
  }

  factory VendorSubscriptionModel.fromEntity(VendorSubscription entity) {
    return VendorSubscriptionModel(
      vendorId: entity.vendorId,
      vendorName: entity.vendorName,
      vendorLogoUrl: entity.vendorLogoUrl,
      planSummary: entity.planSummary,
      planName: entity.planName,
      isPaused: entity.isPaused,
      schedules: entity.schedules
          .map((e) => DailyScheduleModel.fromEntity(e))
          .toList(),
    );
  }
}
