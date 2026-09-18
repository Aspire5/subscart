import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/daily_schedule.dart';
import '../../../domain/entities/meal_order.dart';
import 'app_loading_overlay.dart';

class MoveBottomSheet extends StatefulWidget {
  final MealOrder? currentOrder;
  final DateTime currentDate;
  final List<DailySchedule> availableDays;
  final int? itemCount;
  final void Function(DateTime targetDate, int targetOrderNumber) onMoveConfirmed;

  const MoveBottomSheet({
    super.key,
    this.currentOrder,
    required this.currentDate,
    required this.availableDays,
    this.itemCount,
    required this.onMoveConfirmed,
  });

  @override
  State<MoveBottomSheet> createState() => _MoveBottomSheetState();
}

class _MoveBottomSheetState extends State<MoveBottomSheet> {
  late DateTime _selectedTargetDate;
  int _selectedOrderNumber = 1;
  bool _isSubmitting = false;

  DailySchedule? get _selectedSchedule {
    for (final s in widget.availableDays) {
      if (DateFormatter.isSameDay(s.date, _selectedTargetDate)) {
        return s;
      }
    }
    return null;
  }

  bool _isSlotPastCutoff(int slotNum) {
    final schedule = _selectedSchedule;
    if (schedule == null) return false;
    for (final order in schedule.orders) {
      if (order.orderNumber == slotNum) {
        return order.isPastCutoff;
      }
    }
    return false;
  }

  MealOrder? get _selectedTargetOrder {
    final schedule = _selectedSchedule;
    if (schedule == null) return null;
    for (final order in schedule.orders) {
      if (order.orderNumber == _selectedOrderNumber) {
        return order;
      }
    }
    return null;
  }

  String _defaultTimeWindowForSlot(int slotNum) {
    switch (slotNum) {
      case 1:
        return '8:00 am - 9:00 am';
      case 2:
        return '12:30 pm - 1:30 pm';
      case 3:
        return '7:30 pm - 8:30 pm';
      default:
        return 'Delivery Window';
    }
  }

  String _defaultCutoffForSlot(int slotNum) {
    switch (slotNum) {
      case 1:
        return 'Edits allowed until 7:00 AM the day of your Order.';
      case 2:
        return 'Edits allowed until 11:00 AM the day of your Order.';
      case 3:
        return 'Edits allowed until 6:00 PM the day of your Order.';
      default:
        return '';
    }
  }

