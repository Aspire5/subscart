import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscart/data/models/daily_schedule_model.dart';
import 'package:subscart/data/models/meal_item_model.dart';
import 'package:subscart/data/models/meal_order_model.dart';
import 'package:subscart/data/models/vendor_subscription_model.dart';
import 'package:subscart/domain/entities/daily_schedule.dart';
import 'package:subscart/domain/entities/meal_item.dart';
import 'package:subscart/domain/entities/meal_order.dart';
import 'package:subscart/domain/entities/vendor_subscription.dart';
import 'package:subscart/domain/repositories/subscription_repository.dart';
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
import 'package:subscart/presentation/views/widgets/app_confirmation_dialog.dart';
import 'package:subscart/presentation/views/widgets/move_bottom_sheet.dart';
import 'package:subscart/presentation/views/widgets/reschedule_bottom_sheet.dart';
import 'package:subscart/presentation/views/widgets/swap_bottom_sheet.dart';
import 'package:subscart/presentation/views/widgets/top_nav_bar.dart';
import 'fixtures/mock_test_data.dart';

/// In-memory repository fake used for testing domain use cases and controller state.
class FakeSubscriptionRepository implements SubscriptionRepository {
  VendorSubscriptionModel _data = MockTestData.initialSubscription();

  @override
  Future<VendorSubscription> getSubscription() async => _data.toEntity();

  @override
  Future<Map<String, dynamic>> getSlotAvailability(
    DateTime targetDate, {
    String? excludeOrderId,
  }) async {
    return {
      'hasAvailableSlots': true,
      'slots': [
        {
          'name': 'Breakfast Window',
          'displayTime': '8:00 am - 9:00 am',
          'cutoffTime': '07:00',
          'cutoffNotice': 'Edits allowed until 7:00 AM the day of your Order.',
          'isAvailable': true,
        },
      ],
    };
  }

  @override
  Future<VendorSubscription> skipMealItem({
    required DateTime date,
    required String orderId,
    required String itemId,
  }) async {
    return await skipMealItems(date: date, orderToItemIdsMap: {
      orderId: [itemId]
    });
  }

  @override
  Future<VendorSubscription> skipMealItems({
    required DateTime date,
    required Map<String, List<String>> orderToItemIdsMap,
  }) async {
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
    return _data.toEntity();
  }

  @override
  Future<VendorSubscription> swapMealItem({
    required DateTime sourceDate,
    required String sourceOrderId,
    required String sourceItemId,
    required DateTime targetDate,
    required String targetOrderId,
    required String targetItemId,
  }) async {
    MealItemModel? itemA;
    MealItemModel? itemB;

    final poolItem = MockTestData.alternateMealsPool()
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
      return _data.toEntity();
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
    return _data.toEntity();
  }

