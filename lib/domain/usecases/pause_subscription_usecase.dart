import '../entities/vendor_subscription.dart';
import '../repositories/subscription_repository.dart';

class PauseSubscriptionUseCase {
  final SubscriptionRepository _repository;

  PauseSubscriptionUseCase(this._repository);

  Future<VendorSubscription> call({
    required bool isPaused,
  }) {
    return _repository.pauseSubscription(isPaused: isPaused);
  }
}
