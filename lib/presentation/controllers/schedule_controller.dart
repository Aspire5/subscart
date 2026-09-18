import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/daily_schedule.dart';
import '../../domain/entities/meal_item.dart';
import '../../domain/entities/meal_order.dart';
import '../../domain/entities/vendor_subscription.dart';
import '../../domain/usecases/get_subscription_schedule_usecase.dart';
import '../../domain/usecases/move_meal_items_batch_usecase.dart';
import '../../domain/usecases/move_order_items_usecase.dart';
import '../../domain/usecases/pause_subscription_usecase.dart';
import '../../domain/usecases/reschedule_order_usecase.dart';
import '../../domain/usecases/skip_meal_item_usecase.dart';
import '../../domain/usecases/skip_meal_items_batch_usecase.dart';
import '../../domain/usecases/swap_meal_item_usecase.dart';
import '../../domain/usecases/toggle_delivery_slot_usecase.dart';
import '../views/widgets/move_bottom_sheet.dart';
import '../views/widgets/reschedule_bottom_sheet.dart';
import '../views/widgets/swap_bottom_sheet.dart';

class ScheduleController extends GetxController {
  final GetSubscriptionScheduleUseCase getSubscriptionUseCase;
  final SkipMealItemUseCase skipMealItemUseCase;
  final SkipMealItemsBatchUseCase skipMealItemsBatchUseCase;
  final SwapMealItemUseCase swapMealItemUseCase;
  final MoveOrderItemsUseCase moveOrderItemsUseCase;
  final MoveMealItemsBatchUseCase moveMealItemsBatchUseCase;
  final RescheduleOrderUseCase rescheduleOrderUseCase;
  final ToggleDeliverySlotUseCase toggleDeliverySlotUseCase;
  final PauseSubscriptionUseCase pauseSubscriptionUseCase;

  ScheduleController({
    required this.getSubscriptionUseCase,
    required this.skipMealItemUseCase,
    required this.skipMealItemsBatchUseCase,
    required this.swapMealItemUseCase,
    required this.moveOrderItemsUseCase,
    required this.moveMealItemsBatchUseCase,
    required this.rescheduleOrderUseCase,
    required this.toggleDeliverySlotUseCase,
    required this.pauseSubscriptionUseCase,
  });

  // Initial full-page load state
  final RxBool isLoading = true.obs;

  // Mutating state for async actions (skips, moves, swaps, reschedules, toggles)
  final RxBool isMutating = false.obs;
  final RxString loadingMessage = ''.obs;

  final Rx<VendorSubscription?> subscription = Rx<VendorSubscription?>(null);
  final Rx<DateTime> selectedDate = Rx<DateTime>(DateTime(2026, 9, 15));