  @override
  Future<VendorSubscription> moveOrderItems({
    required DateTime sourceDate,
    required String sourceOrderId,
    required DateTime targetDate,
    required String targetOrderId,
  }) async {
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
      sourceDate: sourceDate,
      sourceOrderToItemIdsMap: {sourceOrderId: allItemIds},
      targetDate: targetDate,
      targetOrderId: targetOrderId,
    );
  }

  @override
  Future<VendorSubscription> moveMealItems({
    required DateTime sourceDate,
    required Map<String, List<String>> sourceOrderToItemIdsMap,
    required DateTime targetDate,
    String? targetOrderId,
    int? targetOrderNumber,
  }) async {
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
        final isMatchingTarget = isTarget &&
            ((targetOrderId != null && order.id == targetOrderId) ||
                (targetOrderNumber != null && order.orderNumber == targetOrderNumber));
        if (isMatchingTarget) {
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
    return _data.toEntity();
  }

  @override
  Future<VendorSubscription> rescheduleOrder({
    required DateTime date,
    required String orderId,
    required String newTimeWindow,
    DateTime? targetDate,
    String? targetSlotId,
  }) async {
    final effectiveTarget = targetDate ?? date;
    if (effectiveTarget.day != date.day) {
      MealOrderModel? orderToMove;
      for (final s in _data.schedules) {
        if (s.date.day == date.day) {
          orderToMove = s.orders.where((o) => o.id == orderId).firstOrNull;
        }
      }
      if (orderToMove != null) {
        final updatedOrder = MealOrderModel(
          id: orderToMove.id,
          orderNumber: 1,
          orderType: orderToMove.orderType,
          location: orderToMove.location,
          timeWindow: newTimeWindow,
          isSlotActive: orderToMove.isSlotActive,
          cutoffNotice: orderToMove.cutoffNotice,
          items: orderToMove.items,
          previewImageUrl: orderToMove.previewImageUrl,
        );
        final updatedSchedules = _data.schedules.map((schedule) {
          if (schedule.date.day == date.day) {
            return DailyScheduleModel(
              date: schedule.date,
              dayOfWeek: schedule.dayOfWeek,
              dayNumber: schedule.dayNumber,
              orders: schedule.orders.where((o) => o.id != orderId).toList(),
            );
          } else if (schedule.date.day == effectiveTarget.day) {
            return DailyScheduleModel(
              date: schedule.date,
              dayOfWeek: schedule.dayOfWeek,
              dayNumber: schedule.dayNumber,
              orders: [...schedule.orders, updatedOrder],
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
        return _data.toEntity();
      }
    }

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
    return _data.toEntity();
  }

  @override
  Future<VendorSubscription> toggleDeliverySlot({
    required DateTime date,
    required String orderId,
    required bool isActive,
  }) async {
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
    return _data.toEntity();
  }

  @override
  Future<VendorSubscription> pauseSubscription({
    required bool isPaused,
  }) async {
    _data = VendorSubscriptionModel(
      vendorId: _data.vendorId,
      vendorName: _data.vendorName,
      vendorLogoUrl: _data.vendorLogoUrl,
      planSummary: _data.planSummary,
      planName: _data.planName,
      isPaused: isPaused,
      schedules: _data.schedules,
    );
    return _data.toEntity();
  }

  @override
  Future<VendorSubscription> resetData() async {
    return _data.toEntity();
  }
}

void main() {
  group('Subscription Clean Architecture UseCase Tests', () {
    late FakeSubscriptionRepository repository;
    late GetSubscriptionScheduleUseCase getSubscriptionUseCase;
    late SkipMealItemUseCase skipMealItemUseCase;
    late SkipMealItemsBatchUseCase skipMealItemsBatchUseCase;
    late SwapMealItemUseCase swapMealItemUseCase;
    late MoveOrderItemsUseCase moveOrderItemsUseCase;
    late MoveMealItemsBatchUseCase moveMealItemsBatchUseCase;
    late RescheduleOrderUseCase rescheduleOrderUseCase;
    late ToggleDeliverySlotUseCase toggleDeliverySlotUseCase;
    late PauseSubscriptionUseCase pauseSubscriptionUseCase;

    setUp(() {
      repository = FakeSubscriptionRepository();
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

    test('Reschedules entire order to a different target date', () async {
      final sourceDate = DateTime(2026, 9, 15);
      final targetDate = DateTime(2026, 9, 18);
      final updated = await rescheduleOrderUseCase(
        date: sourceDate,
        orderId: 'ord_15_1',
        newTimeWindow: '7:30 pm - 8:30 pm',
        targetDate: targetDate,
      );

      final sourceSchedule =
          updated.schedules.firstWhere((s) => s.dayNumber == 15);
      expect(sourceSchedule.orders.any((o) => o.id == 'ord_15_1'), false);

      final targetSchedule =
          updated.schedules.firstWhere((s) => s.dayNumber == 18);
      final movedOrder =
          targetSchedule.orders.firstWhere((o) => o.id == 'ord_15_1');
      expect(movedOrder.timeWindow, '7:30 pm - 8:30 pm');
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

      expect(tueOrder.items.any((i) => i.name.contains('Oatmeal')), isTrue);
      expect(tueOrder.items.any((i) => i.name.contains('Burger')), isFalse);

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

    test('ScheduleController blocks duplicate concurrent action executions',
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
      );
      await controller.loadSubscriptionData();

      int executions = 0;
      final f1 = controller.runWithBlockingLoading(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        executions++;
      }, message: 'Action 1');

      // Simultaneous duplicate trigger while f1 is in flight
      final f2 = controller.runWithBlockingLoading(() async {
        executions++;
      }, message: 'Action 2');

      await Future.wait([f1, f2]);
      expect(executions, 1,
          reason: 'Second action must be dropped by mutex lock');
      expect(controller.isMutating.value, isFalse);
    });

    test('ScheduleController rejects selecting items from past cutoff orders',
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
      );
      await controller.loadSubscriptionData();

      const item = MealItem(
        id: 'item_past_1',
        name: 'Test Item',
        calories: 350,
        fatGrams: 10,
        proteinGrams: 20,
        carbGrams: 40,
        imageUrl: '',
      );

      const pastOrder = MealOrder(
        id: 'ord_past_1',
        orderNumber: 1,
        orderType: 'Lunch',
        location: 'Home',
        timeWindow: '12:00 PM',
        isSlotActive: true,
        cutoffNotice: 'Cut-off passed',
        isPastCutoff: true,
        previewImageUrl: '',
        items: [item],
      );

      controller.toggleItemSelection(item, pastOrder);
      expect(controller.isItemSelected('item_past_1'), isFalse,
          reason: 'Item selection must be ignored when order is past cutoff');
      expect(controller.selectedCount, 0);
    });

    test('ScheduleController runWithBlockingLoading enforces minimum perceptual duration',
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
      );

      final stopwatch = Stopwatch()..start();
      await controller.runWithBlockingLoading(() async {
        // Fast 5ms action
        await Future.delayed(const Duration(milliseconds: 5));
      }, message: 'Fast action');
      stopwatch.stop();

      // Should take at least 400ms to eliminate visual blink
      expect(stopwatch.elapsedMilliseconds >= 400, isTrue);
      expect(controller.isMutating.value, isFalse);
    });

    testWidgets(
        'SwapBottomSheet renders Cut-off passed badge instead of Swap button for past cutoff meals',
        (tester) async {
      const sourceItem = MealItem(
        id: 'source_item_1',
        name: 'Saturday Burger',
        calories: 450,
        fatGrams: 15,
        proteinGrams: 25,
        carbGrams: 45,
        imageUrl: '',
      );

      const sourceOrder = MealOrder(
        id: 'ord_sat_1',
        orderNumber: 1,
        orderType: 'Lunch',
        location: 'Home',
        timeWindow: '12:00 PM',
        isSlotActive: true,
        cutoffNotice: 'Edits allowed until 11:00 AM',
        isPastCutoff: false,
        previewImageUrl: '',
        items: [sourceItem],
      );

      const targetPastCutoffMeal = MealItem(
        id: 'target_past_item',
        name: 'Greek Yogurt Berry Bowl',
        calories: 280,
        fatGrams: 5,
        proteinGrams: 12,
        carbGrams: 35,
        imageUrl: '',
      );

      const targetPastCutoffOrder = MealOrder(
        id: 'ord_fri_1',
        orderNumber: 1,
        orderType: 'Lunch',
        location: 'Home',
        timeWindow: '12:00 PM',
        isSlotActive: true,
        cutoffNotice: 'Cut-off passed',
        isPastCutoff: true,
        previewImageUrl: '',
        items: [targetPastCutoffMeal],
      );

      final targetDate = DateTime(2026, 9, 18);
      final scheduleWithPastCutoff = DailySchedule(
        date: targetDate,
        dayOfWeek: 'Fri',
        dayNumber: 18,
        orders: [targetPastCutoffOrder],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwapBottomSheet(
              sourceItems: [
                SelectedSwapSource(
                  item: sourceItem,
                  order: sourceOrder,
                  date: DateTime(2026, 9, 19),
                ),
              ],
              availableDays: [scheduleWithPastCutoff],
              onAllSwapsConfirmed: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that the 'Cut-off passed' badge appears and NO 'Swap' button is rendered for this item
      expect(find.text('Cut-off passed'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Swap'), findsNothing);
    });

    testWidgets(
        'MoveBottomSheet disables past cutoff order slot and displays lock icon',
        (tester) async {
      const pastOrder = MealOrder(
        id: 'ord_target_1',
        orderNumber: 1,
        orderType: 'Lunch',
        location: 'Home',
        timeWindow: '12:00 PM',
        isSlotActive: true,
        cutoffNotice: 'Cut-off passed',
        isPastCutoff: true,
        previewImageUrl: '',
        items: [],
      );

      const futureOrder = MealOrder(
        id: 'ord_target_2',
        orderNumber: 2,
        orderType: 'Dinner',
        location: 'Home',
        timeWindow: '8:00 PM',
        isSlotActive: true,
        cutoffNotice: 'Edits allowed until 6:00 PM',
        isPastCutoff: false,
        previewImageUrl: '',
        items: [],
      );

      final targetDate = DateTime(2026, 9, 18);
      final schedule = DailySchedule(
        date: targetDate,
        dayOfWeek: 'Fri',
        dayNumber: 18,
        orders: [pastOrder, futureOrder],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoveBottomSheet(
              currentDate: DateTime(2026, 9, 19),
              availableDays: [schedule],
              itemCount: 1,
              onMoveConfirmed: (_, __) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that the lock icon is shown for the closed slot (Order 1)
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.text('Order 1'), findsOneWidget);
      expect(find.text('Order 2'), findsOneWidget);
    });

    testWidgets('MoveBottomSheet displays target order preview with time window, items, and calories',
        (tester) async {
      const orderWithMeals = MealOrder(
        id: 'ord_rich_1',
        orderNumber: 1,
        orderType: 'Lunch',
        location: 'Home',
        timeWindow: '12:30 pm - 1:30 pm',
        isSlotActive: true,
        cutoffNotice: 'Edits allowed until 11:00 AM',
        isPastCutoff: false,
        previewImageUrl: '',
        items: [
          MealItem(
            id: 'm1',
            name: 'Avocado Green Salad',
            calories: 320,
            fatGrams: 14,
            proteinGrams: 8,
            carbGrams: 22,
            imageUrl: '',
          ),
        ],
      );

      final targetDate = DateTime(2026, 9, 20);
      final schedule = DailySchedule(
        date: targetDate,
        dayOfWeek: 'Sun',
        dayNumber: 20,
        orders: [orderWithMeals],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoveBottomSheet(
              currentDate: DateTime(2026, 9, 19),
              availableDays: [schedule],
              itemCount: 1,
              onMoveConfirmed: (_, __) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check preview header elements
      expect(find.text('12:30 pm - 1:30 pm'), findsOneWidget);
      expect(find.text('Edits allowed until 11:00 AM'), findsOneWidget);
      expect(find.text('Items in this Order (1)'), findsOneWidget);
      expect(find.text('Avocado Green Salad'), findsOneWidget);
      expect(find.text('320 kcal'), findsOneWidget);
    });

    testWidgets('RescheduleBottomSheet renders Occupied badge for occupied delivery slots',
        (tester) async {
      const testOrder = MealOrder(
        id: 'ord_resched_test',
        orderNumber: 3,
        orderType: 'Delivery',
        location: 'Home',
        timeWindow: '7:30 pm - 8:30 pm',
        isSlotActive: true,
        cutoffNotice: 'Edits allowed until 6:00 PM',
        isPastCutoff: false,
        previewImageUrl: '',
        items: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RescheduleBottomSheet(
              order: testOrder,
              currentDate: DateTime(2026, 9, 20),
              availableSchedules: const [],
              onFetchSlotAvailability: (_) async => {
                'hasAvailableSlots': true,
                'nextAvailableSlot': {
                  'id': 'slot_2',
                  'displayTime': '12:30 pm - 1:30 pm',
                },
                'slots': [
                  {
                    'id': 'slot_1',
                    'name': 'Breakfast Window',
                    'displayTime': '8:00 am - 9:00 am',
                    'cutoffNotice': 'Edits allowed until 7:00 AM',
                    'isAvailable': false,
                    'reason': 'Slot occupied by an existing order',
                  },
                  {
                    'id': 'slot_2',
                    'name': 'Lunch Window',
                    'displayTime': '12:30 pm - 1:30 pm',
                    'cutoffNotice': 'Edits allowed until 11:00 AM',
                    'isAvailable': true,
                  },
                ],
              },
              onConfirm: (_, __, ___) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that the Occupied badge is rendered for slot 1
      expect(find.text('Occupied'), findsOneWidget);
      // Verify nothing is pre-selected initially
      expect(find.text('Selected'), findsNothing);
      expect(find.text('12:30 pm - 1:30 pm'), findsOneWidget);
    });

    testWidgets('RescheduleBottomSheet renders Current Slot badge for the order own window and nothing pre-selected',
        (tester) async {
      const testOrder = MealOrder(
        id: 'ord_resched_test',
        orderNumber: 1,
        orderType: 'Delivery',
        location: 'Home',
        timeWindow: '8:00 am - 9:00 am',
        isSlotActive: true,
        cutoffNotice: 'Edits allowed until 7:00 AM',
        isPastCutoff: false,
        previewImageUrl: '',
        items: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RescheduleBottomSheet(
              order: testOrder,
              currentDate: DateTime(2026, 9, 20),
              availableSchedules: const [],
              onFetchSlotAvailability: (_) async => {
                'hasAvailableSlots': true,
                'slots': [
                  {
                    'id': 'slot_1',
                    'name': 'Breakfast Window',
                    'displayTime': '8:00 am - 9:00 am',
                    'cutoffNotice': 'Edits allowed until 7:00 AM',
                    'isAvailable': false,
                    'isCurrentSlot': true,
                    'reason': 'Current delivery window',
                  },
                  {
                    'id': 'slot_2',
                    'name': 'Lunch Window',
                    'displayTime': '12:30 pm - 1:30 pm',
                    'cutoffNotice': 'Edits allowed until 11:00 AM',
                    'isAvailable': true,
                  },
                ],
              },
              onConfirm: (_, __, ___) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current Slot'), findsOneWidget);
      expect(find.text('Selected'), findsNothing);
    });

    testWidgets('TopNavBar displays Reset Database option in popup menu and triggers onResetTap',
        (tester) async {
      bool resetTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: TopNavBar(
              vendorName: 'Daily Green & Gourmet',
              planSummary: 'Weekly Balanced Diet • 3 Slots Daily',
              vendorLogoUrl: '',
              onResetTap: () {
                resetTapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 3-dots button
      final moreButton = find.byIcon(Icons.more_horiz);
      expect(moreButton, findsOneWidget);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Check popup menu item
      final resetMenuItem = find.text('Reset Database');
      expect(resetMenuItem, findsOneWidget);

      // Tap reset database
      await tester.tap(resetMenuItem);
      await tester.pumpAndSettle();

      expect(resetTapped, true);
    });

    testWidgets('AppConfirmationDialog renders warning and calls onConfirm when pressed',
        (tester) async {
      bool onConfirmCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppConfirmationDialog.show(
                  context,
                  title: 'Reset Database?',
                  message: 'This will restore all meal plans back to original demo seed data.',
                  confirmText: 'Reset Database',
                  onConfirm: () {
                    onConfirmCalled = true;
                  },
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog contents
      expect(find.text('Reset Database?'), findsOneWidget);
      expect(find.text('This will restore all meal plans back to original demo seed data.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Reset Database'), findsOneWidget);

      // Tap Confirm in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Database'));
      await tester.pumpAndSettle();

      expect(onConfirmCalled, true);
    });
  });
}
