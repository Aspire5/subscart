import '../entities/vendor_subscription.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptionScheduleUseCase {
  final SubscriptionRepository _repository;

  GetSubscriptionScheduleUseCase(this._repository);

  Future<VendorSubscription> call() {
    return _repository.getSubscription();
  }
}
