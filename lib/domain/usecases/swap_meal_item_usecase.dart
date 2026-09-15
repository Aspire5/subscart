import '../entities/vendor_subscription.dart';
import '../repositories/subscription_repository.dart';

class SwapMealItemUseCase {
  final SubscriptionRepository _repository;

  SwapMealItemUseCase(this._repository);

  Future<VendorSubscription> call({
    required DateTime sourceDate,
    required String sourceOrderId,
    required String sourceItemId,
    required DateTime targetDate,
    required String targetOrderId,
    required String targetItemId,
  }) {
    return _repository.swapMealItem(
      sourceDate: sourceDate,
      sourceOrderId: sourceOrderId,
      sourceItemId: sourceItemId,
      targetDate: targetDate,
      targetOrderId: targetOrderId,
      targetItemId: targetItemId,
    );
  }
}
