import 'daily_schedule.dart';

class VendorSubscription {
  final String vendorId;
  final String vendorName;
  final String vendorLogoUrl;
  final String planSummary;
  final String planName;
  final bool isPaused;
  final List<DailySchedule> schedules;

  const VendorSubscription({
    required this.vendorId,
    required this.vendorName,
    required this.vendorLogoUrl,
    required this.planSummary,
    required this.planName,
    required this.isPaused,
    required this.schedules,
  });

  VendorSubscription copyWith({
    String? vendorId,
    String? vendorName,
    String? vendorLogoUrl,
    String? planSummary,
    String? planName,
    bool? isPaused,
    List<DailySchedule>? schedules,
  }) {
    return VendorSubscription(
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorLogoUrl: vendorLogoUrl ?? this.vendorLogoUrl,
      planSummary: planSummary ?? this.planSummary,
      planName: planName ?? this.planName,
      isPaused: isPaused ?? this.isPaused,
      schedules: schedules ?? this.schedules,
    );
  }
}
