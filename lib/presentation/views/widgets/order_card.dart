import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/meal_item.dart';
import '../../../domain/entities/meal_order.dart';
import 'meal_item_tile.dart';

class OrderCard extends StatelessWidget {
  final MealOrder order;
  final VoidCallback onReschedule;
  final ValueChanged<bool> onSlotToggle;
  final bool Function(String itemId) isItemSelected;
  final void Function(MealItem item, MealOrder order) onToggleItemSelect;
  final VoidCallback? onAddMealToOrder;

  const OrderCard({
    super.key,
    required this.order,
    required this.onReschedule,
    required this.onSlotToggle,
    required this.isItemSelected,
    required this.onToggleItemSelect,
    this.onAddMealToOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.subtleBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A111827),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Box Thumbnail
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.subtleBorder),
                      color: const Color(0xFFF3F4F6),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: order.previewImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Order Title
                  Text(
                    'Order ${order.orderNumber}',
                    style: AppTextStyles.cardHeader,
                  ),
                  const SizedBox(width: 8),

                  // Delivery Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.sageBadgeBg,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      order.orderType,
                      style: AppTextStyles.badge,
                    ),
                  ),
                ],
              ),

              // Re-schedule Button
              InkWell(
                onTap: order.isPastCutoff ? null : onReschedule,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        order.isPastCutoff ? Icons.lock_outline_rounded : Icons.calendar_today_outlined,
                        size: 15,
                        color: order.isPastCutoff ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Re-schedule',
                        style: AppTextStyles.actionButton.copyWith(
                          color: order.isPastCutoff ? AppColors.textMuted : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Location & Time Slot Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.chipBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.chipBorder, width: 0.8),
            ),
            child: Row(
              children: [
                // Location Item
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.location,
                      style: AppTextStyles.chipText.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),

                // Subtle Divider
                Container(
                  height: 16,
                  width: 1,
                  color: AppColors.chipBorder,
                ),
                const SizedBox(width: 10),

                // Time Slot Item (Tappable to reschedule)
                Expanded(
                  child: InkWell(
                    onTap: order.isPastCutoff ? null : onReschedule,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            order.isPastCutoff ? Icons.lock_outline_rounded : Icons.schedule_outlined,
                            size: 16,
                            color: order.isPastCutoff ? AppColors.textMuted : AppColors.textPrimary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.timeWindow,
                              style: AppTextStyles.chipText.copyWith(
                                fontWeight: FontWeight.w600,
                                color: order.isPastCutoff ? AppColors.textMuted : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            order.isPastCutoff ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
                            size: order.isPastCutoff ? 14 : 18,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),

          // Delivery Slot Toggle Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Slot',
                style: AppTextStyles.cardHeader,
              ),
              CupertinoSwitch(
                value: order.isSlotActive,
                activeTrackColor: AppColors.primaryDark,
                onChanged: order.isPastCutoff ? null : onSlotToggle,
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Cut-off Notice
          if (order.isPastCutoff) ...[
            Row(
              children: [
                const Icon(
                  Icons.history_toggle_off_rounded,
                  size: 14,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 5),
                Text(
                  order.cutoffNotice.isNotEmpty
                      ? order.cutoffNotice
                      : 'Cut-off passed • Order in preparation',
                  style: AppTextStyles.bodyNotice.copyWith(
                    color: const Color(0xFFD97706),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Skip, swap, and move actions are closed for this order.',
              style: AppTextStyles.bodyNotice.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ] else
            RichText(
              text: TextSpan(
                text: 'Edits allowed until ',
                style: AppTextStyles.bodyNotice,
                children: [
                  TextSpan(
                    text: _extractCutoffTime(order.cutoffNotice),
                    style: AppTextStyles.bodyNotice.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: _extractCutoffRest(order.cutoffNotice),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.divider),

          // Meal Items
          if (order.items.isEmpty)
            _buildEmptyItemsState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(height: 1, color: AppColors.divider),
              ),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return MealItemTile(
                  item: item,
                  isSelected: isItemSelected(item.id),
                  isSelectable: !order.isPastCutoff,
                  onToggleSelect: () => onToggleItemSelect(item, order),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.no_meals_outlined,
            size: 28,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 6),
          Text(
            'No meals in this slot',
            style: AppTextStyles.itemTitle.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Items were moved or skipped for this order.',
            style: AppTextStyles.helperText,
          ),
        ],
      ),
    );
  }

  String _extractCutoffTime(String notice) {
    if (notice.contains('until ')) {
      final afterUntil = notice.split('until ').last;
      if (afterUntil.contains(' the day')) {
        return afterUntil.split(' the day').first;
      }
    }
    return '3:00 PM';
  }

  String _extractCutoffRest(String notice) {
    if (notice.contains(' the day')) {
      return ' the day ${notice.split(' the day').last.trimLeft()}';
    }
    return ' the day of your Order.';
  }
}
