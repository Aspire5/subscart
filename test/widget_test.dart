import 'package:flutter_test/flutter_test.dart';
import 'package:subscart/data/datasources/mock_seed_data.dart';
import 'package:subscart/data/datasources/subscription_local_datasource.dart';
import 'package:subscart/data/models/daily_schedule_model.dart';
import 'package:subscart/data/models/meal_item_model.dart';
import 'package:subscart/data/models/meal_order_model.dart';
import 'package:subscart/data/models/vendor_subscription_model.dart';
import 'package:subscart/data/repositories/subscription_repository_impl.dart';
import 'package:subscart/domain/usecases/get_subscription_schedule_usecase.dart';
import 'package:subscart/domain/usecases/move_meal_items_batch_usecase.dart';
import 'package:subscart/domain/usecases/move_order_items_usecase.dart';
import 'package:subscart/domain/usecases/pause_subscription_usecase.dart';
import 'package:subscart/domain/usecases/reschedule_order_usecase.dart';
import 'package:subscart/domain/usecases/skip_meal_item_usecase.dart';
import 'package:subscart/domain/usecases/skip_meal_items_batch_usecase.dart';
import 'package:subscart/domain/usecases/swap_meal_item_usecase.dart';
import 'package:subscart/domain/usecases/toggle_delivery_slot_usecase.dart';
import 'package:subscart/presentation/controllers/schedule_controller.dart';

