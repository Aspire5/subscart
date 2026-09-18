import 'package:get/get.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/local_storage_service.dart';
import '../../data/datasources/subscription_remote_datasource.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/usecases/get_subscription_schedule_usecase.dart';
import '../../domain/usecases/move_meal_items_batch_usecase.dart';
import '../../domain/usecases/move_order_items_usecase.dart';
import '../../domain/usecases/pause_subscription_usecase.dart';
import '../../domain/usecases/reschedule_order_usecase.dart';
import '../../domain/usecases/reset_data_usecase.dart';
import '../../domain/usecases/skip_meal_item_usecase.dart';
import '../../domain/usecases/skip_meal_items_batch_usecase.dart';
import '../../domain/usecases/swap_meal_item_usecase.dart';
import '../../domain/usecases/toggle_delivery_slot_usecase.dart';
import '../controllers/schedule_controller.dart';

class ScheduleBinding extends Bindings {
  @override
  void dependencies() {
    // Network Client
    Get.lazyPut<DioClient>(() => DioClient());

    // Remote Data Source
    final remoteDataSource =
        SubscriptionRemoteDataSourceImpl(Get.find<DioClient>());
    Get.lazyPut<SubscriptionRemoteDataSource>(() => remoteDataSource);

    // Repository (Backed by live remote backend API, optionally cached in local storage)
    final storageService = Get.find<LocalStorageService>();
    final repository = SubscriptionRepositoryImpl(remoteDataSource, storageService);
    Get.lazyPut<SubscriptionRepository>(() => repository);

    // Use Cases
    Get.lazyPut(() => GetSubscriptionScheduleUseCase(repository));
    Get.lazyPut(() => SkipMealItemUseCase(repository));
    Get.lazyPut(() => SkipMealItemsBatchUseCase(repository));
    Get.lazyPut(() => SwapMealItemUseCase(repository));
    Get.lazyPut(() => MoveOrderItemsUseCase(repository));
    Get.lazyPut(() => MoveMealItemsBatchUseCase(repository));
    Get.lazyPut(() => RescheduleOrderUseCase(repository));
    Get.lazyPut(() => ToggleDeliverySlotUseCase(repository));
    Get.lazyPut(() => PauseSubscriptionUseCase(repository));
    Get.lazyPut(() => ResetDataUseCase(repository));

    // Controller
    Get.lazyPut<ScheduleController>(
      () => ScheduleController(
        getSubscriptionUseCase: Get.find<GetSubscriptionScheduleUseCase>(),
        skipMealItemUseCase: Get.find<SkipMealItemUseCase>(),
        skipMealItemsBatchUseCase: Get.find<SkipMealItemsBatchUseCase>(),
        swapMealItemUseCase: Get.find<SwapMealItemUseCase>(),
        moveOrderItemsUseCase: Get.find<MoveOrderItemsUseCase>(),
        moveMealItemsBatchUseCase: Get.find<MoveMealItemsBatchUseCase>(),
        rescheduleOrderUseCase: Get.find<RescheduleOrderUseCase>(),
        toggleDeliverySlotUseCase: Get.find<ToggleDeliverySlotUseCase>(),
        pauseSubscriptionUseCase: Get.find<PauseSubscriptionUseCase>(),
        resetDataUseCase: Get.find<ResetDataUseCase>(),
      ),
    );
  }
}
