import 'package:flutter/material.dart';

import '../design/design.dart';

/// Numbered pagination bar: `< 1 2 3 … 8 9 >`.
/// Returns [SizedBox.shrink] when [lastPage] ≤ 1.
class SellerPaginationBar extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final ValueChanged<int> onPage;

  const SellerPaginationBar({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.onPage,
  });

  List<_PageItem> _buildItems() {
    if (lastPage <= 7) {
      return [for (int i = 1; i <= lastPage; i++) _PageItem.page(i)];
    }

    final items = <_PageItem>[];
    const ellipsis = _PageItem.ellipsis();

    if (currentPage <= 4) {
      // 1 2 3 4 5 … last
      for (int i = 1; i <= 5; i++) { items.add(_PageItem.page(i)); }
      items.add(ellipsis);
      items.add(_PageItem.page(lastPage));
    } else if (currentPage >= lastPage - 3) {
      // 1 … last-4 last-3 last-2 last-1 last
      items.add(_PageItem.page(1));
      items.add(ellipsis);
      for (int i = lastPage - 4; i <= lastPage; i++) { items.add(_PageItem.page(i)); }
    } else {
      // 1 … cur-1 cur cur+1 … last
      items.add(_PageItem.page(1));
      items.add(ellipsis);
      for (int i = currentPage - 1; i <= currentPage + 1; i++) { items.add(_PageItem.page(i)); }
      items.add(ellipsis);
      items.add(_PageItem.page(lastPage));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (lastPage <= 1) return const SizedBox.shrink();

    final c = context.sellerColors;
    final text = context.sellerText;
    final items = _buildItems();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavBtn(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 1,
          onTap: () => onPage(currentPage - 1),
          c: c,
        ),
        const Gap.h(AppSpace.xs),
        ...items.map((item) {
          if (item.isEllipsis) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text('…', style: text.caption.copyWith(color: c.textTertiary)),
            );
          }
          final selected = item.page == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: selected ? null : () => onPage(item.page!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? c.accent : Colors.transparent,
                  borderRadius: AppRadius.brSm,
                  border: selected ? null : Border.all(color: c.border),
                ),
                child: Center(
                  child: Text(
                    '${item.page}',
                    style: text.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? c.onAccent : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const Gap.h(AppSpace.xs),
        _NavBtn(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < lastPage,
          onTap: () => onPage(currentPage + 1),
          c: c,
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final SellerColors c;

  const _NavBtn({required this.icon, required this.enabled, required this.onTap, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: AppRadius.brSm,
          border: Border.all(color: enabled ? c.border : c.divider),
        ),
        child: Icon(icon, size: 18, color: enabled ? c.textSecondary : c.textTertiary),
      ),
    );
  }
}

class _PageItem {
  final int? page;
  final bool isEllipsis;

  const _PageItem.page(int p) : page = p, isEllipsis = false;
  const _PageItem.ellipsis() : page = null, isEllipsis = true;
}
