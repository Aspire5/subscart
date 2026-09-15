import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/daily_schedule.dart';
import '../../../domain/entities/meal_order.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedTargetDate = widget.availableDays.isNotEmpty
        ? widget.availableDays.first.date
        : widget.currentDate.add(const Duration(days: 1));
    _selectedOrderNumber = widget.currentOrder?.orderNumber ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.itemCount;
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
                final isSelected = _selectedOrderNumber == slotNum;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: slotNum < 3 ? 8.0 : 0.0,
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedOrderNumber = slotNum;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0x14111827)
                              : AppColors.chipBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryDark
                                : AppColors.chipBorder,
                            width: isSelected ? 1.5 : 0.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Order $slotNum',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Confirm Move Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => widget.onMoveConfirmed(
                  _selectedTargetDate,
                  _selectedOrderNumber,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
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
}
