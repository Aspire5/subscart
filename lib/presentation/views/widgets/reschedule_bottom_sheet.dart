import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/daily_schedule.dart';
import '../../../domain/entities/meal_order.dart';
import 'app_loading_overlay.dart';

class RescheduleBottomSheet extends StatefulWidget {
  final MealOrder order;
  final DateTime currentDate;
  final List<DailySchedule> availableSchedules;
  final Future<Map<String, dynamic>> Function(DateTime targetDate)
      onFetchSlotAvailability;
  final void Function(
    DateTime targetDate,
    String selectedSlot,
    String? selectedSlotId,
  ) onConfirm;

  const RescheduleBottomSheet({
    super.key,
    required this.order,
    required this.currentDate,
    required this.availableSchedules,
    required this.onFetchSlotAvailability,
    required this.onConfirm,
  });

  @override
  State<RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<RescheduleBottomSheet> {
  late DateTime _selectedDate;
  String? _selectedSlot;
  String? _selectedSlotId;

  bool _isLoadingSlots = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _slots = [];
  bool _hasAvailableSlots = true;

  @override
  void initState() {
    super.initState();
    // Default to the next day or same day if in schedules
    _selectedDate = widget.currentDate;
    _selectedSlot = widget.order.timeWindow;
    _loadSlotsForDate(_selectedDate);
  }

  Future<void> _loadSlotsForDate(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
    });

