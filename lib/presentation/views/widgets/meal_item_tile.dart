import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/meal_item.dart';

class MealItemTile extends StatelessWidget {
  final MealItem item;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final bool isSelectable;

  const MealItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onToggleSelect,
    this.isSelectable = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isSelectable ? onToggleSelect : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isSelectable && isSelected) ? const Color(0x0A111827) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isSelectable && isSelected) ? AppColors.primaryDark : Colors.transparent,
            width: (isSelectable && isSelected) ? 1.2 : 0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Selection Checkbox / Radio indicator (hidden if order is past cutoff)
            if (isSelectable) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primaryDark : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryDark
                        : const Color(0xFFD1D5DB),
                    width: isSelected ? 0 : 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
            ],

            // Meal Thumbnail
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.subtleBorder),
                color: const Color(0xFFF9FAFB),
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.fastfood,
                  size: 24,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Nutrition Macros
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.cardHeader.copyWith(
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.calories} Calories, fat ${item.fatGrams} gm,\nprotein ${item.proteinGrams} gm and carbohy...',
                    style: AppTextStyles.chipText.copyWith(
                      height: 1.35,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
