import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../controllers/schedule_controller.dart';
import 'widgets/app_loading_overlay.dart';
import 'widgets/bulk_action_bar.dart';
import 'widgets/order_card.dart';
import 'widgets/schedule_header_card.dart';
import 'widgets/top_nav_bar.dart';

class ScheduleView extends GetView<ScheduleController> {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: AppInlineLoader(
              message: 'Loading your meal subscription...',
            ),
          );
        }

        final subscription = controller.subscription.value;
        if (subscription == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Failed to load meal schedule'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.loadSubscriptionData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final currentSchedule = controller.currentSchedule;
        final isAnySelected = controller.selectedCount > 0;

        return AppLoadingOverlay(
          isLoading: controller.isMutating.value,
          message: controller.loadingMessage.value.isNotEmpty
              ? controller.loadingMessage.value
              : 'Applying changes...',
          child: Stack(
            children: [
              Column(
                children: [
                  // Top App Bar
                  TopNavBar(
                    vendorName: subscription.vendorName,
                    planSummary: subscription.planSummary,
                    vendorLogoUrl: subscription.vendorLogoUrl,
                    onBackTap: () {},
                    onMoreTap: () {},
                  ),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        isAnySelected ? 90 : 16,
                      ),
                      child: Column(
                        children: [
                          // Schedule Header Card with Day Selector Carousel
                          ScheduleHeaderCard(
                            schedules: subscription.schedules,
                            selectedDate: controller.selectedDate.value,
                            onDateSelected: controller.selectDate,
                            isPaused: subscription.isPaused,
                            onPauseToggle: controller.togglePauseSubscription,
                            onAddSlots: controller.onAddSlotsTapped,
                            timezoneLabel: subscription.timezoneDisplay,
                          ),
                          const SizedBox(height: 14),

                          // Daily Orders
                          if (currentSchedule != null)
                            ...currentSchedule.orders.map((order) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: OrderCard(
                                  order: order,
                                  onReschedule: () =>
                                      controller.openRescheduleSheet(order),
                                  onSlotToggle: (val) =>
                                      controller.toggleDeliverySlot(order, val),
                                  isItemSelected: controller.isItemSelected,
                                  onToggleItemSelect:
                                      controller.toggleItemSelection,
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Floating Non-Blocking Batch Action Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: BulkActionBar(
                    selectedCount: controller.selectedCount,
                    isEnabled: !controller.isMutating.value,
                    onSkip: controller.batchSkipSelected,
                    onSwap: controller.openBatchSwapSheet,
                    onMove: controller.openBatchMoveSheet,
                    onClear: controller.clearSelection,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
