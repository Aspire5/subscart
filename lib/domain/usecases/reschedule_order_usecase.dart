import '../entities/vendor_subscription.dart';
import '../repositories/subscription_repository.dart';

class RescheduleOrderUseCase {
  final SubscriptionRepository _repository;

  RescheduleOrderUseCase(this._repository);

  Future<VendorSubscription> call({
    required DateTime date,
    required String orderId,
    required String newTimeWindow,
    DateTime? targetDate,
    String? targetSlotId,
  }) {
    return _repository.rescheduleOrder(
      date: date,
      orderId: orderId,
      newTimeWindow: newTimeWindow,
      targetDate: targetDate,
      targetSlotId: targetSlotId,
    );
  }

  Future<Map<String, dynamic>> getSlotAvailability(
    DateTime targetDate, {
    String? excludeOrderId,
  }) {
    return _repository.getSlotAvailability(
      targetDate,
      excludeOrderId: excludeOrderId,
    );
  }
}
