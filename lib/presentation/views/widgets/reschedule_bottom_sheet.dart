import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/meal_order.dart';

class RescheduleBottomSheet extends StatefulWidget {
  final MealOrder order;
  final DateTime currentDate;
  final ValueChanged<String> onSlotSelected;

  const RescheduleBottomSheet({
    super.key,
    required this.order,
    required this.currentDate,
    required this.onSlotSelected,
  });

  @override
  State<RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<RescheduleBottomSheet> {
  late String _selectedSlot;

  final List<Map<String, dynamic>> _availableSlots = [
    {
      'label': 'Breakfast Window',
      'time': '8:00 am - 9:00 am',
      'cutoff': 'Cut-off: 7:00 AM',
      'isAvailable': true,
    },
    {
      'label': 'Lunch Window',
      'time': '12:30 pm - 1:30 pm',
      'cutoff': 'Cut-off: 11:00 AM',
      'isAvailable': true,
    },
    {
      'label': 'Evening Window',
      'time': '4:00 pm - 5:00 pm',
      'cutoff': 'Cut-off: 3:00 PM',
      'isAvailable': true,
    },
    {
      'label': 'Dinner Window',
      'time': '7:30 pm - 8:30 pm',
      'cutoff': 'Cut-off: 6:00 PM',
      'isAvailable': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.order.timeWindow;
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
                        'Order ${widget.order.orderNumber} • ${DateFormatter.formatFullDate(widget.currentDate)}',
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

            // Slot Options List
            ...List.generate(_availableSlots.length, (index) {
              final slot = _availableSlots[index];
              final time = slot['time'] as String;
              final label = slot['label'] as String;
              final cutoff = slot['cutoff'] as String;
              final isSelected = _selectedSlot == time;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSlot = time;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0x0A111827)
                          : AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.chipBorder,
                        width: isSelected ? 1.5 : 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                time,
                                style: AppTextStyles.cardHeader.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$label • $cutoff',
                                style: AppTextStyles.helperText,
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
            const SizedBox(height: 12),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => widget.onSlotSelected(_selectedSlot),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
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
