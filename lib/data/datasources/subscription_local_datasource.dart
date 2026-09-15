import '../../core/storage/local_storage_service.dart';
import '../models/daily_schedule_model.dart';
import '../models/meal_item_model.dart';
import '../models/meal_order_model.dart';
import '../models/vendor_subscription_model.dart';
import 'mock_seed_data.dart';

abstract class SubscriptionLocalDataSource {
  Future<VendorSubscriptionModel> getSubscription();
  Future<VendorSubscriptionModel> skipMealItem(
      DateTime date, String orderId, String itemId);
  Future<VendorSubscriptionModel> skipMealItems(
      DateTime date, Map<String, List<String>> orderToItemIdsMap);
  Future<VendorSubscriptionModel> swapMealItem(
    DateTime sourceDate,
    String sourceOrderId,
    String sourceItemId,
    DateTime targetDate,
    String targetOrderId,
    String targetItemId,
  );
  Future<VendorSubscriptionModel> moveOrderItems(
    DateTime sourceDate,
    String sourceOrderId,
    DateTime targetDate,
    String targetOrderId,
  );
  Future<VendorSubscriptionModel> moveMealItems(
    DateTime sourceDate,
    Map<String, List<String>> sourceOrderToItemIdsMap,
    DateTime targetDate,
    String targetOrderId,
  );
  Future<VendorSubscriptionModel> rescheduleOrder(
      DateTime date, String orderId, String newTimeWindow);
  Future<VendorSubscriptionModel> toggleDeliverySlot(
      DateTime date, String orderId, bool isActive);
  Future<VendorSubscriptionModel> pauseSubscription(bool isPaused);
  List<MealItemModel> getAlternateMealsPool();
}

class SubscriptionLocalDataSourceImpl implements SubscriptionLocalDataSource {
  final LocalStorageService _storageService;

  SubscriptionLocalDataSourceImpl(this._storageService);

  @override
  Future<VendorSubscriptionModel> getSubscription() async {
    final rawData = _storageService.getSavedSubscription();
    if (rawData != null) {
      try {
        return VendorSubscriptionModel.fromJson(rawData);
      } catch (_) {
        // Fallback to initial seed if stored format changed
      }
    }
    final initial = MockSeedData.initialSubscription();
    await _storageService.saveSubscription(initial.toJson());
    return initial;
  }

