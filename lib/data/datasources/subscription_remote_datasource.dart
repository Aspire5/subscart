import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/vendor_subscription_model.dart';

abstract class SubscriptionRemoteDataSource {
  Future<VendorSubscriptionModel> getSubscription();
  Future<Map<String, dynamic>> getSlotAvailability(
    DateTime targetDate, {
    String? excludeOrderId,
  });
  Future<VendorSubscriptionModel> rescheduleOrder({
    required String orderId,
    required DateTime targetDate,
    String? targetSlot,
    String? targetSlotId,
  });
  Future<VendorSubscriptionModel> moveMealItems(
    DateTime sourceDate,
    Map<String, List<String>> sourceOrderToItemIdsMap,
    DateTime targetDate,
    String? targetOrderId, {
    int? targetOrderNumber,
  });
  Future<VendorSubscriptionModel> swapMealItem(
    DateTime sourceDate,
    String sourceOrderId,
    String sourceItemId,
    DateTime targetDate,
    String targetOrderId,
    String targetItemId,
  );
  Future<VendorSubscriptionModel> skipMealItem(
    DateTime date,
    String orderId,
    String itemId,
  );
  Future<VendorSubscriptionModel> skipMealItems(
    DateTime date,
    Map<String, List<String>> orderToItemIdsMap,
  );
  Future<VendorSubscriptionModel> toggleDeliverySlot(
    DateTime date,
    String orderId,
    bool isActive,
  );
  Future<VendorSubscriptionModel> pauseSubscription(bool isPaused);
  Future<VendorSubscriptionModel> resetData();
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final DioClient _dioClient;

  SubscriptionRemoteDataSourceImpl(this._dioClient);

  Dio get _dio => _dioClient.dio;

  @override
  Future<VendorSubscriptionModel> getSubscription() async {
    final response = await _dio.get(ApiConstants.subscription);
    final data = response.data['data'] as Map<String, dynamic>;
    return VendorSubscriptionModel.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>> getSlotAvailability(
    DateTime targetDate, {
    String? excludeOrderId,
  }) async {
    final dateStr =
        '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    final response = await _dio.get(
      ApiConstants.slotAvailability,
      queryParameters: {
        'targetDate': dateStr,
        if (excludeOrderId != null) 'excludeOrderId': excludeOrderId,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<VendorSubscriptionModel> rescheduleOrder({
    required String orderId,
    required DateTime targetDate,
    String? targetSlot,
    String? targetSlotId,
  }) async {
    final dateStr =
        '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    final response = await _dio.post(
      ApiConstants.reschedule,
      data: {
        'orderId': orderId,
        'targetDate': dateStr,
        if (targetSlot != null) 'targetSlot': targetSlot,
        if (targetSlotId != null) 'targetSlotId': targetSlotId,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return VendorSubscriptionModel.fromJson(data);
  }

  @override
  Future<VendorSubscriptionModel> moveMealItems(
    DateTime sourceDate,
    Map<String, List<String>> sourceOrderToItemIdsMap,
    DateTime targetDate,
    String? targetOrderId, {
    int? targetOrderNumber,
  }) async {
    final dateStr =
        '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    final payload = <String, dynamic>{
      'sourceOrderToItemIdsMap': sourceOrderToItemIdsMap,
      'targetDate': dateStr,
    };
    if (targetOrderId != null && targetOrderId.isNotEmpty) {
      payload['targetOrderId'] = targetOrderId;
    }
    if (targetOrderNumber != null) {
      payload['targetOrderNumber'] = targetOrderNumber;
    }
    final response = await _dio.post(
      ApiConstants.moveItems,
      data: payload,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return VendorSubscriptionModel.fromJson(data);
  }

  @override
  Future<VendorSubscriptionModel> swapMealItem(
    DateTime sourceDate,
    String sourceOrderId,
    String sourceItemId,
    DateTime targetDate,
    String targetOrderId,
    String targetItemId,
  ) async {
    final response = await _dio.post(
      ApiConstants.swapItems,
      data: {
        'sourceItemId': sourceItemId,
        'targetItemId': targetItemId,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return VendorSubscriptionModel.fromJson(data);
  }

  @override
  Future<VendorSubscriptionModel> skipMealItem(
    DateTime date,
    String orderId,
    String itemId,
  ) async {
    final response = await _dio.post(
      ApiConstants.skipItems,
      data: {
        'orderId': orderId,
        'itemId': itemId,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return VendorSubscriptionModel.fromJson(data);
  }

  @override
  Future<VendorSubscriptionModel> skipMealItems(
    DateTime date,
    Map<String, List<String>> orderToItemIdsMap,
  ) async {
    final response = await _dio.post(
      ApiConstants.skipItems,
      data: {
        'orderToItemIdsMap': orderToItemIdsMap,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return VendorSubscriptionModel.fromJson(data);
  }

  @override
  Future<VendorSubscriptionModel> toggleDeliverySlot(
    DateTime date,
    String orderId,
    bool isActive,
  ) async {
    final response = await _dio.post(
      ApiConstants.toggleSlot,
      data: {
        'orderId': orderId,
        'isActive': isActive,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return VendorSubscriptionModel.fromJson(data);
  }

  @override
  Future<VendorSubscriptionModel> pauseSubscription(bool isPaused) async {
    final response = await _dio.post(
      ApiConstants.pause,
      data: {
        'isPaused': isPaused,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return VendorSubscriptionModel.fromJson(data);
  }

  @override
  Future<VendorSubscriptionModel> resetData() async {
    final response = await _dio.post(ApiConstants.resetData);
    final data = response.data['data'] as Map<String, dynamic>;
    return VendorSubscriptionModel.fromJson(data);
  }
}
