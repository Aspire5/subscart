import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/daily_schedule.dart';

class DaySelectorCarousel extends StatelessWidget {
  final List<DailySchedule> schedules;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DaySelectorCarousel({
    super.key,
    required this.schedules,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: schedules.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = schedules[index];
          final isSelected = DateFormatter.isSameDay(item.date, selectedDate);

          return GestureDetector(
            onTap: () => onDateSelected(item.date),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.dayOfWeek,
                  style: AppTextStyles.dayLabel.copyWith(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.cardBackground,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.subtleBorder,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Color(0x2E111827),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.dayNumber}',
                    style: AppTextStyles.dayNumber.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
