import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class BulkActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onSkip;
  final VoidCallback onSwap;
  final VoidCallback onMove;
  final VoidCallback onClear;
  final bool isEnabled;

  const BulkActionBar({
    super.key,
    required this.selectedCount,
    required this.onSkip,
    required this.onSwap,
    required this.onMove,
    required this.onClear,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isVisible = selectedCount > 0;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      offset: isVisible ? Offset.zero : const Offset(0, 1.5),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        opacity: isVisible ? 1.0 : 0.0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3D111827),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Selection Info with Clear Button
                InkWell(
                  onTap: isEnabled ? onClear : null,
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0x2EFFFFFF),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$selectedCount',
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'selected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.close,
                          size: 13,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Flexible Actions: Skip | Swap | Move
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.skip_next_rounded,
                          label: 'Skip',
                          onTap: onSkip,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Swap',
                          onTap: onSwap,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.swap_vert_rounded,
                          label: 'Move',
                          onTap: onMove,
                          isPrimary: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPrimary ? Colors.transparent : const Color(0x28FFFFFF),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isPrimary ? AppColors.primaryDark : Colors.white,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.itemActionButton.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? AppColors.primaryDark : Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