class InMemorySubscriptionLocalDataSource
    implements SubscriptionLocalDataSource {
  VendorSubscriptionModel _data = MockSeedData.initialSubscription();

  @override
  Future<VendorSubscriptionModel> getSubscription() async => _data;

  @override
  List<MealItemModel> getAlternateMealsPool() =>
      MockSeedData.alternateMealsPool();

  @override
  Future<VendorSubscriptionModel> skipMealItem(
      DateTime date, String orderId, String itemId) async {
    return await skipMealItems(date, {
      orderId: [itemId]
    });
  }

  @override
  Future<VendorSubscriptionModel> skipMealItems(
      DateTime date, Map<String, List<String>> orderToItemIdsMap) async {
    final updatedSchedules = _data.schedules.map((schedule) {
      if (schedule.date.day == date.day) {
        final updatedOrders = schedule.orders.map((order) {
          final itemsToSkip = orderToItemIdsMap[order.id];
          if (itemsToSkip != null && itemsToSkip.isNotEmpty) {
            final updatedItems = order.items
                .where((i) => !itemsToSkip.contains(i.id))
                .toList();
            return MealOrderModel(
              id: order.id,
              orderNumber: order.orderNumber,
              orderType: order.orderType,
              location: order.location,
              timeWindow: order.timeWindow,
              isSlotActive: order.isSlotActive,
              cutoffNotice: order.cutoffNotice,
              items: updatedItems,
              previewImageUrl: order.previewImageUrl,
            );
          }
          return order;
        }).toList();

        return DailyScheduleModel(
          date: schedule.date,
          dayOfWeek: schedule.dayOfWeek,
          dayNumber: schedule.dayNumber,
          orders: updatedOrders,
        );
      }
      return schedule;
    }).toList();

    _data = VendorSubscriptionModel(
      vendorId: _data.vendorId,
      vendorName: _data.vendorName,
      vendorLogoUrl: _data.vendorLogoUrl,
      planSummary: _data.planSummary,
      planName: _data.planName,
      isPaused: _data.isPaused,
      schedules: updatedSchedules,
    );
    return _data;
  }

  @override
  Future<VendorSubscriptionModel> swapMealItem(
    DateTime sourceDate,
    String sourceOrderId,
    String sourceItemId,
    DateTime targetDate,
    String targetOrderId,
    String targetItemId,
  ) async {
    MealItemModel? itemA;
    MealItemModel? itemB;

    final poolItem = getAlternateMealsPool()
        .where((m) => m.id == targetItemId)
        .firstOrNull;

    for (final s in _data.schedules) {
      if (s.date.day == sourceDate.day) {
        for (final o in s.orders) {
          if (o.id == sourceOrderId) {
            itemA = o.items.where((i) => i.id == sourceItemId).firstOrNull;
          }
        }
      }
      if (s.date.day == targetDate.day) {
        for (final o in s.orders) {
          if (o.id == targetOrderId) {
            itemB = o.items.where((i) => i.id == targetItemId).firstOrNull;
          }
        }
      }
    }

    itemB ??= poolItem;

    if (itemA == null || itemB == null) {
      return _data;
    }

    final replacementForA = itemB;
    final replacementForB = itemA;

    final updatedSchedules = _data.schedules.map((schedule) {
      final isSource = schedule.date.day == sourceDate.day;
      final isTarget = schedule.date.day == targetDate.day;

      if (!isSource && !isTarget) return schedule;

      final updatedOrders = schedule.orders.map((order) {
        if (isSource && order.id == sourceOrderId) {
          final newItems = order.items.map((i) {
            if (i.id == sourceItemId) {
              return replacementForA;
            }
            return i;
          }).toList();
          return MealOrderModel(
            id: order.id,
            orderNumber: order.orderNumber,
            orderType: order.orderType,
            location: order.location,
            timeWindow: order.timeWindow,
            isSlotActive: order.isSlotActive,
            cutoffNotice: order.cutoffNotice,
            items: newItems,
            previewImageUrl: order.previewImageUrl,
          );
        }

        if (isTarget && order.id == targetOrderId && poolItem == null) {
          final newItems = order.items.map((i) {
            if (i.id == targetItemId) {
              return replacementForB;
            }
            return i;
          }).toList();
          return MealOrderModel(
            id: order.id,
            orderNumber: order.orderNumber,
            orderType: order.orderType,
            location: order.location,
            timeWindow: order.timeWindow,
            isSlotActive: order.isSlotActive,
            cutoffNotice: order.cutoffNotice,
            items: newItems,
            previewImageUrl: order.previewImageUrl,
          );
        }

        return order;
      }).toList();

      return DailyScheduleModel(
        date: schedule.date,
        dayOfWeek: schedule.dayOfWeek,
        dayNumber: schedule.dayNumber,
        orders: updatedOrders,
      );
    }).toList();

    _data = VendorSubscriptionModel(
      vendorId: _data.vendorId,
      vendorName: _data.vendorName,
      vendorLogoUrl: _data.vendorLogoUrl,
      planSummary: _data.planSummary,
      planName: _data.planName,
      isPaused: _data.isPaused,
      schedules: updatedSchedules,
    );
    return _data;
  }

  @override
  Future<VendorSubscriptionModel> moveOrderItems(
    DateTime sourceDate,
    String sourceOrderId,
    DateTime targetDate,
    String targetOrderId,
  ) async {
    List<String> allItemIds = [];
    for (final s in _data.schedules) {
      if (s.date.day == sourceDate.day) {
        for (final o in s.orders) {
          if (o.id == sourceOrderId) {
            allItemIds = o.items.map((i) => i.id).toList();
          }
        }
      }
    }
    return await moveMealItems(
      sourceDate,
      {sourceOrderId: allItemIds},
      targetDate,
      targetOrderId,
    );
  }

  @override
  Future<VendorSubscriptionModel> moveMealItems(
    DateTime sourceDate,
    Map<String, List<String>> sourceOrderToItemIdsMap,
    DateTime targetDate,
    String targetOrderId,
  ) async {
    List<MealItemModel> itemsToMove = [];
    for (final s in _data.schedules) {
      if (s.date.day == sourceDate.day) {
        for (final o in s.orders) {
          final movingIds = sourceOrderToItemIdsMap[o.id];
          if (movingIds != null && movingIds.isNotEmpty) {
            final matching =
                o.items.where((i) => movingIds.contains(i.id)).toList();
            itemsToMove.addAll(matching);
          }
        }
      }
    }

    final updatedSchedules = _data.schedules.map((schedule) {
      final isSource = schedule.date.day == sourceDate.day;
      final isTarget = schedule.date.day == targetDate.day;

      if (!isSource && !isTarget) return schedule;

      final updatedOrders = schedule.orders.map((order) {
        if (isSource) {
          final movingIds = sourceOrderToItemIdsMap[order.id];
          if (movingIds != null && movingIds.isNotEmpty) {
            final remaining =
                order.items.where((i) => !movingIds.contains(i.id)).toList();
            return MealOrderModel(
              id: order.id,
              orderNumber: order.orderNumber,
              orderType: order.orderType,
              location: order.location,
              timeWindow: order.timeWindow,
              isSlotActive: order.isSlotActive,
              cutoffNotice: order.cutoffNotice,
              items: remaining,
              previewImageUrl: order.previewImageUrl,
            );
          }
        }
        if (isTarget && order.id == targetOrderId) {
          return MealOrderModel(
            id: order.id,
            orderNumber: order.orderNumber,
            orderType: order.orderType,
            location: order.location,
            timeWindow: order.timeWindow,
            isSlotActive: order.isSlotActive,
            cutoffNotice: order.cutoffNotice,
            items: [...order.items, ...itemsToMove],
            previewImageUrl: order.previewImageUrl,
          );
        }
        return order;
      }).toList();

      return DailyScheduleModel(
        date: schedule.date,
        dayOfWeek: schedule.dayOfWeek,
        dayNumber: schedule.dayNumber,
        orders: updatedOrders,
      );
    }).toList();

    _data = VendorSubscriptionModel(
      vendorId: _data.vendorId,
      vendorName: _data.vendorName,
      vendorLogoUrl: _data.vendorLogoUrl,
      planSummary: _data.planSummary,
      planName: _data.planName,
      isPaused: _data.isPaused,
      schedules: updatedSchedules,
    );
    return _data;
  }

  @override
  Future<VendorSubscriptionModel> rescheduleOrder(
      DateTime date, String orderId, String newTimeWindow) async {
    final updatedSchedules = _data.schedules.map((schedule) {
      if (schedule.date.day == date.day) {
        final updatedOrders = schedule.orders.map((order) {
          if (order.id == orderId) {
            final updatedCutoff = newTimeWindow.contains('8:00')
                ? 'Edits allowed until 7:00 AM the day of your Order.'
                : order.cutoffNotice;
            return MealOrderModel(
              id: order.id,
              orderNumber: order.orderNumber,
              orderType: order.orderType,
              location: order.location,
              timeWindow: newTimeWindow,
              isSlotActive: order.isSlotActive,
              cutoffNotice: updatedCutoff,
              items: order.items,
              previewImageUrl: order.previewImageUrl,
            );
          }
          return order;
        }).toList();

        return DailyScheduleModel(
          date: schedule.date,
          dayOfWeek: schedule.dayOfWeek,
          dayNumber: schedule.dayNumber,
          orders: updatedOrders,
        );
      }
      return schedule;
    }).toList();

    _data = VendorSubscriptionModel(
      vendorId: _data.vendorId,
      vendorName: _data.vendorName,
      vendorLogoUrl: _data.vendorLogoUrl,
      planSummary: _data.planSummary,
      planName: _data.planName,
      isPaused: _data.isPaused,
      schedules: updatedSchedules,
    );
    return _data;
  }

  @override
  Future<VendorSubscriptionModel> toggleDeliverySlot(
      DateTime date, String orderId, bool isActive) async {
    final updatedSchedules = _data.schedules.map((schedule) {
      if (schedule.date.day == date.day) {
        final updatedOrders = schedule.orders.map((order) {
          if (order.id == orderId) {
            return MealOrderModel(
              id: order.id,
              orderNumber: order.orderNumber,
              orderType: order.orderType,
              location: order.location,
              timeWindow: order.timeWindow,
              isSlotActive: isActive,
              cutoffNotice: order.cutoffNotice,
              items: order.items,
              previewImageUrl: order.previewImageUrl,
            );
          }
          return order;
        }).toList();

        return DailyScheduleModel(
          date: schedule.date,
          dayOfWeek: schedule.dayOfWeek,
          dayNumber: schedule.dayNumber,
          orders: updatedOrders,
        );
      }
      return schedule;
    }).toList();

    _data = VendorSubscriptionModel(
      vendorId: _data.vendorId,
      vendorName: _data.vendorName,
      vendorLogoUrl: _data.vendorLogoUrl,
      planSummary: _data.planSummary,
      planName: _data.planName,
      isPaused: _data.isPaused,
      schedules: updatedSchedules,
    );
    return _data;
  }

  @override
  Future<VendorSubscriptionModel> pauseSubscription(bool isPaused) async {
    _data = VendorSubscriptionModel(
      vendorId: _data.vendorId,
      vendorName: _data.vendorName,
      vendorLogoUrl: _data.vendorLogoUrl,
      planSummary: _data.planSummary,
      planName: _data.planName,
      isPaused: isPaused,
      schedules: _data.schedules,
    );
    return _data;
  }
}

