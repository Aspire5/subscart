import '../entities/vendor_subscription.dart';
import '../repositories/subscription_repository.dart';

class ResetDataUseCase {
  final SubscriptionRepository _repository;

  ResetDataUseCase(this._repository);

  Future<VendorSubscription> call() {
    return _repository.resetData();
  }
}
