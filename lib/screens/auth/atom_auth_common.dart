import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../state/atom_account_providers.dart';
import '../../state/atom_session.dart';
import '../../widgets/atom_button.dart';

export '../../utils/atom_validators.dart';

/// Shared pieces of the sign-in and sign-up screens. Form rules live in
/// lib/utils/atom_validators.dart.

/// After any successful sign-in: the shell and account data follow the new
/// session.
Future<void> afterSignIn(WidgetRef ref) async {
  await ref.read(atomSessionProvider.notifier).refresh();
  refreshAccount(ref);
}

/// Scaffold for the auth screens: back button and "Step x of 3" on top,
/// scrolling body, action pinned at the bottom.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.children, this.step, this.bottom, this.showBack = true});

  final List<Widget> children;

  /// "Step 1 of 3".
  final String? step;
  final Widget? bottom;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, 0),
                child: SizedBox(
                  height: AtomSize.iconButton,
                  child: Row(
                    children: [
                      if (showBack && Navigator.of(context).canPop())
                        AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
                      const Spacer(),
                      if (step != null) Text(step!, style: AtomText.small.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(gutter, AtomSpace.md, gutter, AtomSpace.xl),
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              top: false,
              child: AtomPageWidth(
                child: Padding(padding: EdgeInsets.fromLTRB(gutter, AtomSpace.xs, gutter, AtomSpace.sm), child: bottom),
              ),
            ),
    );
  }
}

/// Rounded tile with an icon above a screen title.
class AuthIconTile extends StatelessWidget {
  const AuthIconTile({super.key, required this.icon, this.amber = false});

  final IconData icon;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: amber ? AtomColors.amberSoft : AtomColors.primarySoft, borderRadius: BorderRadius.circular(18)),
        child: Icon(icon, size: 28, color: amber ? AtomColors.amberInk : AtomColors.primary),
      ),
    );
  }
}

class AuthTitle extends StatelessWidget {
  const AuthTitle({super.key, required this.title, this.subtitle});

  final String title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: AtomText.title)),
        if (subtitle != null) ...[const SizedBox(height: AtomSpace.xs), subtitle!],
      ],
    );
  }
}

/// Small grey line with tappable bold links ("Terms of use", "Sign in").
class AuthLinks extends StatelessWidget {
  const AuthLinks({super.key, required this.parts, this.center = true});

  /// (text, onTap) — onTap null for plain text.
  final List<(String, VoidCallback?)> parts;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: center ? WrapAlignment.center : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (text, onTap) in parts)
          onTap == null
              ? Text(text, style: AtomText.small)
              : InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 32),
                    child: Center(
                      widthFactor: 1,
                      child: Text(text, style: AtomText.small.copyWith(color: AtomColors.primary, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
      ],
    );
  }
}

/// Error line shown under a form when the server refuses.
class AuthError extends StatelessWidget {
  const AuthError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final m = message;
    if (m == null || m.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AtomSpace.sm),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, size: 18, color: AtomColors.rose),
            const SizedBox(width: 6),
            Expanded(child: Text(m, style: AtomText.small.copyWith(color: AtomColors.rose, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}
