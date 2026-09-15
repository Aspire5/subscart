import '../../domain/entities/meal_order.dart';
import 'meal_item_model.dart';

class MealOrderModel {
  final String id;
  final int orderNumber;
  final String orderType;
  final String location;
  final String timeWindow;
  final bool isSlotActive;
  final String cutoffNotice;
  final List<MealItemModel> items;
  final String previewImageUrl;

  const MealOrderModel({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.location,
    required this.timeWindow,
    required this.isSlotActive,
    required this.cutoffNotice,
    required this.items,
    required this.previewImageUrl,
  });

  factory MealOrderModel.fromJson(Map<String, dynamic> json) {
    return MealOrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as int,
      orderType: json['orderType'] as String,
      location: json['location'] as String,
      timeWindow: json['timeWindow'] as String,
      isSlotActive: json['isSlotActive'] as bool? ?? true,
      cutoffNotice: json['cutoffNotice'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => MealItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      previewImageUrl: json['previewImageUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'orderType': orderType,
      'location': location,
      'timeWindow': timeWindow,
      'isSlotActive': isSlotActive,
      'cutoffNotice': cutoffNotice,
      'items': items.map((e) => e.toJson()).toList(),
      'previewImageUrl': previewImageUrl,
    };
  }

  MealOrder toEntity() {
    return MealOrder(
      id: id,
      orderNumber: orderNumber,
      orderType: orderType,
      location: location,
      timeWindow: timeWindow,
      isSlotActive: isSlotActive,
      cutoffNotice: cutoffNotice,
      items: items.map((e) => e.toEntity()).toList(),
      previewImageUrl: previewImageUrl,
    );
  }

  factory MealOrderModel.fromEntity(MealOrder entity) {
    return MealOrderModel(
      id: entity.id,
      orderNumber: entity.orderNumber,
      orderType: entity.orderType,
      location: entity.location,
      timeWindow: entity.timeWindow,
      isSlotActive: entity.isSlotActive,
      cutoffNotice: entity.cutoffNotice,
      items: entity.items.map((e) => MealItemModel.fromEntity(e)).toList(),
      previewImageUrl: entity.previewImageUrl,
    );
  }
}
