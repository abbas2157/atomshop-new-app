import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
/// website (the page endpoint may not be live yet).
class InfoPageError extends StatelessWidget {
  const InfoPageError({super.key, required this.onRetry, required this.websiteUrl});

  final VoidCallback onRetry;
  final String websiteUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AtomErrorState(onRetry: onRetry),
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
}
