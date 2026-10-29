import 'package:flutter/material.dart';

import '../design/atom_text.dart';
import '../design/atom_tokens.dart';
import 'atom_text_field.dart';

/// Every pick-one list in the app opens this: a bottom sheet with a search
/// box over the options (owner rule: every select has a search field).
/// Returns the picked option, or null when dismissed.
Future<T?> showAtomSearchSelect<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T) label,
  bool Function(T)? isSelected,
  String searchHint = 'Search',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => _SearchSelectSheet<T>(title: title, options: options, label: label, isSelected: isSelected, searchHint: searchHint),
  );
}

class _SearchSelectSheet<T> extends StatefulWidget {
  const _SearchSelectSheet({required this.title, required this.options, required this.label, required this.isSelected, required this.searchHint});

  final String title;
  final List<T> options;
  final String Function(T) label;
  final bool Function(T)? isSelected;
  final String searchHint;

  @override
  State<_SearchSelectSheet<T>> createState() => _SearchSelectSheetState<T>();
}

class _SearchSelectSheetState<T> extends State<_SearchSelectSheet<T>> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty ? widget.options : widget.options.where((o) => widget.label(o).toLowerCase().contains(q)).toList(growable: false);
    // Short lists get a short sheet; long ones most of the screen.
    final maxHeight = MediaQuery.sizeOf(context).height * (widget.options.length > 8 ? 0.8 : 0.55);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AtomSpace.gutter),
              child: Semantics(header: true, child: Text(widget.title, style: AtomText.heading)),
            ),
            const SizedBox(height: AtomSpace.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AtomSpace.gutter),
              // Focus the box straight away only for long lists, so a short
              // list isn't hidden behind the keyboard.
              child: AtomSearchField(
                controller: _search,
                hint: widget.searchHint,
                autofocus: widget.options.length > 8,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: AtomSpace.xs),
            Flexible(
              child: shown.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AtomSpace.lg),
                      child: Text('Nothing matches "${_query.trim()}"', textAlign: TextAlign.center, style: AtomText.body),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: AtomSpace.md),
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final o = shown[i];
                        final on = widget.isSelected?.call(o) ?? false;
                        return ListTile(
                          minTileHeight: 48,
                          contentPadding: const EdgeInsets.symmetric(horizontal: AtomSpace.gutter),
                          selected: on,
                          title: Text(
                            widget.label(o),
                            style: AtomText.body.copyWith(color: on ? AtomColors.primary : AtomColors.ink, fontWeight: on ? FontWeight.w800 : FontWeight.w500),
                          ),
                          trailing: on ? const Icon(Icons.check_rounded, color: AtomColors.primary) : null,
                          onTap: () => Navigator.of(context).pop(o),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Form field that looks like an input and opens [showAtomSearchSelect].
/// Shows "Loading…" / "Could not load" (with retry) while its options load.
class AtomSelectField<T> extends StatelessWidget {
  const AtomSelectField({
    super.key,
    required this.title,
    required this.options,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.hint = 'Select',
    this.searchHint = 'Search',
    this.missing,
    this.enabled = true,
    this.loading = false,
    this.failed = false,
    this.onRetry,
  });

  /// Sheet title ("Choose your city").
  final String title;
  final List<T> options;
  final String Function(T) label;
  final T? selected;
  final ValueChanged<T> onChanged;
  final String hint;
  final String searchHint;

  /// Error when nothing is chosen; null makes the field optional.
  final String? missing;
  final bool enabled;
  final bool loading;
  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final current = selected;
    return FormField<T>(
      key: ValueKey('select-$title-${options.length}-${current == null ? '' : label(current)}'),
      initialValue: current,
      validator: (_) => (current == null && missing != null) ? missing : null,
      builder: (state) => Semantics(
        button: true,
        label: current == null ? title : '$title: ${label(current)}',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(AtomRadius.input),
          onTap: !enabled || options.isEmpty
              ? null
              : () async {
                  final picked = await showAtomSearchSelect<T>(
                    context,
                    title: title,
                    options: options,
                    label: label,
                    isSelected: current == null ? null : (o) => label(o) == label(current),
                    searchHint: searchHint,
                  );
                  if (picked != null) {
                    state.didChange(picked);
                    onChanged(picked);
                  }
                },
          child: InputDecorator(
            isEmpty: current == null,
            decoration: InputDecoration(
              hintText: loading ? 'Loading…' : (failed ? 'Could not load' : hint),
              errorText: state.errorText,
              enabled: enabled,
              suffixIcon: failed && onRetry != null
                  ? IconButton(tooltip: 'Try again', icon: const Icon(Icons.refresh_rounded), onPressed: onRetry)
                  : const Icon(Icons.arrow_drop_down_rounded),
            ),
            child: current == null
                ? null
                : Text(label(current), maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.body.copyWith(fontSize: 15, color: AtomColors.ink)),
          ),
        ),
      ),
    );
  }
}
