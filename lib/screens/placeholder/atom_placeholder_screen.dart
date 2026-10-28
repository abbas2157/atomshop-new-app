import 'package:flutter/material.dart';

import '../../widgets/atom_states.dart';

/// Stand-in for a v2 screen that is designed (see the canvas) but not built
/// yet, so the shell and navigation can be tried end to end.
class AtomPlaceholderScreen extends StatelessWidget {
  const AtomPlaceholderScreen({super.key, required this.title, required this.icon, this.guest = false});

  final String title;
  final IconData icon;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(guest ? '$title · guest' : title)),
      body: Center(
        child: AtomEmptyState(
          icon: icon,
          title: '$title is being built',
          message: 'This screen is designed and comes in the next step of app v2.',
        ),
      ),
    );
  }
}
