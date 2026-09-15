import '../entities/vendor_subscription.dart';
import '../repositories/subscription_repository.dart';

class ToggleDeliverySlotUseCase {
  final SubscriptionRepository _repository;

  ToggleDeliverySlotUseCase(this._repository);

  Future<VendorSubscription> call({
    required DateTime date,
    required String orderId,
    required bool isActive,
  }) {
    return _repository.toggleDeliverySlot(
      date: date,
      orderId: orderId,
      isActive: isActive,
    );
  }
}
