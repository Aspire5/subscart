import 'meal_item.dart';

class MealOrder {
  final String id;
  final int orderNumber;
  final String orderType;
  final String location;
  final String timeWindow;
  final bool isSlotActive;
  final String cutoffNotice;
  final List<MealItem> items;
  final String previewImageUrl;
  final bool isPastCutoff;

  const MealOrder({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.location,
    required this.timeWindow,
    required this.isSlotActive,
    required this.cutoffNotice,
    required this.items,
    required this.previewImageUrl,
    this.isPastCutoff = false,
  });

  MealOrder copyWith({
    String? id,
    int? orderNumber,
    String? orderType,
    String? location,
    String? timeWindow,
    bool? isSlotActive,
    String? cutoffNotice,
    List<MealItem>? items,
    String? previewImageUrl,
    bool? isPastCutoff,
  }) {
    return MealOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      orderType: orderType ?? this.orderType,
      location: location ?? this.location,
      timeWindow: timeWindow ?? this.timeWindow,
      isSlotActive: isSlotActive ?? this.isSlotActive,
      cutoffNotice: cutoffNotice ?? this.cutoffNotice,
      items: items ?? this.items,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      isPastCutoff: isPastCutoff ?? this.isPastCutoff,
    );
  }
}
