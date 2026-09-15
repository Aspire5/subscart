import '../entities/vendor_subscription.dart';
import '../repositories/subscription_repository.dart';

class SkipMealItemUseCase {
  final SubscriptionRepository _repository;

  SkipMealItemUseCase(this._repository);

  Future<VendorSubscription> call({
    required DateTime date,
    required String orderId,
    required String itemId,
  }) {
    return _repository.skipMealItem(
      date: date,
      orderId: orderId,
      itemId: itemId,
    );
  }
}
