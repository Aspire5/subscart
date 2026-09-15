import '../entities/vendor_subscription.dart';
import '../repositories/subscription_repository.dart';

class SkipMealItemsBatchUseCase {
  final SubscriptionRepository repository;

  SkipMealItemsBatchUseCase(this.repository);

  Future<VendorSubscription> call({
    required DateTime date,
    required Map<String, List<String>> orderToItemIdsMap,
  }) async {
    return await repository.skipMealItems(
      date: date,
      orderToItemIdsMap: orderToItemIdsMap,
    );
  }
}
