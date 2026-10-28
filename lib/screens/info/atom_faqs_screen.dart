import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_account.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../state/atom_account_providers.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import 'atom_info_widgets.dart';

/// FAQs (canvas: "Frequently asked questions"). The questions come from the
/// server (`api/app/pages/faqs`), the same text as the website.
class AtomFaqsScreen extends ConsumerStatefulWidget {
  const AtomFaqsScreen({super.key});

  @override
  ConsumerState<AtomFaqsScreen> createState() => _AtomFaqsScreenState();
}

class _AtomFaqsScreenState extends ConsumerState<AtomFaqsScreen> {
  /// Null = All.
  String? _group;

  /// Index of the open question in the visible list; one open at a time.
  int? _open = 0;

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(pageContentProvider('faqs'));
    return AtomPage(
      title: 'Frequently asked questions',
      onRefresh: () async {
        ref.invalidate(pageContentProvider('faqs'));
        await ref.read(pageContentProvider('faqs').future).catchError((_) => const PageContent(title: '', updatedAt: null, intro: '', sections: [], faqGroups: [], url: ''));
      },
      children: [
        ...value.when(
          skipLoadingOnRefresh: true,
          data: _content,
          loading: () => [
            for (var i = 0; i < 5; i++) ...[const AtomSkeleton(height: 64, radius: AtomRadius.card), const SizedBox(height: AtomSpace.xs)],
          ],
          error: (_, _) => [InfoPageError(onRetry: () => ref.invalidate(pageContentProvider('faqs')), websiteUrl: ref.watch(appConfigProvider).value?.pages['faqs'] ?? 'https://atomshop.pk/faqs')],
        ),
        const SizedBox(height: AtomSpace.lg),
        AtomCard(
          onTap: () => AtomNav.toTab(context, ref, AtomTab.askAtom),
          color: AtomColors.ink,
          borderColor: null,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Still have a question?', style: AtomText.subheading.copyWith(color: AtomColors.white)),
                    Text('Ask Atom or chat with us on WhatsApp', style: AtomText.small.copyWith(color: AtomColors.onDark)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AtomColors.white),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _content(PageContent page) {
    final groups = page.faqGroups;
    final items = [
      for (final g in groups)
        if (_group == null || g.title == _group) ...g.items,
    ];
    return [
      if (groups.length > 1)
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final title in [null, ...groups.map((g) => g.title)])
                Padding(
                  padding: const EdgeInsets.only(right: AtomSpace.xs),
                  child: AtomChoiceChip(
                    label: title ?? 'All',
                    dark: true,
                    selected: _group == title,
                    onTap: () => setState(() {
                      _group = title;
                      _open = 0;
                    }),
                  ),
                ),
            ],
          ),
        ),
      const SizedBox(height: AtomSpace.sm),
      if (items.isEmpty) const AtomEmptyState(icon: Icons.help_outline_rounded, title: 'No questions here yet', message: 'Ask Atom or contact us and we will help.'),
      for (var i = 0; i < items.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: AtomSpace.xs),
          child: _FaqItem(
            question: items[i].$1,
            answer: items[i].$2,
            open: _open == i,
            onTap: () => setState(() => _open = _open == i ? null : i),
          ),
        ),
    ];
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer, required this.open, required this.onTap});

  final String question;
  final String answer;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      expanded: open,
      button: true,
      child: AtomCard(
        onTap: onTap,
        color: open ? AtomColors.primarySoft : AtomColors.white,
        borderColor: open ? AtomColors.primary : AtomColors.line,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(question, style: AtomText.label)),
                  const SizedBox(width: AtomSpace.xs),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: open ? AtomColors.primary : AtomColors.surface, shape: BoxShape.circle),
                    child: AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(Icons.expand_more_rounded, size: 18, color: open ? AtomColors.white : AtomColors.body),
                    ),
                  ),
                ],
              ),
              if (open) ...[
                const SizedBox(height: AtomSpace.xs),
                Text(answer, style: AtomText.body),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
