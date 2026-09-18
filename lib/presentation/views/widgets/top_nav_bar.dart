import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String vendorName;
  final String planSummary;
  final String vendorLogoUrl;
  final VoidCallback? onBackTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onResetTap;

  const TopNavBar({
    super.key,
    required this.vendorName,
    required this.planSummary,
    required this.vendorLogoUrl,
    this.onBackTap,
    this.onMoreTap,
    this.onResetTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: Color(0x1F000000),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              // Back Button
              IconButton(
                onPressed: onBackTap ?? () {},
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                splashRadius: 20,
              ),
              const SizedBox(width: 8),

              // Vendor Thumbnail
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.subtleBorder, width: 1),
                  color: const Color(0xFFF3F4F6),
                ),
                clipBehavior: Clip.antiAlias,
                child: vendorLogoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: vendorLogoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.restaurant,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      )
                    : const Icon(
                        Icons.restaurant,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
              ),
              const SizedBox(width: 10),

              // Title and Subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorName,
                      style: AppTextStyles.screenTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      planSummary,
                      style: AppTextStyles.screenSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // More Options Button / Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'reset') {
                    onResetTap?.call();
                  }
                },
                icon: const Icon(
                  Icons.more_horiz,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                splashRadius: 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
                color: AppColors.cardBackground,
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(
                          Icons.restart_alt_rounded,
                          size: 18,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Reset Database',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
