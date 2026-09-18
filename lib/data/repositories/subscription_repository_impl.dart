import '../../core/storage/local_storage_service.dart';
import '../../domain/entities/vendor_subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_datasource.dart';
import '../models/vendor_subscription_model.dart';

/// Implementation of [SubscriptionRepository] communicating directly with the backend API.
/// Optionally persists the latest payload into [LocalStorageService] for offline/cache-first viewing.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _remoteDataSource;
  final LocalStorageService? _storageService;

  SubscriptionRepositoryImpl(
    this._remoteDataSource, [
    this._storageService,
  ]);

  @override
  Future<VendorSubscription> getSubscription() async {
    try {
      final model = await _remoteDataSource.getSubscription();
      await _storageService?.saveSubscription(model.toJson());
      return model.toEntity();
    } catch (e) {
      final cachedJson = _storageService?.getSavedSubscription();
      if (cachedJson != null) {
        try {
          return VendorSubscriptionModel.fromJson(cachedJson).toEntity();
        } catch (_) {
          // If cached data is corrupt, rethrow the original network error
        }
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getSlotAvailability(
    DateTime targetDate, {
    String? excludeOrderId,
  }) async {
    return await _remoteDataSource.getSlotAvailability(
      targetDate,
      excludeOrderId: excludeOrderId,
    );
  }

  @override
  Future<VendorSubscription> skipMealItem({
    required DateTime date,
    required String orderId,
    required String itemId,
  }) async {
    final model = await _remoteDataSource.skipMealItem(date, orderId, itemId);
    await _storageService?.saveSubscription(model.toJson());
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> skipMealItems({
    required DateTime date,
    required Map<String, List<String>> orderToItemIdsMap,
  }) async {
    final model =
        await _remoteDataSource.skipMealItems(date, orderToItemIdsMap);
    await _storageService?.saveSubscription(model.toJson());
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
    final model = await _remoteDataSource.swapMealItem(
      sourceDate,
      sourceOrderId,
      sourceItemId,
      targetDate,
      targetOrderId,
      targetItemId,
    );
    await _storageService?.saveSubscription(model.toJson());
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> moveOrderItems({
    required DateTime sourceDate,
    required String sourceOrderId,
    required DateTime targetDate,
    required String targetOrderId,
  }) async {
    final model = await _remoteDataSource.moveMealItems(
      sourceDate,
      {sourceOrderId: []},
      targetDate,
      targetOrderId,
    );
    await _storageService?.saveSubscription(model.toJson());
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> moveMealItems({
    required DateTime sourceDate,
    required Map<String, List<String>> sourceOrderToItemIdsMap,
    required DateTime targetDate,
    required String targetOrderId,
  }) async {
    final model = await _remoteDataSource.moveMealItems(
      sourceDate,
      sourceOrderToItemIdsMap,
      targetDate,
      targetOrderId,
    );
    await _storageService?.saveSubscription(model.toJson());
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> rescheduleOrder({
    required DateTime date,
    required String orderId,
    required String newTimeWindow,
    DateTime? targetDate,
    String? targetSlotId,
  }) async {
    final model = await _remoteDataSource.rescheduleOrder(
      orderId: orderId,
      targetDate: targetDate ?? date,
      targetSlot: newTimeWindow,
      targetSlotId: targetSlotId,
    );
    await _storageService?.saveSubscription(model.toJson());
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> toggleDeliverySlot({
    required DateTime date,
    required String orderId,
    required bool isActive,
  }) async {
    final model = await _remoteDataSource.toggleDeliverySlot(
      date,
      orderId,
      isActive,
    );
    await _storageService?.saveSubscription(model.toJson());
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> pauseSubscription({
    required bool isPaused,
  }) async {
    final model = await _remoteDataSource.pauseSubscription(isPaused);
    await _storageService?.saveSubscription(model.toJson());
    return model.toEntity();
  }

  @override
  Future<VendorSubscription> resetData() async {
    final model = await _remoteDataSource.resetData();
    await _storageService?.saveSubscription(model.toJson());
    return model.toEntity();
  }
}
