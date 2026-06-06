import 'package:flutter/material.dart';

import '../design/design.dart';

/// A single, consistent search input. Replaces the six bespoke search boxes
/// that each re-declared their own border states.
class SellerSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SellerSearchField({
    super.key,
    this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.onClear,
  });

  @override
  State<SellerSearchField> createState() => _SellerSearchFieldState();
}

class _SellerSearchFieldState extends State<SellerSearchField> {
  late final TextEditingController _controller;
  bool _owns = false;
  bool _focused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _owns = widget.controller == null;
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_sync);
  }

  void _sync() {
    final has = _controller.text.isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    _controller.removeListener(_sync);
    if (_owns) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return AnimatedContainer(
      duration: AppMotion.fast,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: _focused ? c.accent : c.border,
          width: _focused ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          const Gap.h(AppSpace.sm),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: _focused ? c.accent : c.textTertiary,
          ),
          const Gap.h(AppSpace.xs),
          Expanded(
            child: Focus(
              onFocusChange: (f) => setState(() => _focused = f),
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                style: text.body,
                cursorColor: c.accent,
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpace.md,
                  ),
                  border: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: text.body.copyWith(color: c.textTertiary),
                ),
              ),
            ),
          ),
          if (_hasText)
            IconButton(
              splashRadius: 18,
              icon: Icon(Icons.close_rounded, size: 18, color: c.textTertiary),
              onPressed: () {
                _controller.clear();
                widget.onChanged?.call('');
                widget.onClear?.call();
              },
            )
          else
            const Gap.h(AppSpace.sm),
        ],
      ),
    );
  }
}
