import '../entities/vendor_subscription.dart';
import '../repositories/subscription_repository.dart';

class MoveMealItemsBatchUseCase {
  final SubscriptionRepository repository;

  MoveMealItemsBatchUseCase(this.repository);

  Future<VendorSubscription> call({
    required DateTime sourceDate,
    required Map<String, List<String>> sourceOrderToItemIdsMap,
    required DateTime targetDate,
    required String targetOrderId,
  }) async {
    return await repository.moveMealItems(
      sourceDate: sourceDate,
      sourceOrderToItemIdsMap: sourceOrderToItemIdsMap,
      targetDate: targetDate,
      targetOrderId: targetOrderId,
    );
  }
}
