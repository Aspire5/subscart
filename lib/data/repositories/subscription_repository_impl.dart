import '../../domain/entities/vendor_subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_local_datasource.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionLocalDataSource _localDataSource;

  SubscriptionRepositoryImpl(this._localDataSource);

  @override
  Future<VendorSubscription> getSubscription() async {
    final model = await _localDataSource.getSubscription();
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> skipMealItem({
    required DateTime date,
    required String orderId,
    required String itemId,
  }) async {
    final model = await _localDataSource.skipMealItem(date, orderId, itemId);
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> skipMealItems({
    required DateTime date,
    required Map<String, List<String>> orderToItemIdsMap,
  }) async {
    final model = await _localDataSource.skipMealItems(date, orderToItemIdsMap);
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> swapMealItem({
    required DateTime sourceDate,
    required String sourceOrderId,
    required String sourceItemId,
    required DateTime targetDate,
    required String targetOrderId,
    required String targetItemId,
  }) async {
    final model = await _localDataSource.swapMealItem(
      sourceDate,
      sourceOrderId,
      sourceItemId,
      targetDate,
      targetOrderId,
      targetItemId,
    );
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> moveOrderItems({
    required DateTime sourceDate,
    required String sourceOrderId,
    required DateTime targetDate,
    required String targetOrderId,
  }) async {
    final model = await _localDataSource.moveOrderItems(
      sourceDate,
      sourceOrderId,
      targetDate,
      targetOrderId,
    );
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> moveMealItems({
    required DateTime sourceDate,
    required Map<String, List<String>> sourceOrderToItemIdsMap,
    required DateTime targetDate,
    required String targetOrderId,
  }) async {
    final model = await _localDataSource.moveMealItems(
      sourceDate,
      sourceOrderToItemIdsMap,
      targetDate,
      targetOrderId,
    );
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> rescheduleOrder({
    required DateTime date,
    required String orderId,
    required String newTimeWindow,
  }) async {
    final model =
        await _localDataSource.rescheduleOrder(date, orderId, newTimeWindow);
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> toggleDeliverySlot({
    required DateTime date,
    required String orderId,
    required bool isActive,
  }) async {
    final model =
        await _localDataSource.toggleDeliverySlot(date, orderId, isActive);
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> pauseSubscription({
    required bool isPaused,
  }) async {
    final model = await _localDataSource.pauseSubscription(isPaused);
    return model.toEntity();
  }
}
