import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_account.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../state/atom_account_providers.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import 'atom_info_widgets.dart';

enum LegalTab { privacy, returns, terms }

extension on LegalTab {
  String get slug => switch (this) {
        LegalTab.privacy => 'privacy',
        LegalTab.returns => 'refund',
        LegalTab.terms => 'terms',
      };

  String get label => switch (this) {
        LegalTab.privacy => 'Privacy',
        LegalTab.returns => 'Returns',
        LegalTab.terms => 'Terms',
      };

  /// The same text on the website (fallback when the page does not load).
  String get websiteUrl => this == LegalTab.returns ? 'https://atomshop.pk/return-refund-policy' : 'https://atomshop.pk/privacy-policy';
}

/// Policies (canvas: "Policies"): privacy, returns and terms, loaded from the
/// server so the app and the website never differ. No text is typed here.
class AtomLegalScreen extends ConsumerStatefulWidget {
  const AtomLegalScreen({super.key, this.tab = LegalTab.privacy});

  final LegalTab tab;

  @override
  ConsumerState<AtomLegalScreen> createState() => _AtomLegalScreenState();
}

class _AtomLegalScreenState extends ConsumerState<AtomLegalScreen> {
  late LegalTab _tab = widget.tab;
  final _scroll = ScrollController();

  /// One key per section of the open document, for "On this page".
  List<GlobalKey> _keys = const [];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jump(int i) {
    final ctx = i < _keys.length ? _keys[i].currentContext : null;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.05);
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final value = ref.watch(pageContentProvider(_tab.slug));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: Column(
            children: [
              const AtomTopBar(title: 'Policies'),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(gutter, AtomSpace.xs, gutter, AtomSpace.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AtomSegmented<LegalTab>(
                        items: {for (final t in LegalTab.values) t: t.label},
                        value: _tab,
                        onChanged: (t) {
                          setState(() => _tab = t);
                          if (_scroll.hasClients) _scroll.jumpTo(0);
                        },
                      ),
                      const SizedBox(height: AtomSpace.lg),
                      ...value.when(
                        skipLoadingOnRefresh: true,
                        data: _document,
                        loading: () => const [
                          AtomSkeleton(width: 200, height: 22),
                          SizedBox(height: AtomSpace.sm),
                          AtomSkeleton(height: 120, radius: AtomRadius.card),
                          SizedBox(height: AtomSpace.md),
                          AtomSkeleton(height: 200, radius: AtomRadius.card),
                        ],
                        error: (_, _) => [InfoPageError(onRetry: () => ref.invalidate(pageContentProvider(_tab.slug)), websiteUrl: ref.watch(appConfigProvider).value?.pages[_tab.slug] ?? _tab.websiteUrl)],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AtomBottomBar(
        child: AtomButton(
          label: 'Questions? Contact us',
          icon: Icons.chat_bubble_outline_rounded,
          variant: AtomButtonVariant.secondary,
          expand: true,
          onPressed: () => AtomNav.contact(context),
        ),
      ),
    );
  }

  List<Widget> _document(PageContent page) {
    final sections = page.sections;
    if (_keys.length != sections.length) _keys = List.generate(sections.length, (_) => GlobalKey());
    return [
      Semantics(header: true, child: Text(page.title, style: AtomText.heading.copyWith(fontSize: 20))),
      if (page.updatedAt != null) ...[
        const SizedBox(height: 4),
        Text('Last updated ${AtomFormat.date(page.updatedAt)}', style: AtomText.small),
      ],
      if (page.intro.isNotEmpty) ...[
        const SizedBox(height: AtomSpace.sm),
        Text(page.intro, style: AtomText.body),
      ],
      if (sections.length > 1) ...[
        const SizedBox(height: AtomSpace.md),
        Container(
          padding: const EdgeInsets.all(AtomSpace.md),
          decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(AtomRadius.card)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('On this page', style: AtomText.label),
              const SizedBox(height: 4),
              for (var i = 0; i < sections.length; i++)
                Semantics(
                  link: true,
                  child: InkWell(
                    onTap: () => _jump(i),
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 36),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${i + 1}. ${sections[i].heading}', style: AtomText.body.copyWith(color: AtomColors.primary, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      for (var i = 0; i < sections.length; i++)
        Padding(
          key: _keys[i],
          padding: const EdgeInsets.only(top: AtomSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text('${i + 1}. ${sections[i].heading}', style: AtomText.subheading)),
              for (final p in sections[i].paragraphs) ...[
                const SizedBox(height: AtomSpace.xs),
                Text(p, style: AtomText.body),
              ],
              for (final b in sections[i].bullets)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 8, right: 10), child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: AtomColors.body, shape: BoxShape.circle))),
                      Expanded(child: Text(b, style: AtomText.body)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      if (sections.isEmpty) const AtomEmptyState(icon: Icons.description_outlined, title: 'Nothing to show yet', message: 'This policy is on atomshop.pk.'),
    ];
  }
}