void main() {
  group('Subscription Clean Architecture UseCase Tests', () {
    late SubscriptionRepositoryImpl repository;
    late GetSubscriptionScheduleUseCase getSubscriptionUseCase;
    late SkipMealItemUseCase skipMealItemUseCase;
    late SkipMealItemsBatchUseCase skipMealItemsBatchUseCase;
    late SwapMealItemUseCase swapMealItemUseCase;
    late MoveOrderItemsUseCase moveOrderItemsUseCase;
    late MoveMealItemsBatchUseCase moveMealItemsBatchUseCase;
    late RescheduleOrderUseCase rescheduleOrderUseCase;
    late ToggleDeliverySlotUseCase toggleDeliverySlotUseCase;
    late PauseSubscriptionUseCase pauseSubscriptionUseCase;
    late InMemorySubscriptionLocalDataSource localDataSource;

    setUp(() {
      localDataSource = InMemorySubscriptionLocalDataSource();
      repository = SubscriptionRepositoryImpl(localDataSource);
      getSubscriptionUseCase = GetSubscriptionScheduleUseCase(repository);
      skipMealItemUseCase = SkipMealItemUseCase(repository);
      skipMealItemsBatchUseCase = SkipMealItemsBatchUseCase(repository);
      swapMealItemUseCase = SwapMealItemUseCase(repository);
      moveOrderItemsUseCase = MoveOrderItemsUseCase(repository);
      moveMealItemsBatchUseCase = MoveMealItemsBatchUseCase(repository);
      rescheduleOrderUseCase = RescheduleOrderUseCase(repository);
      toggleDeliverySlotUseCase = ToggleDeliverySlotUseCase(repository);
      pauseSubscriptionUseCase = PauseSubscriptionUseCase(repository);
    });

    test('Loads initial vendor subscription details correctly', () async {
      final subscription = await getSubscriptionUseCase();
      expect(subscription.vendorName, contains('Healthy Lab'));
      expect(subscription.schedules.length, 6);
      expect(subscription.schedules.first.orders.length, 3);
    });

    test('Reschedules order time window and updates cutoff notice', () async {
      final date = DateTime(2026, 9, 15);
      final updated = await rescheduleOrderUseCase(
        date: date,
        orderId: 'ord_15_1',
        newTimeWindow: '8:00 am - 9:00 am',
      );

      final schedule = updated.schedules.firstWhere((s) => s.dayNumber == 15);
      final order = schedule.orders.firstWhere((o) => o.id == 'ord_15_1');
      expect(order.timeWindow, '8:00 am - 9:00 am');
      expect(order.cutoffNotice,
          'Edits allowed until 7:00 AM the day of your Order.');
    });

    test('Skips meal item from order with multiple items', () async {
      final date = DateTime(2026, 9, 15);
      final updated = await skipMealItemUseCase(
        date: date,
        orderId: 'ord_15_1',
        itemId: 'item_15_1_1',
      );

      final schedule = updated.schedules.firstWhere((s) => s.dayNumber == 15);
      final order = schedule.orders.firstWhere((o) => o.id == 'ord_15_1');
      expect(order.items.any((i) => i.id == 'item_15_1_1'), isFalse);
      expect(order.items.length, 1);
    });

    test('Batch skips multiple meal items across orders on the same day',
        () async {
      final date = DateTime(2026, 9, 15);
      final updated = await skipMealItemsBatchUseCase(
        date: date,
        orderToItemIdsMap: {
          'ord_15_1': ['item_15_1_1', 'item_15_1_2'],
          'ord_15_2': ['item_15_2_1'],
        },
      );

      final schedule = updated.schedules.firstWhere((s) => s.dayNumber == 15);
      final order1 = schedule.orders.firstWhere((o) => o.id == 'ord_15_1');
      final order2 = schedule.orders.firstWhere((o) => o.id == 'ord_15_2');
      expect(order1.items.isEmpty, isTrue);
      expect(order2.items.isEmpty, isTrue);
    });

    test('Swaps meal item with another meal from a different date order',
        () async {
      final sourceDate = DateTime(2026, 9, 15);
      final targetDate = DateTime(2026, 9, 16);

      // Tue 15th Order 1 has item_15_1_1 ('Grilled Chicken Burger')
      // Wed 16th Order 1 has item_16_1_1 ('Oatmeal Chia Seed Parfait')
      final updated = await swapMealItemUseCase(
        sourceDate: sourceDate,
        sourceOrderId: 'ord_15_1',
        sourceItemId: 'item_15_1_1',
        targetDate: targetDate,
        targetOrderId: 'ord_16_1',
        targetItemId: 'item_16_1_1',
      );

      final tueSchedule =
          updated.schedules.firstWhere((s) => s.dayNumber == 15);
      final wedSchedule =
          updated.schedules.firstWhere((s) => s.dayNumber == 16);

      final tueOrder =
          tueSchedule.orders.firstWhere((o) => o.id == 'ord_15_1');
      final wedOrder =
          wedSchedule.orders.firstWhere((o) => o.id == 'ord_16_1');

      // Now Tue Order 1 has the Oatmeal Chia Parfait
      expect(tueOrder.items.any((i) => i.name.contains('Oatmeal')), isTrue);
      expect(tueOrder.items.any((i) => i.name.contains('Burger')), isFalse);

      // And Wed Order 1 has the Grilled Chicken Burger
      expect(wedOrder.items.any((i) => i.name.contains('Burger')), isTrue);
      expect(wedOrder.items.any((i) => i.name.contains('Oatmeal')), isFalse);
    });

    test('Moves meal items to another day slot', () async {
      final sourceDate = DateTime(2026, 9, 15);
      final targetDate = DateTime(2026, 9, 16);

      final updated = await moveOrderItemsUseCase(
        sourceDate: sourceDate,
        sourceOrderId: 'ord_15_1',
        targetDate: targetDate,
        targetOrderId: 'ord_16_1',
      );

      final sourceSchedule =
          updated.schedules.firstWhere((s) => s.dayNumber == 15);
      final targetSchedule =
          updated.schedules.firstWhere((s) => s.dayNumber == 16);

      final sourceOrder =
          sourceSchedule.orders.firstWhere((o) => o.id == 'ord_15_1');
      final targetOrder =
          targetSchedule.orders.firstWhere((o) => o.id == 'ord_16_1');

      expect(sourceOrder.items.isEmpty, isTrue);
      expect(targetOrder.items.length, greaterThan(1));
    });

    test('Batch moves selected meal items from multiple orders to a target day and slot',
        () async {
      final sourceDate = DateTime(2026, 9, 15);
      final targetDate = DateTime(2026, 9, 16);

      final updated = await moveMealItemsBatchUseCase(
        sourceDate: sourceDate,
        sourceOrderToItemIdsMap: {
          'ord_15_1': ['item_15_1_1'],
          'ord_15_2': ['item_15_2_1'],
        },
        targetDate: targetDate,
        targetOrderId: 'ord_16_1',
      );

      final sourceSchedule =
          updated.schedules.firstWhere((s) => s.dayNumber == 15);
      final targetSchedule =
          updated.schedules.firstWhere((s) => s.dayNumber == 16);

      final sourceOrder1 =
          sourceSchedule.orders.firstWhere((o) => o.id == 'ord_15_1');
      final sourceOrder2 =
          sourceSchedule.orders.firstWhere((o) => o.id == 'ord_15_2');
      final targetOrder =
          targetSchedule.orders.firstWhere((o) => o.id == 'ord_16_1');

      expect(
          sourceOrder1.items.any((i) => i.id == 'item_15_1_1'), isFalse);
      expect(
          sourceOrder2.items.any((i) => i.id == 'item_15_2_1'), isFalse);
      expect(
          targetOrder.items.any((i) => i.id == 'item_15_1_1'), isTrue);
      expect(
          targetOrder.items.any((i) => i.id == 'item_15_2_1'), isTrue);
    });

    test('ScheduleController multi-selection and date-change clearing',
        () async {
      final controller = ScheduleController(
        getSubscriptionUseCase: getSubscriptionUseCase,
        skipMealItemUseCase: skipMealItemUseCase,
        skipMealItemsBatchUseCase: skipMealItemsBatchUseCase,
        swapMealItemUseCase: swapMealItemUseCase,
        moveOrderItemsUseCase: moveOrderItemsUseCase,
        moveMealItemsBatchUseCase: moveMealItemsBatchUseCase,
        rescheduleOrderUseCase: rescheduleOrderUseCase,
        toggleDeliverySlotUseCase: toggleDeliverySlotUseCase,
        pauseSubscriptionUseCase: pauseSubscriptionUseCase,
        localDataSource: localDataSource,
      );

      await controller.loadSubscriptionData();

      final schedule = controller.currentSchedule;
      expect(schedule, isNotNull);
      final order1 = schedule!.orders.first;
      final item1 = order1.items.first;
      final item2 = order1.items[1];

      // Select items
      controller.toggleItemSelection(item1, order1);
      expect(controller.selectedCount, 1);
      expect(controller.isItemSelected(item1.id), isTrue);

      controller.toggleItemSelection(item2, order1);
      expect(controller.selectedCount, 2);

      // Deselect 1 item
      controller.toggleItemSelection(item1, order1);
      expect(controller.selectedCount, 1);
      expect(controller.isItemSelected(item1.id), isFalse);
      expect(controller.isItemSelected(item2.id), isTrue);

      // Switching date clears selection
      final nextDate = DateTime(2026, 9, 16);
      controller.selectDate(nextDate);
      expect(controller.selectedCount, 0);
      expect(controller.isItemSelected(item2.id), isFalse);
    });

    test('Toggles delivery slot active state', () async {
      final date = DateTime(2026, 9, 15);
      final updated = await toggleDeliverySlotUseCase(
        date: date,
        orderId: 'ord_15_1',
        isActive: false,
      );

      final schedule = updated.schedules.firstWhere((s) => s.dayNumber == 15);
      final order = schedule.orders.firstWhere((o) => o.id == 'ord_15_1');
      expect(order.isSlotActive, isFalse);
    });

    test('Toggles pause subscription status', () async {
      final updated = await pauseSubscriptionUseCase(isPaused: true);
      expect(updated.isPaused, isTrue);
    });
  });
}
