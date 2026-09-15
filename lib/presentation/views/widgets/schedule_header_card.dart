import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/daily_schedule.dart';
import 'day_selector_carousel.dart';

class ScheduleHeaderCard extends StatelessWidget {
  final List<DailySchedule> schedules;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool isPaused;
  final VoidCallback onPauseToggle;
  final VoidCallback onAddSlots;

  const ScheduleHeaderCard({
    super.key,
    required this.schedules,
    required this.selectedDate,
    required this.onDateSelected,
    required this.isPaused,
    required this.onPauseToggle,
    required this.onAddSlots,
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
          // Section Heading
          const Text(
            'Schedule',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 14),

          // Day Selector Carousel
          DaySelectorCarousel(
            schedules: schedules,
            selectedDate: selectedDate,
            onDateSelected: onDateSelected,
          ),
          const SizedBox(height: 16),

          // Action Buttons: Pause Subscription & Add Slots
          Row(
            children: [
              // Pause / Resume Subscription Button
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: onPauseToggle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: isPaused ? AppColors.danger : AppColors.textPrimary,
                      side: BorderSide(
                        color: isPaused ? AppColors.danger : AppColors.chipBorder,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    icon: Icon(
                      isPaused ? Icons.play_arrow : Icons.pause,
                      size: 16,
                      color: isPaused ? AppColors.danger : AppColors.textPrimary,
                    ),
                    label: Text(
                      isPaused ? 'Resume Plan' : 'Pause Subscription',
                      style: AppTextStyles.actionButton.copyWith(
                        color: isPaused ? AppColors.danger : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Add Slots Button
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onAddSlots,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    icon: const Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Add Slots',
                      style: AppTextStyles.actionButton,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Helper Note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                'Drag items between slots to reorganize',
                style: AppTextStyles.helperText.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
