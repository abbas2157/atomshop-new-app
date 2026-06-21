import 'package:flutter/material.dart';

import '../design/design.dart';

/// An animated segmented control for switching scopes (e.g. "My / All").
/// Equal-width segments inside a muted track with a sliding selection pill.
class SellerSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Optional count badge per tab. Must be same length as [labels] when provided.
  final List<int?>? counts;

  const SellerSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: AppRadius.brMd,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segW = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedAlign(
                duration: AppMotion.base,
                curve: AppMotion.standard,
                alignment: Alignment(
                  labels.length == 1
                      ? 0
                      : (selectedIndex / (labels.length - 1)) * 2 - 1,
                  0,
                ),
                child: Container(
                  width: segW,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    boxShadow: c.cardShadow,
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (i) {
                  final selected = i == selectedIndex;
                  final count = counts != null && i < counts!.length
                      ? counts![i]
                      : null;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: AppMotion.fast,
                              style: text.labelSm.copyWith(
                                color: selected ? c.accent : c.textSecondary,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                              child: Text(
                                labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (count != null && count > 0) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? c.accent
                                      : c.borderStrong,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  count.toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? c.onAccent
                                        : c.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A single horizontally-scrollable row of filter chips, with optional counts.
class SellerFilterChips extends StatelessWidget {
  final List<SellerChipData> chips;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  const SellerFilterChips({
    super.key,
    required this.chips,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = AppInsets.pageH,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const Gap.h(AppSpace.xs),
        itemBuilder: (context, i) {
          final chip = chips[i];
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? c.accent : c.surface,
                borderRadius: AppRadius.brPill,
                border: Border.all(
                  color: selected ? c.accent : c.border,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chip.label,
                    style: text.labelSm.copyWith(
                      color: selected ? c.onAccent : c.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (chip.count != null) ...[
                    const Gap.h(AppSpace.xs - 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.22)
                            : c.surfaceMuted,
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Text(
                        '${chip.count}',
                        style: text.caption.copyWith(
                          color: selected ? c.onAccent : c.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SellerChipData {
  final String label;
  final int? count;
  const SellerChipData(this.label, {this.count});
}
