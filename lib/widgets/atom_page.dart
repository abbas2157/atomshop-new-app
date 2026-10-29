import 'package:flutter/material.dart';

import '../design/atom_text.dart';
import '../design/atom_tokens.dart';
import '../responsive/atom_responsive.dart';
import 'atom_button.dart';

/// Top of a pushed screen: round back button, title and an optional line
/// under it, optional trailing action. Sits inside the page's scroll view.
class AtomTopBar extends StatelessWidget {
  const AtomTopBar({super.key, required this.title, this.subtitle, this.trailing, this.showBack = true, this.border = false});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBack;

  /// Hairline under the bar, for screens whose body scrolls under it.
  final bool border;

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    return Container(
      padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, AtomSpace.sm),
      decoration: border ? const BoxDecoration(border: Border(bottom: BorderSide(color: AtomColors.line))) : null,
      child: Row(
        children: [
          if (showBack && Navigator.of(context).canPop()) ...[
            AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
            const SizedBox(width: AtomSpace.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: AtomText.heading.copyWith(fontSize: 20))),
                if (subtitle != null && subtitle!.isNotEmpty) Text(subtitle!, style: AtomText.small.copyWith(fontSize: 13)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A standard pushed screen: [AtomTopBar] above a scrolling, width-capped
/// body, with an optional bottom action bar.
class AtomPage extends StatelessWidget {
  const AtomPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
    this.bottom,
    this.padding,
    this.onRefresh,
    this.hero,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  /// Bottom bar content (usually one full-width [AtomButton]).
  final Widget? bottom;
  final EdgeInsetsGeometry? padding;
  final Future<void> Function()? onRefresh;

  /// Full-width photo header (e.g. [AtomPhotoHero]) that replaces the top
  /// bar and scrolls with the page; it carries its own back button.
  final Widget? hero;

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    if (hero != null) {
      return Scaffold(
        body: AtomStatusBarBacking(
          child: AtomPageWidth(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                hero!,
                Padding(
                  padding: padding ?? EdgeInsets.fromLTRB(gutter, AtomSpace.lg, gutter, AtomSpace.xl),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: bottom == null ? null : AtomBottomBar(child: bottom!),
      );
    }
    Widget list = ListView(
      padding: padding ?? EdgeInsets.fromLTRB(gutter, AtomSpace.xs, gutter, AtomSpace.xl),
      children: children,
    );
    if (onRefresh != null) list = RefreshIndicator(color: AtomColors.primary, onRefresh: onRefresh!, child: list);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: Column(
            children: [
              AtomTopBar(title: title, subtitle: subtitle, trailing: trailing),
              Expanded(child: list),
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottom == null ? null : AtomBottomBar(child: bottom!),
    );
  }
}

/// White bar with a top hairline for a screen's main action.
class AtomBottomBar extends StatelessWidget {
  const AtomBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AtomColors.white, border: Border(top: BorderSide(color: AtomColors.line))),
      child: SafeArea(
        top: false,
        child: AtomPageWidth(
          child: Padding(padding: EdgeInsets.fromLTRB(context.atomGutter, AtomSpace.sm, context.atomGutter, AtomSpace.sm), child: child),
        ),
      ),
    );
  }
}

enum AtomNoticeTone { blue, amber, green, rose }

/// Soft box with an icon and a sentence (safety notes, next steps).
class AtomNotice extends StatelessWidget {
  const AtomNotice({super.key, required this.text, this.icon = Icons.info_outline_rounded, this.tone = AtomNoticeTone.blue, this.title});

  final String text;
  final String? title;
  final IconData icon;
  final AtomNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      AtomNoticeTone.blue => (AtomColors.primarySoft, AtomColors.primaryDark),
      AtomNoticeTone.amber => (AtomColors.amberSoft, AtomColors.amberInk),
      AtomNoticeTone.green => (AtomColors.greenSoft, AtomColors.green),
      AtomNoticeTone.rose => (AtomColors.roseSoft, AtomColors.rose),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: AtomSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) Text(title!, style: AtomText.label.copyWith(color: fg)),
                Text(text, style: AtomText.body.copyWith(fontSize: 13, color: fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Label ........ value" line used in summaries and receipts.
class AtomInfoRow extends StatelessWidget {
  const AtomInfoRow(this.label, this.value, {super.key, this.strong = false, this.valueColor});

  final String label;
  final String value;
  final bool strong;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AtomText.body),
          const SizedBox(width: AtomSpace.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AtomText.label.copyWith(fontWeight: strong ? FontWeight.w800 : FontWeight.w700, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small grey heading above a group of rows ("Your orders", "Help").
class AtomGroupLabel extends StatelessWidget {
  const AtomGroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AtomSpace.lg, bottom: AtomSpace.xs),
      child: Text(text, style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}

/// For pages drawn edge to edge under the status bar (a photo at the top):
/// once the page scrolls, a white band fills the status-bar strip so text
/// never slides under the clock and battery icons.
class AtomStatusBarBacking extends StatefulWidget {
  const AtomStatusBarBacking({super.key, required this.child});

  /// A scrollable (or a widget holding one).
  final Widget child;

  @override
  State<AtomStatusBarBacking> createState() => _AtomStatusBarBackingState();
}

class _AtomStatusBarBackingState extends State<AtomStatusBarBacking> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final scrolled = n.metrics.pixels > 8;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: top,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _scrolled ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: const DecoratedBox(
                decoration: BoxDecoration(color: AtomColors.white, border: Border(bottom: BorderSide(color: AtomColors.line))),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
