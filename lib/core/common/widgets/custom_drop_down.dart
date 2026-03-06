import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:flutter/material.dart';

class CustomSearchDropdown<T> extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final List<T> items;
  final String Function(T) itemAsString;
  final T? selectedItem;
  final void Function(T?)? onChanged;
  final Widget? prefixIcon;
  final bool enabled;
  final Color? surfaceColor;

  const CustomSearchDropdown({
    super.key,
    this.labelText,
    this.hintText,
    required this.items,
    required this.itemAsString,
    this.selectedItem,
    this.onChanged,
    this.prefixIcon,
    this.enabled = true,
    this.surfaceColor,
  });

  @override
  State<CustomSearchDropdown<T>> createState() =>
      _CustomSearchDropdownState<T>();
}

class _CustomSearchDropdownState<T> extends State<CustomSearchDropdown<T>> {
  bool _isFocused = false;

  void _showSearchBottomSheet() {
    if (!widget.enabled) return;

    setState(() => _isFocused = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _SearchSheet<T>(
          items: widget.items,
          itemAsString: widget.itemAsString,
          onItemSelected: (item) {
            widget.onChanged?.call(item);
            Navigator.pop(context);
          },
        );
      },
    ).then((_) => setState(() => _isFocused = false));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: _isFocused
                  ? ColorPalette.secondary
                  : ColorPalette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: _showSearchBottomSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color:
                  widget.surfaceColor ??
                  (widget.enabled
                      ? ColorPalette.surfaceGray
                      : ColorPalette.surfaceGray.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? ColorPalette.secondary
                    : ColorPalette.border,
                width: _isFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  widget.prefixIcon!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    widget.selectedItem != null
                        ? widget.itemAsString(widget.selectedItem!)
                        : (widget.hintText ?? "Select Option"),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: widget.selectedItem != null
                          ? ColorPalette.textPrimary
                          : ColorPalette.textLight,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: ColorPalette.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchSheet<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemAsString;
  final Function(T) onItemSelected;

  const _SearchSheet({
    required this.items,
    required this.itemAsString,
    required this.onItemSelected,
  });

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items
          .where(
            (item) => widget
                .itemAsString(item)
                .toLowerCase()
                .contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              // Reusing your TextField style logic for the search bar
              TextField(
                controller: _searchController,
                onChanged: _filterItems,
                decoration: InputDecoration(
                  hintText: "Search...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: ColorPalette.surfaceGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _filteredItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return ListTile(
                      title: Text(widget.itemAsString(item)),
                      onTap: () => widget.onItemSelected(item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
