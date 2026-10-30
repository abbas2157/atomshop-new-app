import 'package:flutter/material.dart';

import '../design/atom_text.dart';
import '../design/atom_tokens.dart';
import '../responsive/atom_responsive.dart';
import 'atom_button.dart';

/// Dialog used for every question the app asks: heading, message, then the
/// actions stacked full width with the main action on top. Stacking keeps
/// labels whole on the narrowest phones.
class AtomDialog extends StatelessWidget {
  const AtomDialog({super.key, required this.title, required this.content, required this.actions});

  final String title;
  final Widget content;

  /// Main action first, cancel last. Pass full-width (`expand: true`) buttons.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: context.atomGutter, vertical: AtomSpace.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AtomSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text(title, style: AtomText.heading)),
              const SizedBox(height: AtomSpace.xs),
              Flexible(child: SingleChildScrollView(child: DefaultTextStyle.merge(style: AtomText.body, child: content))),
              const SizedBox(height: AtomSpace.lg),
              for (final (i, action) in actions.indexed) ...[
                if (i > 0) const SizedBox(height: AtomSpace.xs),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Yes/no question in an [AtomDialog]. True only when the main action is
/// tapped; Cancel, Back and tapping outside all give false. [danger] makes
/// the main action red (sign out, delete, leave without saving).
Future<bool> showAtomConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required IconData confirmIcon,
  String cancelLabel = 'Cancel',
  IconData cancelIcon = Icons.close_rounded,
  bool danger = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AtomDialog(
      title: title,
      content: Text(message),
      actions: [
        AtomButton(
          label: confirmLabel,
          icon: confirmIcon,
          variant: danger ? AtomButtonVariant.danger : AtomButtonVariant.primary,
          size: AtomButtonSize.medium,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        AtomButton(
          label: cancelLabel,
          icon: cancelIcon,
          variant: AtomButtonVariant.secondary,
          size: AtomButtonSize.medium,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
  );
  return ok == true;
}