  @override
  List<MealItemModel> getAlternateMealsPool() {
    return MockSeedData.alternateMealsPool();
  }

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
    final current = await getSubscription();
    final updatedSchedules = current.schedules.map((schedule) {
      if (_isSameDay(schedule.date, date)) {
        final updatedOrders = schedule.orders.map((order) {
          final itemsToSkip = orderToItemIdsMap[order.id];
          if (itemsToSkip != null && itemsToSkip.isNotEmpty) {
            final updatedItems = order.items
                .where((item) => !itemsToSkip.contains(item.id))
                .toList();
            return _copyOrderWithItems(order, updatedItems);
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

    final updatedModel = VendorSubscriptionModel(
      vendorId: current.vendorId,
      vendorName: current.vendorName,
      vendorLogoUrl: current.vendorLogoUrl,
      planSummary: current.planSummary,
      planName: current.planName,
      isPaused: current.isPaused,
      schedules: updatedSchedules,
    );

    await _storageService.saveSubscription(updatedModel.toJson());
    return updatedModel;
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
    final current = await getSubscription();

    MealItemModel? itemA;
    MealItemModel? itemB;

    // Check if itemB comes from pool
    final poolItem = MockSeedData.alternateMealsPool()
        .where((m) => m.id == targetItemId)
        .firstOrNull;

    // Find source item
    for (final s in current.schedules) {
      if (_isSameDay(s.date, sourceDate)) {
        for (final o in s.orders) {
          if (o.id == sourceOrderId) {
            itemA = o.items.where((i) => i.id == sourceItemId).firstOrNull;
          }
        }
      }
      if (_isSameDay(s.date, targetDate)) {
        for (final o in s.orders) {
          if (o.id == targetOrderId) {
            itemB = o.items.where((i) => i.id == targetItemId).firstOrNull;
          }
        }
      }
    }

    itemB ??= poolItem;

    if (itemA == null || itemB == null) {
      return current;
    }

    final replacementForA = itemB;
    final replacementForB = itemA;

    final updatedSchedules = current.schedules.map((schedule) {
      final isSource = _isSameDay(schedule.date, sourceDate);
      final isTarget = _isSameDay(schedule.date, targetDate);

      if (!isSource && !isTarget) return schedule;

      final updatedOrders = schedule.orders.map((order) {
        if (isSource && order.id == sourceOrderId) {
          final newItems = order.items.map((i) {
            if (i.id == sourceItemId) {
              return replacementForA;
            }
            return i;
          }).toList();
          return _copyOrderWithItems(order, newItems);
        }

        if (isTarget && order.id == targetOrderId && poolItem == null) {
          final newItems = order.items.map((i) {
            if (i.id == targetItemId) {
              return replacementForB;
            }
            return i;
          }).toList();
          return _copyOrderWithItems(order, newItems);
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

    final updatedModel = VendorSubscriptionModel(
      vendorId: current.vendorId,
      vendorName: current.vendorName,
      vendorLogoUrl: current.vendorLogoUrl,
      planSummary: current.planSummary,
      planName: current.planName,
      isPaused: current.isPaused,
      schedules: updatedSchedules,
    );

    await _storageService.saveSubscription(updatedModel.toJson());
    return updatedModel;
  }

  @override
  Future<VendorSubscriptionModel> moveOrderItems(
    DateTime sourceDate,
    String sourceOrderId,
    DateTime targetDate,
    String targetOrderId,
  ) async {
    final current = await getSubscription();
    List<String> allItemIds = [];
    for (final s in current.schedules) {
      if (_isSameDay(s.date, sourceDate)) {
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
    final current = await getSubscription();

    List<MealItemModel> itemsToMove = [];
    for (final s in current.schedules) {
      if (_isSameDay(s.date, sourceDate)) {
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

    if (itemsToMove.isEmpty) return current;

    final updatedSchedules = current.schedules.map((schedule) {
      final isSource = _isSameDay(schedule.date, sourceDate);
      final isTarget = _isSameDay(schedule.date, targetDate);

      if (!isSource && !isTarget) return schedule;

      final updatedOrders = schedule.orders.map((order) {
        if (isSource) {
          final movingIds = sourceOrderToItemIdsMap[order.id];
          if (movingIds != null && movingIds.isNotEmpty) {
            final remainingItems =
                order.items.where((i) => !movingIds.contains(i.id)).toList();
            return _copyOrderWithItems(order, remainingItems);
          }
        }
        if (isTarget && order.id == targetOrderId) {
          final combinedItems = [...order.items, ...itemsToMove];
          return _copyOrderWithItems(order, combinedItems);
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

    final updatedModel = VendorSubscriptionModel(
      vendorId: current.vendorId,
      vendorName: current.vendorName,
      vendorLogoUrl: current.vendorLogoUrl,
      planSummary: current.planSummary,
      planName: current.planName,
      isPaused: current.isPaused,
      schedules: updatedSchedules,
    );

    await _storageService.saveSubscription(updatedModel.toJson());
    return updatedModel;
  }

  @override
  Future<VendorSubscriptionModel> rescheduleOrder(
      DateTime date, String orderId, String newTimeWindow) async {
    final current = await getSubscription();
    final updatedCutoff = _computeCutoffNotice(newTimeWindow);

    final updatedSchedules = current.schedules.map((schedule) {
      if (_isSameDay(schedule.date, date)) {
        final updatedOrders = schedule.orders.map((order) {
          if (order.id == orderId) {
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

    final updatedModel = VendorSubscriptionModel(
      vendorId: current.vendorId,
      vendorName: current.vendorName,
      vendorLogoUrl: current.vendorLogoUrl,
      planSummary: current.planSummary,
      planName: current.planName,
      isPaused: current.isPaused,
      schedules: updatedSchedules,
    );

    await _storageService.saveSubscription(updatedModel.toJson());
    return updatedModel;
  }

  @override
  Future<VendorSubscriptionModel> toggleDeliverySlot(
      DateTime date, String orderId, bool isActive) async {
    final current = await getSubscription();
    final updatedSchedules = current.schedules.map((schedule) {
      if (_isSameDay(schedule.date, date)) {
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

    final updatedModel = VendorSubscriptionModel(
      vendorId: current.vendorId,
      vendorName: current.vendorName,
      vendorLogoUrl: current.vendorLogoUrl,
      planSummary: current.planSummary,
      planName: current.planName,
      isPaused: current.isPaused,
      schedules: updatedSchedules,
    );

    await _storageService.saveSubscription(updatedModel.toJson());
    return updatedModel;
  }

  @override
  Future<VendorSubscriptionModel> pauseSubscription(bool isPaused) async {
    final current = await getSubscription();
    final updatedModel = VendorSubscriptionModel(
      vendorId: current.vendorId,
      vendorName: current.vendorName,
      vendorLogoUrl: current.vendorLogoUrl,
      planSummary: current.planSummary,
      planName: current.planName,
      isPaused: isPaused,
      schedules: current.schedules,
    );

    await _storageService.saveSubscription(updatedModel.toJson());
    return updatedModel;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _computeCutoffNotice(String timeWindow) {
    if (timeWindow.contains('8:00') || timeWindow.contains('9:00 am')) {
      return 'Edits allowed until 7:00 AM the day of your Order.';
    } else if (timeWindow.contains('12:30') ||
        timeWindow.contains('1:00') ||
        timeWindow.contains('1:30')) {
      return 'Edits allowed until 11:00 AM the day of your Order.';
    } else if (timeWindow.contains('4:00') || timeWindow.contains('5:00')) {
      return 'Edits allowed until 3:00 PM the day of your Order.';
    } else if (timeWindow.contains('7:30') || timeWindow.contains('8:30')) {
      return 'Edits allowed until 6:00 PM the day of your Order.';
    }
    return 'Edits allowed until 2 hours before the day of your Order.';
  }

  MealOrderModel _copyOrderWithItems(
      MealOrderModel order, List<MealItemModel> items) {
    return MealOrderModel(
      id: order.id,
      orderNumber: order.orderNumber,
      orderType: order.orderType,
      location: order.location,
      timeWindow: order.timeWindow,
      isSlotActive: order.isSlotActive,
      cutoffNotice: order.cutoffNotice,
      items: items,
      previewImageUrl: order.previewImageUrl,
    );
  }
}