  void _adjustSelectedSlotIfPastCutoff() {
    if (_isSlotPastCutoff(_selectedOrderNumber)) {
      for (int i = 1; i <= 3; i++) {
        if (!_isSlotPastCutoff(i)) {
          _selectedOrderNumber = i;
          return;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedTargetDate = widget.availableDays.isNotEmpty
        ? widget.availableDays.first.date
        : widget.currentDate.add(const Duration(days: 1));
    _selectedOrderNumber = widget.currentOrder?.orderNumber ?? 1;
    _adjustSelectedSlotIfPastCutoff();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.itemCount;
    final allSlotsClosed = [1, 2, 3].every(_isSlotPastCutoff);
    final subtitleText = count != null && count > 0
        ? 'Moving $count selected ${count == 1 ? "meal" : "meals"} from ${DateFormatter.formatShortDay(widget.currentDate)} ${widget.currentDate.day}'
        : (widget.currentOrder != null
            ? 'Move all meals from Order ${widget.currentOrder!.orderNumber} (${DateFormatter.formatShortDay(widget.currentDate)} ${widget.currentDate.day})'
            : 'Move selected meals from ${DateFormatter.formatShortDay(widget.currentDate)} ${widget.currentDate.day}');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.subtleBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Move Order Meals',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitleText,
                        style: AppTextStyles.screenSubtitle,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  splashRadius: 18,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Target Day Selection
            const Text(
              'Select Target Day',
              style: AppTextStyles.cardHeader,
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.availableDays.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final day = widget.availableDays[index];
                  final isSelected =
                      DateFormatter.isSameDay(day.date, _selectedTargetDate);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTargetDate = day.date;
                        _adjustSelectedSlotIfPastCutoff();
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.chipBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.chipBorder,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day.dayOfWeek,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white70
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${day.dayNumber}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Target Order Slot Selection
            const Text(
              'Select Target Order Slot',
              style: AppTextStyles.cardHeader,
            ),
            const SizedBox(height: 10),

            Row(
              children: [1, 2, 3].map((slotNum) {
                final isPastCutoff = _isSlotPastCutoff(slotNum);
                final isSelected = !isPastCutoff && _selectedOrderNumber == slotNum;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: slotNum < 3 ? 8.0 : 0.0,
                    ),
                    child: InkWell(
                      onTap: isPastCutoff
                          ? null
                          : () {
                              setState(() {
                                _selectedOrderNumber = slotNum;
                              });
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isPastCutoff
                              ? const Color(0xFFF3F4F6)
                              : (isSelected
                                  ? const Color(0x14111827)
                                  : AppColors.chipBackground),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPastCutoff
                                ? AppColors.subtleBorder
                                : (isSelected
                                    ? AppColors.primaryDark
                                    : AppColors.chipBorder),
                            width: isSelected ? 1.5 : 0.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isPastCutoff) ...[
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 12,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              'Order $slotNum',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isPastCutoff
                                    ? AppColors.textMuted
                                    : (isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (allSlotsClosed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.history_toggle_off_rounded,
                    size: 13,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'All slots on this date are closed for modifications.',
                    style: AppTextStyles.bodyNotice.copyWith(
                      color: const Color(0xFFD97706),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ],

            // Dynamic Target Order Preview Card
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: _buildTargetOrderPreview(
                _selectedTargetOrder,
                _isSlotPastCutoff(_selectedOrderNumber),
              ),
            ),
            const SizedBox(height: 18),

            // Confirm Move Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isSubmitting || allSlotsClosed || _isSlotPastCutoff(_selectedOrderNumber))
                    ? null
                    : () {
                        setState(() => _isSubmitting = true);
                        widget.onMoveConfirmed(
                          _selectedTargetDate,
                          _selectedOrderNumber,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: AppCustomSpinner(size: 20, color: Colors.white),
                      )
                    : const Text(
                        'Confirm Move',
                        style: AppTextStyles.actionButton,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetOrderPreview(MealOrder? order, bool isPastCutoff) {
    final hasItems = order != null && order.items.isNotEmpty;
    final timeWindow = order?.timeWindow ?? _defaultTimeWindowForSlot(_selectedOrderNumber);
    final cutoffNotice = order?.cutoffNotice ?? _defaultCutoffForSlot(_selectedOrderNumber);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.subtleBorder,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Time Window badge + Cut-off notice
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isPastCutoff
                      ? const Color(0xFFFEF3C7)
                      : const Color(0x14111827),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPastCutoff
                          ? Icons.history_toggle_off_rounded
                          : Icons.access_time_rounded,
                      size: 13,
                      color: isPastCutoff
                          ? const Color(0xFFD97706)
                          : AppColors.primaryDark,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      timeWindow,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isPastCutoff
                            ? const Color(0xFFB45309)
                            : AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isPastCutoff)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Modifications closed',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                )
              else if (cutoffNotice.isNotEmpty)
                Flexible(
                  child: Text(
                    cutoffNotice,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Items section
          if (hasItems) ...[
            Row(
              children: [
                Text(
                  'Items in this Order (${order.items.length})',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '• your moved meals join these',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final item = order.items[idx];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.subtleBorder.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: item.imageUrl.isNotEmpty
                              ? Image.network(
                                  item.imageUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildFallbackThumbnail(),
                                )
                              : _buildFallbackThumbnail(),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${item.calories} kcal',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.subtleBorder.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPastCutoff
                          ? 'This slot is past its cut-off time.'
                          : 'Slot is currently empty (0 items) — meals will arrive here.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      width: 36,
      height: 36,
      color: const Color(0xFFF3F4F6),
      child: const Icon(
        Icons.restaurant_menu_rounded,
        size: 16,
        color: AppColors.textMuted,
      ),
    );
  }
}
