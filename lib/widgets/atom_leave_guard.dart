import 'package:flutter/material.dart';

import '../design/atom_text.dart';
import 'atom_button.dart';

/// Asks before leaving a form with unsaved changes (back button, gesture or
/// the screen's own back arrow). [dirty] turns true on the first edit and
/// false once the form is sent.
class AtomLeaveGuard extends StatelessWidget {
  const AtomLeaveGuard({super.key, required this.dirty, required this.child});

  final bool dirty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Leave this form?', style: AtomText.heading),
            content: Text('What you typed will be lost.', style: AtomText.body),
            actions: [
              AtomButton(
                label: 'Keep editing',
                icon: Icons.edit_outlined,
                variant: AtomButtonVariant.text,
                size: AtomButtonSize.small,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              AtomButton(
                label: 'Leave',
                icon: Icons.logout_rounded,
                variant: AtomButtonVariant.secondary,
                size: AtomButtonSize.small,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.of(context).pop();
      },
      child: child,
    );
  }
}
