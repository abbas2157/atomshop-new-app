import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/atom_http.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_states.dart';

/// Opens [url] outside the app (browser, dialler, WhatsApp, maps). Shows a
/// short message when nothing can open it.
Future<void> atomOpenUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  final opened = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open this link on your phone.')));
  }
}

/// Eyebrow (small blue caps) above a heading.
class InfoEyebrow extends StatelessWidget {
  const InfoEyebrow(this.text, {super.key, this.color = AtomColors.primary});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: AtomText.eyebrow.copyWith(color: color));
}


/// Error for a server page that did not load: retry, or read it on the
/// website. Only a lost connection says "check your internet"; when the
/// server answers without the page (endpoint not live yet) it says so and
/// leads with the website.
class InfoPageError extends StatelessWidget {
  const InfoPageError({super.key, required this.onRetry, required this.websiteUrl, this.error});

  final VoidCallback onRetry;
  final String websiteUrl;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final e = error;
    final offline = e is! AtomApiException || e.isOffline;
    if (offline) {
      return Column(
        children: [
          AtomErrorState(onRetry: onRetry, error: error),
          AtomButton(
            label: 'Read on atomshop.pk',
            icon: Icons.open_in_new_rounded,
            variant: AtomButtonVariant.secondary,
            size: AtomButtonSize.medium,
            onPressed: () => atomOpenUrl(context, websiteUrl),
          ),
        ],
      );
    }
    return AtomEmptyState(
      icon: Icons.article_outlined,
      title: 'Read this on our website',
      message: 'This page is not in the app yet. The full, up-to-date version is on atomshop.pk.',
      actionLabel: 'Open on atomshop.pk',
      actionIcon: Icons.open_in_new_rounded,
      onAction: () => atomOpenUrl(context, websiteUrl),
    );
  }
}
