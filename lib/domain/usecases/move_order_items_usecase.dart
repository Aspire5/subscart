import '../entities/vendor_subscription.dart';
import '../repositories/subscription_repository.dart';

class MoveOrderItemsUseCase {
  final SubscriptionRepository _repository;

  MoveOrderItemsUseCase(this._repository);

  Future<VendorSubscription> call({
    required DateTime sourceDate,
    required String sourceOrderId,
    required DateTime targetDate,
    required String targetOrderId,
  }) {
    return _repository.moveOrderItems(
      sourceDate: sourceDate,
      sourceOrderId: sourceOrderId,
      targetDate: targetDate,
      targetOrderId: targetOrderId,
    );
  }
}