  // Multi-selection state: itemId -> orderId
  final RxMap<String, String> selectedItemOrderMap = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadSubscriptionData();
  }

  int get selectedCount => selectedItemOrderMap.length;

  bool isItemSelected(String itemId) =>
      selectedItemOrderMap.containsKey(itemId);

  void toggleItemSelection(MealItem item, MealOrder order) {
    if (isMutating.value) return; // Block selection during active mutations

    if (selectedItemOrderMap.containsKey(item.id)) {
      selectedItemOrderMap.remove(item.id);
    } else {
      selectedItemOrderMap[item.id] = order.id;
    }
  }

  void clearSelection() {
    selectedItemOrderMap.clear();
  }

  DailySchedule? get currentSchedule {
    final sub = subscription.value;
    if (sub == null) return null;
    return sub.schedules.firstWhereOrNull(
      (s) => DateFormatter.isSameDay(s.date, selectedDate.value),
    );
  }

  /// Generic blocking guard that executes an async action while showing the custom overlay
  /// and automatically drops any duplicate incoming calls.
  Future<T?> runWithBlockingLoading<T>(
    Future<T> Function() action, {
    required String message,
  }) async {
    if (isMutating.value) return null; // Mutex lock: drop duplicate calls

    isMutating.value = true;
    loadingMessage.value = message;
    try {
      return await action();
    } finally {
      isMutating.value = false;
      loadingMessage.value = '';
    }
  }

  Future<void> loadSubscriptionData() async {
    isLoading.value = true;
    try {
      final data = await getSubscriptionUseCase();
      subscription.value = data;

      // Default selected date to the second schedule day (Tue 15th) if available
      if (data.schedules.isNotEmpty) {
        final tue15 =
            data.schedules.firstWhereOrNull((s) => s.dayNumber == 15);
        selectedDate.value = tue15?.date ?? data.schedules.first.date;
      }
      clearSelection();
    } finally {
      isLoading.value = false;
    }
  }

  void selectDate(DateTime date) {
    if (isMutating.value) return; // Prevent switching days while mutation is active
    selectedDate.value = date;
    clearSelection();
  }

  /// Batch Skip all selected items across orders on the selected day
  Future<void> batchSkipSelected() async {
    if (selectedItemOrderMap.isEmpty || isMutating.value) return;

    final count = selectedItemOrderMap.length;
    final orderToItemIdsMap = <String, List<String>>{};
    for (final entry in selectedItemOrderMap.entries) {
      orderToItemIdsMap.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    await runWithBlockingLoading(() async {
      try {
        final updated = await skipMealItemsBatchUseCase(
          date: selectedDate.value,
          orderToItemIdsMap: orderToItemIdsMap,
        );
        subscription.value = updated;
        clearSelection();
        _showFeedbackSnackBar(
          title: 'Items Skipped',
          message:
              '$count ${count == 1 ? "meal item" : "meal items"} skipped from today\'s schedule.',
        );
      } catch (e) {
        _showErrorSnackBar('Failed to skip selected items');
      }
    }, message: 'Skipping $count ${count == 1 ? "meal" : "meals"}...');
  }

  /// Open Swap Sheet to swap selected meal(s) with meal(s) from other date(s)
  void openBatchSwapSheet() {
    if (selectedItemOrderMap.isEmpty || isMutating.value) return;

    final sub = subscription.value;
    if (sub == null) return;

    final otherDays = sub.schedules
        .where((s) => !DateFormatter.isSameDay(s.date, selectedDate.value))
        .toList();

    // Collect all source items with their parent orders
    final sourceList = <SelectedSwapSource>[];
    final schedule = currentSchedule;
    if (schedule != null) {
      for (final order in schedule.orders) {
        for (final item in order.items) {
          if (selectedItemOrderMap.containsKey(item.id)) {
            sourceList.add(
              SelectedSwapSource(
                item: item,
                order: order,
                date: selectedDate.value,
              ),
            );
          }
        }
      }
    }

    if (sourceList.isEmpty) return;

    Get.bottomSheet(
      SwapBottomSheet(
        sourceItems: sourceList,
        availableDays: otherDays,
        onAllSwapsConfirmed: (pairs) async {
          Get.back();
          await _executeBatchDateToDateSwaps(pairs);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _executeBatchDateToDateSwaps(
      List<CompletedSwapPair> pairs) async {
    if (isMutating.value || pairs.isEmpty) return;

    final count = pairs.length;
    await runWithBlockingLoading(() async {
      try {
        VendorSubscription? current = subscription.value;
        if (current == null) return;

        for (final pair in pairs) {
          current = await swapMealItemUseCase(
            sourceDate: pair.source.date,
            sourceOrderId: pair.source.order.id,
            sourceItemId: pair.source.item.id,
            targetDate: pair.targetDate,
            targetOrderId: pair.targetOrder.id,
            targetItemId: pair.targetItem.id,
          );
        }
        subscription.value = current;
        clearSelection();
        _showFeedbackSnackBar(
          title: 'Meals Swapped',
          message: count == 1
              ? 'Swapped "${pairs.first.source.item.name}" with "${pairs.first.targetItem.name}".'
              : 'Successfully swapped $count meals across scheduled dates.',
        );
      } catch (e) {
        _showErrorSnackBar('Failed to swap meals');
      }
    }, message: 'Swapping $count ${count == 1 ? "meal" : "meals"}...');
  }

  /// Open Move Sheet to move all selected items to a target day & order slot
  void openBatchMoveSheet() {
    if (selectedItemOrderMap.isEmpty || isMutating.value) return;

    final sub = subscription.value;
    if (sub == null) return;

    final otherDays = sub.schedules
        .where((s) => !DateFormatter.isSameDay(s.date, selectedDate.value))
        .toList();

    Get.bottomSheet(
      MoveBottomSheet(
        currentDate: selectedDate.value,
        availableDays: otherDays,
        itemCount: selectedItemOrderMap.length,
        onMoveConfirmed: (targetDate, targetOrderNumber) async {
          Get.back();
          await _executeBatchMove(
            targetDate: targetDate,
            targetOrderNumber: targetOrderNumber,
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _executeBatchMove({
    required DateTime targetDate,
    required int targetOrderNumber,
  }) async {
    if (isMutating.value || selectedItemOrderMap.isEmpty) return;

    final count = selectedItemOrderMap.length;
    await runWithBlockingLoading(() async {
      try {
        final targetOrderId = 'ord_${targetDate.day}_$targetOrderNumber';
        final sourceOrderToItemIdsMap = <String, List<String>>{};
        for (final entry in selectedItemOrderMap.entries) {
          sourceOrderToItemIdsMap
              .putIfAbsent(entry.value, () => [])
              .add(entry.key);
        }

        final updated = await moveMealItemsBatchUseCase(
          sourceDate: selectedDate.value,
          sourceOrderToItemIdsMap: sourceOrderToItemIdsMap,
          targetDate: targetDate,
          targetOrderId: targetOrderId,
        );

        subscription.value = updated;
        clearSelection();
        _showFeedbackSnackBar(
          title: 'Items Moved',
          message:
              'Moved $count ${count == 1 ? "item" : "items"} to ${DateFormatter.formatShortDay(targetDate)} ${targetDate.day} (Order $targetOrderNumber).',
        );
      } catch (e) {
        _showErrorSnackBar('Failed to move selected items');
      }
    }, message: 'Moving $count ${count == 1 ? "item" : "items"}...');
  }

  void openRescheduleSheet(MealOrder currentOrder) {
    if (isMutating.value) return;

    final sub = subscription.value;
    if (sub == null) return;

    Get.bottomSheet(
      RescheduleBottomSheet(
        order: currentOrder,
        currentDate: selectedDate.value,
        availableSchedules: sub.schedules,
        onFetchSlotAvailability: (targetDate) =>
            rescheduleOrderUseCase.getSlotAvailability(targetDate),
        onConfirm: (targetDate, newTimeSlot, slotId) async {
          Get.back();
          await _executeReschedule(
            currentOrder,
            targetDate,
            newTimeSlot,
            slotId,
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _executeReschedule(
    MealOrder order,
    DateTime targetDate,
    String newTimeSlot,
    String? slotId,
  ) async {
    if (isMutating.value) return;

    await runWithBlockingLoading(() async {
      try {
        final updated = await rescheduleOrderUseCase(
          date: selectedDate.value,
          orderId: order.id,
          targetDate: targetDate,
          newTimeWindow: newTimeSlot,
          targetSlotId: slotId,
        );
        subscription.value = updated;

        // Automatically focus the date carousel to the target date
        selectedDate.value = targetDate;

        _showFeedbackSnackBar(
          title: 'Delivery Rescheduled',
          message:
              'Order ${order.orderNumber} moved to ${DateFormatter.formatShortDay(targetDate)} ${targetDate.day} ($newTimeSlot).',
        );
      } catch (e) {
        _showErrorSnackBar('Failed to reschedule delivery');
      }
    }, message: 'Rescheduling Order ${order.orderNumber}...');
  }

  Future<void> toggleDeliverySlot(MealOrder order, bool isActive) async {
    if (isMutating.value) return;

    await runWithBlockingLoading(() async {
      try {
        final updated = await toggleDeliverySlotUseCase(
          date: selectedDate.value,
          orderId: order.id,
          isActive: isActive,
        );
        subscription.value = updated;
        _showFeedbackSnackBar(
          title: isActive ? 'Slot Activated' : 'Slot Deactivated',
          message:
              'Order ${order.orderNumber} delivery slot is now ${isActive ? "active" : "inactive"}.',
        );
      } catch (e) {
        _showErrorSnackBar('Failed to toggle delivery slot');
      }
    }, message: '${isActive ? "Activating" : "Deactivating"} slot...');
  }

  Future<void> togglePauseSubscription() async {
    final sub = subscription.value;
    if (sub == null || isMutating.value) return;

    final newState = !sub.isPaused;
    await runWithBlockingLoading(() async {
      try {
        final updated = await pauseSubscriptionUseCase(isPaused: newState);
        subscription.value = updated;
        _showFeedbackSnackBar(
          title: newState ? 'Subscription Paused' : 'Subscription Resumed',
          message: newState
              ? 'Your meal plan has been paused temporarily.'
              : 'Your meal plan is now active.',
        );
      } catch (e) {
        _showErrorSnackBar('Failed to update subscription status');
      }
    }, message: '${newState ? "Pausing" : "Resuming"} subscription...');
  }

  void onAddSlotsTapped() {
    _showFeedbackSnackBar(
      title: 'Add Extra Slots',
      message: 'Extra slots can be added for upcoming days from next cycle.',
    );
  }

  void _showFeedbackSnackBar({required String title, required String message}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.primaryDark,
      colorText: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 300),
      boxShadows: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.danger,
      colorText: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 300),
      boxShadows: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    );
  }
}