    try {
      final res = await widget.onFetchSlotAvailability(date);
      final rawSlots = (res['slots'] as List<dynamic>?) ?? [];
      final parsedSlots = rawSlots.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final hasAvailable = res['hasAvailableSlots'] as bool? ?? parsedSlots.any((s) => s['isAvailable'] == true);
      final nextSlot = res['nextAvailableSlot'] as Map<String, dynamic>?;

      String? newSelectedSlot = _selectedSlot;
      String? newSelectedSlotId;

      // Check if current selected slot is available on this date
      final matchingCurrent = parsedSlots.firstWhere(
        (s) =>
            s['displayTime'] == _selectedSlot ||
            s['name'] == _selectedSlot,
        orElse: () => <String, dynamic>{},
      );

      if (matchingCurrent.isNotEmpty && matchingCurrent['isAvailable'] == true) {
        newSelectedSlot = matchingCurrent['displayTime'] as String?;
        newSelectedSlotId = matchingCurrent['id'] as String?;
      } else if (nextSlot != null && nextSlot['displayTime'] != null) {
        // Auto-assign to next available slot
        newSelectedSlot = nextSlot['displayTime'] as String?;
        newSelectedSlotId = nextSlot['id'] as String?;
      } else {
        final firstAvail = parsedSlots.firstWhere(
          (s) => s['isAvailable'] == true,
          orElse: () => <String, dynamic>{},
        );
        if (firstAvail.isNotEmpty) {
          newSelectedSlot = firstAvail['displayTime'] as String?;
          newSelectedSlotId = firstAvail['id'] as String?;
        } else {
          newSelectedSlot = null;
          newSelectedSlotId = null;
        }
      }

      if (mounted) {
        setState(() {
          _slots = parsedSlots;
          _hasAvailableSlots = hasAvailable;
          _selectedSlot = newSelectedSlot;
          _selectedSlotId = newSelectedSlotId;
          _isLoadingSlots = false;
        });
      }
    } catch (_) {
      // Fallback slot definition
      if (mounted) {
        setState(() {
          _slots = [
            {
              'name': 'Breakfast Window',
              'displayTime': '8:00 am - 9:00 am',
              'cutoffNotice': 'Edits allowed until 7:00 AM the day of your Order.',
              'isAvailable': true,
            },
            {
              'name': 'Lunch Window',
              'displayTime': '12:30 pm - 1:30 pm',
              'cutoffNotice': 'Edits allowed until 11:00 AM the day of your Order.',
              'isAvailable': true,
            },
            {
              'name': 'Evening Window',
              'displayTime': '4:00 pm - 5:00 pm',
              'cutoffNotice': 'Edits allowed until 3:00 PM the day of your Order.',
              'isAvailable': true,
            },
            {
              'name': 'Dinner Window',
              'displayTime': '7:30 pm - 8:30 pm',
              'cutoffNotice': 'Edits allowed until 6:00 PM the day of your Order.',
              'isAvailable': true,
            },
          ];
          _hasAvailableSlots = true;
          _isLoadingSlots = false;
        });
      }
    }
  }

  void _onDateChanged(DateTime date) {
    if (DateFormatter.isSameDay(_selectedDate, date)) return;
    setState(() {
      _selectedDate = date;
    });
    _loadSlotsForDate(date);
  }

  @override
  Widget build(BuildContext context) {
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
                        'Reschedule Delivery',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Order ${widget.order.orderNumber} • Current: ${DateFormatter.formatFullDate(widget.currentDate)}',
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

            // Target Date Selection Header
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 6),
                Text(
                  'Select Target Date',
                  style: AppTextStyles.cardHeader.copyWith(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Target Date Carousel
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.availableSchedules.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final schedule = widget.availableSchedules[index];
                  final isSelected =
                      DateFormatter.isSameDay(schedule.date, _selectedDate);
                  final isCurrent =
                      DateFormatter.isSameDay(schedule.date, widget.currentDate);

                  return InkWell(
                    onTap: () => _onDateChanged(schedule.date),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 58,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.chipBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryDark
                              : isCurrent
                                  ? AppColors.primaryDark.withValues(alpha: 0.4)
                                  : AppColors.chipBorder,
                          width: isSelected || isCurrent ? 1.5 : 0.8,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            schedule.dayOfWeek,
                            style: AppTextStyles.dayLabel.copyWith(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white70
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            schedule.dayNumber.toString(),
                            style: AppTextStyles.dayNumber.copyWith(
                              fontSize: 15,
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
            const SizedBox(height: 18),

            // Slot Selection Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Delivery Time Window',
                      style: AppTextStyles.cardHeader.copyWith(fontSize: 13),
                    ),
                  ],
                ),
                if (_isLoadingSlots)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Slots List or Unavailable Notice
            if (!_hasAvailableSlots)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 0.8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'All delivery cut-off times for this date have passed. Please select an upcoming date.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ...List.generate(_slots.length, (index) {
              final slot = _slots[index];
              final time = (slot['displayTime'] ?? slot['time']) as String;
              final name = (slot['name'] ?? slot['label'] ?? 'Delivery Window') as String;
              final cutoff = (slot['cutoffNotice'] ?? slot['cutoff'] ?? '') as String;
              final isAvailable = slot['isAvailable'] as bool? ?? true;
              final isSelected = _selectedSlot == time && isAvailable;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: isAvailable
                      ? () {
                          setState(() {
                            _selectedSlot = time;
                            _selectedSlotId = slot['id'] as String?;
                          });
                        }
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: !isAvailable
                          ? const Color(0xFFF9FAFB)
                          : isSelected
                              ? const Color(0x0A111827)
                              : AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: !isAvailable
                            ? AppColors.subtleBorder.withValues(alpha: 0.5)
                            : isSelected
                                ? AppColors.primaryDark
                                : AppColors.chipBorder,
                        width: isSelected ? 1.5 : 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          !isAvailable
                              ? Icons.block_rounded
                              : isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                          color: !isAvailable
                              ? AppColors.textMuted.withValues(alpha: 0.4)
                              : isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    time,
                                    style: AppTextStyles.cardHeader.copyWith(
                                      fontSize: 13.5,
                                      color: isAvailable
                                          ? AppColors.textPrimary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                  if (!isAvailable) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Cut-off passed',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$name${cutoff.isNotEmpty ? " • $cutoff" : ""}',
                                style: AppTextStyles.helperText.copyWith(
                                  fontSize: 11,
                                  color: isAvailable
                                      ? AppColors.textMuted
                                      : AppColors.textMuted.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_selectedSlot != null &&
                        _hasAvailableSlots &&
                        !_isSubmitting)
                    ? () {
                        setState(() => _isSubmitting = true);
                        widget.onConfirm(
                          _selectedDate,
                          _selectedSlot!,
                          _selectedSlotId,
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  disabledForegroundColor: const Color(0xFF9CA3AF),
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
                        'Confirm Reschedule',
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
