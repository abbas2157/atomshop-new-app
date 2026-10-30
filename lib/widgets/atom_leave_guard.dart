import 'package:flutter/material.dart';

import 'atom_dialog.dart';

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
        final leave = await showAtomConfirm(
          context,
          title: 'Leave this form?',
          message: 'What you typed will be lost.',
          confirmLabel: 'Leave',
          confirmIcon: Icons.logout_rounded,
          cancelLabel: 'Keep editing',
          cancelIcon: Icons.edit_outlined,
          danger: true,
        );
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: child,
    );
  }
}
