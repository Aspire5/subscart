import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/daily_schedule.dart';
import '../../../domain/entities/meal_item.dart';
import '../../../domain/entities/meal_order.dart';
import 'app_loading_overlay.dart';

class SelectedSwapSource {
  final MealItem item;
  final MealOrder order;
  final DateTime date;

  SelectedSwapSource({
    required this.item,
    required this.order,
    required this.date,
  });
}

class CompletedSwapPair {
  final SelectedSwapSource source;
  final DateTime targetDate;
  final MealOrder targetOrder;
  final MealItem targetItem;

  CompletedSwapPair({
    required this.source,
    required this.targetDate,
    required this.targetOrder,
    required this.targetItem,
  });
}

class SwapBottomSheet extends StatefulWidget {
  final List<SelectedSwapSource> sourceItems;
  final List<DailySchedule> availableDays;
  final void Function(List<CompletedSwapPair> pairs) onAllSwapsConfirmed;

  const SwapBottomSheet({
    super.key,
    required this.sourceItems,
    required this.availableDays,
    required this.onAllSwapsConfirmed,
  });

  @override
  State<SwapBottomSheet> createState() => _SwapBottomSheetState();
}

class _SwapBottomSheetState extends State<SwapBottomSheet> {
  int _currentStepIndex = 0;
  final Map<String, CompletedSwapPair> _pairedSwaps = {};
  bool _isReviewStep = false;
  late DateTime _selectedTargetDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedTargetDate = widget.availableDays.isNotEmpty
        ? widget.availableDays.first.date
        : DateTime.now();
  }

  SelectedSwapSource get _currentSourceItem =>
      widget.sourceItems[_currentStepIndex];

  DailySchedule? get _selectedSchedule {
    return widget.availableDays.cast<DailySchedule?>().firstWhere(
          (s) =>
              s != null && DateFormatter.isSameDay(s.date, _selectedTargetDate),
          orElse: () => widget.availableDays.isNotEmpty
              ? widget.availableDays.first
              : null,
        );
  }

  bool _isTargetItemAlreadyPaired(String itemId, DateTime date) {
    for (final pair in _pairedSwaps.values) {
      if (pair.source.item.id != _currentSourceItem.item.id &&
          pair.targetItem.id == itemId &&
          DateFormatter.isSameDay(pair.targetDate, date)) {
        return true;
      }
    }
    return false;
  }

  void _goToStep(int index) {
    setState(() {
      _currentStepIndex = index;
      _isReviewStep = false;
      final existing = _pairedSwaps[widget.sourceItems[index].item.id];
      if (existing != null) {
        _selectedTargetDate = existing.targetDate;
      }
    });
  }

  void _onMealSelected(
    DateTime targetDate,
    MealOrder targetOrder,
    MealItem targetItem,
  ) {
    final source = _currentSourceItem;
    _pairedSwaps[source.item.id] = CompletedSwapPair(
      source: source,
      targetDate: targetDate,
      targetOrder: targetOrder,
      targetItem: targetItem,
    );

    if (_currentStepIndex < widget.sourceItems.length - 1) {
      _goToStep(_currentStepIndex + 1);
    } else {
      setState(() {
        _isReviewStep = true;
      });
    }
  }

  void _editPair(int index) {
    _goToStep(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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

            // Main Content: either Review step or Guided Selection step
            if (_isReviewStep)
              _buildReviewView()
            else
              _buildGuidedSelectionView(),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidedSelectionView() {
    final totalSteps = widget.sourceItems.length;
    final source = _currentSourceItem;
    final schedule = _selectedSchedule;
    final allOrders = schedule?.orders ?? [];

    final targetMeals = <Map<String, dynamic>>[];
    for (final order in allOrders) {
      for (final item in order.items) {
        targetMeals.add({
          'order': order,
          'item': item,
        });
      }
    }

    final existingPair = _pairedSwaps[source.item.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Swap Meals',
                        style: AppTextStyles.sectionTitle,
                      ),
                      if (totalSteps > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x0F111827),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Step ${_currentStepIndex + 1} of $totalSteps',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Pick a target date & meal to swap with Item ${_currentStepIndex + 1}',
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
        const SizedBox(height: 12),

        // Step Progress Bar (if multiple items)
        if (totalSteps > 1) ...[
          Row(
            children: List.generate(totalSteps, (index) {
              final isDone = _pairedSwaps.containsKey(widget.sourceItems[index].item.id);
              final isCurrent = index == _currentStepIndex;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primaryDark
                        : (isDone ? AppColors.sageBadgeText : const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
        ],

        // Active Source Item Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x08111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1F111827), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.subtleBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: source.item.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.fastfood, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CURRENT MEAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Order ${source.order.orderNumber} • ${DateFormatter.formatShortDay(source.date)} ${source.date.day}',
                            style: AppTextStyles.helperText.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      source.item.name,
                      style: AppTextStyles.itemTitle.copyWith(
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Target Date Selector Carousel
        const Text(
          'Select Target Date',
          style: AppTextStyles.cardHeader,
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.availableDays.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                  width: 62,
                  padding: const EdgeInsets.symmetric(vertical: 6),
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
                      const SizedBox(height: 1),
                      Text(
                        '${day.dayNumber}',
                        style: TextStyle(
                          fontSize: 14.5,
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
        const SizedBox(height: 14),

        // Available Meals on Target Date
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Meals on ${DateFormatter.formatShortDay(_selectedTargetDate)} ${_selectedTargetDate.day}',
              style: AppTextStyles.cardHeader,
            ),
            Text(
              '${targetMeals.length} items',
              style: AppTextStyles.helperText,
            ),
          ],
        ),
        const SizedBox(height: 8),

        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.36,
          ),
          child: targetMeals.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: const Text(
                    'No meals scheduled on this date',
                    style: AppTextStyles.helperText,
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: targetMeals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = targetMeals[index];
                    final MealOrder order = entry['order'] as MealOrder;
                    final MealItem item = entry['item'] as MealItem;
                    final isAlreadyPairedWithOther =
                        _isTargetItemAlreadyPaired(item.id, _selectedTargetDate);
                    final isCurrentPaired = existingPair?.targetItem.id == item.id &&
                        DateFormatter.isSameDay(
                            existingPair!.targetDate, _selectedTargetDate);

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCurrentPaired
                            ? const Color(0x0A111827)
                            : AppColors.chipBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrentPaired
                              ? AppColors.primaryDark
                              : AppColors.chipBorder,
                          width: isCurrentPaired ? 1.5 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Thumbnail
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.subtleBorder),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.fastfood, size: 20),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: AppTextStyles.itemTitle.copyWith(
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Order ${order.orderNumber} • ${item.calories} kcal',
                                  style: AppTextStyles.helperText.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Selection Action
                          if (isAlreadyPairedWithOther)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Paired',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => _onMealSelected(
                                _selectedTargetDate,
                                order,
                                item,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCurrentPaired
                                    ? AppColors.sageBadgeText
                                    : AppColors.primaryDark,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                minimumSize: const Size(60, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                isCurrentPaired ? 'Selected' : 'Swap',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),

        // Bottom Navigation Row
        if (_currentStepIndex > 0 || existingPair != null || _pairedSwaps.isNotEmpty)
          Row(
            children: [
              if (_currentStepIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _goToStep(_currentStepIndex - 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.chipBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(0, 42),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text(
                      'Previous Item',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              if (_currentStepIndex > 0 && (_currentStepIndex < totalSteps - 1 && existingPair != null || _pairedSwaps.length == totalSteps))
                const SizedBox(width: 10),
              if (_currentStepIndex < totalSteps - 1 && existingPair != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _goToStep(_currentStepIndex + 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.chipBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(0, 42),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text(
                      'Next Item',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              if (_currentStepIndex < totalSteps - 1 && existingPair != null && _pairedSwaps.length == totalSteps)
                const SizedBox(width: 10),
              if (_pairedSwaps.length == totalSteps)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isReviewStep = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      minimumSize: const Size(0, 42),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text(
                      'Review Swaps',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildReviewView() {
    final pairs = widget.sourceItems
        .map((s) => _pairedSwaps[s.item.id])
        .whereType<CompletedSwapPair>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review & Confirm Swaps',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  'Review your ${pairs.length} planned meal swaps',
                  style: AppTextStyles.screenSubtitle,
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20),
              splashRadius: 18,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Pairs List
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.45,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: pairs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final pair = pairs[index];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.chipBorder),
                ),
                child: Column(
                  children: [
                    // Row 1: Source Item
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.subtleBorder),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: pair.source.item.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.fastfood, size: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pair.source.item.name,
                                style: AppTextStyles.itemTitle.copyWith(
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${DateFormatter.formatShortDay(pair.source.date)} ${pair.source.date.day} • Order ${pair.source.order.orderNumber}',
                                style: AppTextStyles.helperText,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _editPair(index),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.chipBorder),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 12, color: AppColors.textPrimary),
                                SizedBox(width: 3),
                                Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swap_vert, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                    // Row 2: Target Item
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.subtleBorder),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: pair.targetItem.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.fastfood, size: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pair.targetItem.name,
                                style: AppTextStyles.itemTitle.copyWith(
                                  fontSize: 13,
                                  color: AppColors.sageBadgeText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${DateFormatter.formatShortDay(pair.targetDate)} ${pair.targetDate.day} • Order ${pair.targetOrder.orderNumber}',
                                style: AppTextStyles.helperText,
                              ),
                            ],
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
        const SizedBox(height: 16),

        // Action Buttons: Back to Edit | Confirm All Swaps
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isReviewStep = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.chipBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text(
                  'Back',
                  style: AppTextStyles.actionButton,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() => _isSubmitting = true);
                        widget.onAllSwapsConfirmed(pairs);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: AppCustomSpinner(size: 20, color: Colors.white),
                      )
                    : Text(
                        pairs.length == 1
                            ? 'Confirm Swap'
                            : 'Confirm ${pairs.length} Swaps',
                        style: AppTextStyles.actionButton,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
