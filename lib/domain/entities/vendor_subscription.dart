import 'daily_schedule.dart';

class VendorSubscription {
  final String vendorId;
  final String vendorName;
  final String vendorLogoUrl;
  final String planSummary;
  final String planName;
  final String timezone;
  final String timezoneDisplay;
  final bool isPaused;
  final List<DailySchedule> schedules;

  const VendorSubscription({
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

  VendorSubscription copyWith({
    String? vendorId,
    String? vendorName,
    String? vendorLogoUrl,
    String? planSummary,
    String? planName,
    String? timezone,
    String? timezoneDisplay,
    bool? isPaused,
    List<DailySchedule>? schedules,
  }) {
    return VendorSubscription(
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorLogoUrl: vendorLogoUrl ?? this.vendorLogoUrl,
      planSummary: planSummary ?? this.planSummary,
      planName: planName ?? this.planName,
      timezone: timezone ?? this.timezone,
      timezoneDisplay: timezoneDisplay ?? this.timezoneDisplay,
      isPaused: isPaused ?? this.isPaused,
      schedules: schedules ?? this.schedules,
    );
  }
}
