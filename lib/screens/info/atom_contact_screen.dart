import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_account.dart';
import '../../data/atom_http.dart';
import '../../data/atom_models.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../state/atom_order_providers.dart';
import '../../utils/atom_validators.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';
import 'atom_info_widgets.dart';

/// Contact us (canvas: "Contact us"). Every number, address and link comes
/// from `api/app/config`; nothing is typed into the app.
class AtomContactScreen extends ConsumerStatefulWidget {
  const AtomContactScreen({super.key});

  @override
  ConsumerState<AtomContactScreen> createState() => _AtomContactScreenState();
}

class _AtomContactScreenState extends ConsumerState<AtomContactScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    ref.read(orderPrefillProvider.future).then((p) {
      if (!mounted) return;
      if (_name.text.isEmpty) _name.text = p.name;
      if (_phone.text.isEmpty) _phone.text = p.phone;
    }).ignore();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      await ref.read(atomAccountApiProvider).contact(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            subject: _subject.text.trim(),
            message: _message.text.trim(),
          );
      if (!mounted) return;
      _subject.clear();
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent. We will get back to you soon.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(atomMessage(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static String? _required(String? v, String message) => (v ?? '').trim().isEmpty ? message : null;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    return AtomPage(
      title: 'Contact us',
      children: [
        config.when(
          skipLoadingOnRefresh: true,
          data: (c) => _Channels(config: c),
          loading: () => const Column(children: [AtomSkeleton(height: 76, radius: AtomRadius.card), SizedBox(height: AtomSpace.sm), AtomSkeleton(height: 90, radius: AtomRadius.card)]),
          error: (_, _) => AtomErrorState(onRetry: () => ref.invalidate(appConfigProvider)),
        ),
        const AtomGroupLabel('Send a message'),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AtomTextField(
                      label: 'Name',
                      controller: _name,
                      hint: 'Your name',
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      validator: validatePersonName,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AtomTextField(
                      label: 'Phone',
                      controller: _phone,
                      hint: '0300…',
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')), LengthLimitingTextInputFormatter(20)],
                      validator: (v) {
                        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                        if (digits.isEmpty) return 'Enter your phone.';
                        return digits.length < 10 || digits.length > 13 ? 'Enter a valid phone.' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AtomTextField(label: 'Subject', controller: _subject, hint: 'What is it about?', validator: (v) => _required(v, 'Enter a subject.')),
              const SizedBox(height: 14),
              AtomTextField(
                label: 'Message',
                controller: _message,
                hint: 'Enter your message',
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                validator: (v) => _required(v, 'Enter your message.'),
              ),
              const SizedBox(height: AtomSpace.md),
              AtomButton(label: 'Send message', icon: Icons.send_rounded, expand: true, loading: _sending, onPressed: _sending ? null : _send),
            ],
          ),
        ),
        if (config.value case final c? when c.social.isNotEmpty) ...[
          const SizedBox(height: AtomSpace.lg),
          Wrap(
            spacing: AtomSpace.xs,
            runSpacing: AtomSpace.xs,
            children: [
              for (final (key, label, icon) in const [
                ('facebook', 'Facebook', Icons.facebook_rounded),
                ('instagram', 'Instagram', Icons.camera_alt_outlined),
                ('tiktok', 'TikTok', Icons.music_note_rounded),
              ])
                if ((c.social[key] ?? '').isNotEmpty)
                  AtomButton(
                    label: label,
                    icon: icon,
                    variant: AtomButtonVariant.secondary,
                    size: AtomButtonSize.small,
                    onPressed: () => atomOpenUrl(context, c.social[key]!),
                  ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Channels extends StatelessWidget {
  const _Channels({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final c = config;
    Widget tile(IconData icon, String title, String value, VoidCallback onTap) => Expanded(
          child: AtomCard(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AtomColors.primary, size: 22),
                const SizedBox(height: AtomSpace.xs),
                Text(title, style: AtomText.label),
                Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: AtomText.small.copyWith(color: AtomColors.body)),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.whatsappUrl.isNotEmpty)
          Semantics(
            button: true,
            child: AtomCard(
              onTap: () => atomOpenUrl(context, c.whatsappUrl),
              color: AtomColors.green,
              borderColor: null,
              child: Row(
                children: [
                  const Icon(Icons.chat_rounded, color: AtomColors.white, size: 26),
                  const SizedBox(width: AtomSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chat on WhatsApp', style: AtomText.subheading.copyWith(color: AtomColors.white)),
                        Text('${c.whatsapp} · fastest for orders and plans', style: AtomText.small.copyWith(color: AtomColors.white)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AtomColors.white),
                ],
              ),
            ),
          ),
        const SizedBox(height: AtomSpace.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (c.phone.isNotEmpty) tile(Icons.call_outlined, 'Call us', c.phone, () => atomOpenUrl(context, 'tel:${c.phone.replaceAll(' ', '')}')),
              if (c.phone.isNotEmpty && c.email.isNotEmpty) const SizedBox(width: AtomSpace.sm),
              if (c.email.isNotEmpty) tile(Icons.mail_outline_rounded, 'Email', c.email, () => atomOpenUrl(context, 'mailto:${c.email}')),
            ],
          ),
        ),
        if (c.officeAddress.isNotEmpty) ...[
          const SizedBox(height: AtomSpace.sm),
          Container(
            padding: const EdgeInsets.all(AtomSpace.md),
            decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(AtomRadius.card)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, color: AtomColors.primary),
                const SizedBox(width: AtomSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.deliveryArea.isEmpty ? 'Our office' : 'Our ${c.deliveryArea} office', style: AtomText.label),
                      Text(c.officeAddress, style: AtomText.body.copyWith(fontSize: 13)),
                      if (c.deliveryArea.isNotEmpty)
                        Text('Delivery is currently available across ${c.deliveryArea} only. Call before you visit.', style: AtomText.small),
                      const SizedBox(height: AtomSpace.xs),
                      AtomButton(
                        label: 'Directions',
                        icon: Icons.near_me_outlined,
                        variant: AtomButtonVariant.secondary,
                        size: AtomButtonSize.small,
                        onPressed: () => atomOpenUrl(context, 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(c.officeAddress)}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
