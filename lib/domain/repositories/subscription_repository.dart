import '../entities/vendor_subscription.dart';

abstract class SubscriptionRepository {
  Future<VendorSubscription> getSubscription();

  Future<VendorSubscription> skipMealItem({
    required DateTime date,
    required String orderId,
    required String itemId,
  });

  Future<VendorSubscription> skipMealItems({
    required DateTime date,
    required Map<String, List<String>> orderToItemIdsMap,
  });

  Future<VendorSubscription> swapMealItem({
    required DateTime sourceDate,
    required String sourceOrderId,
    required String sourceItemId,
    required DateTime targetDate,
    required String targetOrderId,
    required String targetItemId,
  });

  Future<VendorSubscription> moveOrderItems({
    required DateTime sourceDate,
    required String sourceOrderId,
    required DateTime targetDate,
    required String targetOrderId,
  });

  Future<VendorSubscription> moveMealItems({
    required DateTime sourceDate,
    required Map<String, List<String>> sourceOrderToItemIdsMap,
    required DateTime targetDate,
    required String targetOrderId,
  });

  Future<VendorSubscription> rescheduleOrder({
    required DateTime date,
    required String orderId,
    required String newTimeWindow,
  });

  Future<VendorSubscription> toggleDeliverySlot({
    required DateTime date,
    required String orderId,
    required bool isActive,
  });

  Future<VendorSubscription> pauseSubscription({
    required bool isPaused,
  });
}
