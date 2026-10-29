import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/atom_account.dart';
import '../../data/atom_http.dart';
import '../../data/atom_models.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_account_providers.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_surfaces.dart';

class _Message {
  const _Message.user(this.text) : fromUser = true, reply = null, failed = false;

  const _Message.bot(this.text, {this.reply, this.failed = false}) : fromUser = false;

  final bool fromUser;
  final String text;
  final AskAtomReply? reply;

  /// A limit or network message shown as Atom's answer.
  final bool failed;
}

/// Ask Atom tab (canvas: "Ask Atom"): questions about products, prices and
/// plans, answered by the server (its rules, knowledge base and AI, with
/// the same limits as the website). The chat lives while the tab is open.
class AtomAskAtomScreen extends ConsumerStatefulWidget {
  const AtomAskAtomScreen({super.key});

  @override
  ConsumerState<AtomAskAtomScreen> createState() => _AtomAskAtomScreenState();
}

class _AtomAskAtomScreenState extends ConsumerState<AtomAskAtomScreen> {
  static const _greeting = "Assalam-o-Alaikum! I'm Atom. Tell me what you want to buy and how many months suit you, and I'll show the monthly amount.";
  static const _historyLimit = 12;

  final _input = TextEditingController();
  final List<_Message> _messages = [const _Message.bot(_greeting)];
  bool _waiting = false;

  // Voice questions, as on the website: English (Pakistan), words fill the
  // box as they are heard and the question is sent when speech ends.
  final _speech = SpeechToText();
  bool _speechReady = false;
  bool _listening = false;

  /// Speech recognition is missing on this phone (not a permission
  /// question): the mic is hidden, like the website does.
  bool _voiceUnavailable = false;

  @override
  void dispose() {
    _speech.cancel();
    _input.dispose();
    super.dispose();
  }

  void _say(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    if (_waiting) return;
    if (!_speechReady) {
      _speechReady = await _speech.initialize(onError: _onSpeechError, onStatus: _onSpeechStatus).catchError((_) => false);
      if (!_speechReady) {
        final allowed = await _speech.hasPermission.catchError((_) => false);
        if (!mounted) return;
        if (allowed) {
          setState(() => _voiceUnavailable = true);
          _say('Voice questions are not available on this phone. Please type your question instead.');
        } else {
          _say('Atomshop needs the microphone for voice questions. Turn it on in your phone settings, or type your question instead.');
        }
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _listening = true;
      _input.clear();
    });
    await _speech.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        localeId: 'en_PK',
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  void _onSpeechResult(SpeechRecognitionResult r) {
    if (!mounted || !_listening) return;
    final words = r.recognizedWords;
    _input.value = TextEditingValue(text: words, selection: TextSelection.collapsed(offset: words.length));
    if (r.finalResult) {
      setState(() => _listening = false);
      if (words.trim().isNotEmpty) _ask(words);
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if ((status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) && _listening) {
      setState(() => _listening = false);
    }
  }

  void _onSpeechError(SpeechRecognitionError e) {
    if (!mounted) return;
    setState(() => _listening = false);
    final msg = e.errorMsg;
    if (msg == 'error_no_match' || msg == 'error_speech_timeout') {
      _say('We did not catch that. Tap the microphone and try again, or type your question.');
    } else if (msg.contains('permission')) {
      _say('Atomshop needs the microphone for voice questions. Turn it on in your phone settings, or type your question instead.');
    } else {
      _say('Voice input stopped. Please try again, or type your question.');
    }
  }

  Future<void> _ask(String question, {int? suggestionId}) async {
    final q = question.trim();
    if (q.isEmpty || _waiting) return;

    // History is what came before this question, newest last, failures left out.
    final history = [for (final m in _messages.where((m) => !m.failed)) (m.fromUser, m.text)];
    final recent = history.length > _historyLimit ? history.sublist(history.length - _historyLimit) : history;

    if (_listening) {
      _listening = false;
      _speech.stop();
    }
    setState(() {
      _messages.add(_Message.user(q));
      _waiting = true;
      _input.clear();
    });

    _Message answer;
    try {
      final reply = await ref.read(atomAccountApiProvider).askAtom(question: q, history: recent, suggestionId: suggestionId);
      answer = _Message.bot(reply.answer, reply: reply);
    } catch (e) {
      answer = _Message.bot(atomMessage(e), failed: true);
    }
    if (!mounted) return;
    setState(() {
      _messages.add(answer);
      _waiting = false;
    });
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open that link.')));
    }
  }

  void _action(AskAtomAction a) {
    final id = a.id;
    switch (a.type) {
      case 'product' when id != null:
        AtomNav.product(context, id);
      case 'category' when id != null:
        AtomNav.category(context, CatalogueItem(id: id, title: a.label, slug: '', picture: ''));
      case 'brand' when id != null:
        AtomNav.brand(context, CatalogueItem(id: id, title: a.label, slug: '', picture: ''));
      case 'custom_order':
        AtomNav.customOrder(context);
      case 'offer':
        AtomNav.makeOffer(context);
      case 'shop':
        AtomNav.toTab(context, ref, AtomTab.shop);
      case 'faqs':
        AtomNav.faqs(context);
      case 'search':
        AtomNav.search(context, query: a.searchText);
      case 'whatsapp':
        final url = a.url.isNotEmpty ? a.url : (ref.read(appConfigProvider).value?.whatsappUrl ?? '');
        if (url.isNotEmpty) _open(url);
      default:
        if (a.url.isNotEmpty) _open(a.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final whatsApp = ref.watch(appConfigProvider).value?.whatsappUrl ?? '';
    final suggestions = ref.watch(askAtomSuggestionsProvider).value ?? const <AskAtomSuggestion>[];
    // Newest at the bottom: the list is reversed, item 0 is the latest.
    final items = _messages.reversed.toList(growable: false);

    // Light status-bar icons over the dark header.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AtomColors.surface,
        body: Column(
          children: [
            const _Header(),
            Expanded(
              child: AtomPageWidth(
                child: ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.fromLTRB(gutter, AtomSpace.md, gutter, AtomSpace.md),
                  itemCount: items.length + (_waiting ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_waiting && i == 0) return const _Typing();
                    final m = items[_waiting ? i - 1 : i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AtomSpace.sm),
                      child: m.fromUser ? _UserBubble(text: m.text) : _BotBubble(message: m, onAction: _action, onAsk: (q) => _ask(q)),
                    );
                  },
                ),
              ),
            ),
            AtomPageWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (whatsApp.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                      child: Row(
                        children: [
                          Text('Prefer a person?', style: AtomText.small),
                          AtomButton(
                            label: 'Ask on WhatsApp',
                            icon: Icons.chat_outlined,
                            variant: AtomButtonVariant.text,
                            size: AtomButtonSize.small,
                            onPressed: () => _open(whatsApp),
                          ),
                        ],
                      ),
                    ),
                  if (suggestions.isNotEmpty)
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 6),
                        itemCount: suggestions.length,
                        separatorBuilder: (_, _) => const SizedBox(width: AtomSpace.xs),
                        itemBuilder: (_, i) {
                          final s = suggestions[i];
                          return AtomChoiceChip(
                            label: s.label,
                            selected: false,
                            onTap: () => _ask(s.prompt, suggestionId: s.id),
                          );
                        },
                      ),
                    ),
                  _Composer(
                    controller: _input,
                    waiting: _waiting,
                    onSend: () => _ask(_input.text),
                    listening: _listening,
                    onVoice: _voiceUnavailable ? null : _toggleVoice,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AtomColors.ink,
      child: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.atomGutter, AtomSpace.sm, context.atomGutter, AtomSpace.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AtomColors.amber, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.auto_awesome_rounded, color: AtomColors.ink),
                ),
                const SizedBox(width: AtomSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text('Ask Atom', style: AtomText.heading.copyWith(color: AtomColors.white)),
                      ),
                      Text('Prices, plans and products', style: AtomText.small.copyWith(color: AtomColors.onDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.atomWidth * 0.78),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AtomColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Text(text, style: AtomText.body.copyWith(color: AtomColors.white)),
        ),
      ),
    );
  }
}

class _BotBubble extends StatelessWidget {
  const _BotBubble({required this.message, required this.onAction, required this.onAsk});

  final _Message message;
  final ValueChanged<AskAtomAction> onAction;

  /// Asks one of the related questions.
  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    final reply = message.reply;
    final paragraphs = message.text.split(RegExp(r'\n\s*\n')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    final plan = reply?.plan;
    final actions = reply?.actions ?? const <AskAtomAction>[];

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.atomWidth * 0.86),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: message.failed ? AtomColors.amberSoft : AtomColors.white,
            border: Border.all(color: message.failed ? AtomColors.amberSoft : AtomColors.line),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, p) in paragraphs.indexed) ...[
                if (i > 0) const SizedBox(height: 6),
                SelectableText.rich(_bold(p, AtomText.body.copyWith(color: message.failed ? AtomColors.amberInk : AtomColors.ink))),
              ],
              if (plan != null) ...[const SizedBox(height: AtomSpace.sm), _PlanCard(plan: plan)],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AtomSpace.sm),
                Wrap(
                  spacing: AtomSpace.xs,
                  runSpacing: AtomSpace.xs,
                  children: [
                    for (final (i, a) in actions.indexed)
                      AtomButton(
                        label: a.label,
                        icon: _icon(a.type),
                        size: AtomButtonSize.small,
                        variant: i == 0 ? AtomButtonVariant.primary : AtomButtonVariant.secondary,
                        onPressed: () => onAction(a),
                      ),
                  ],
                ),
              ],
              if ((reply?.related ?? const <String>[]).isNotEmpty) ...[
                const SizedBox(height: AtomSpace.sm),
                if (reply!.relatedTitle.isNotEmpty) ...[
                  Text(reply.relatedTitle, style: AtomText.small.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                ],
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final q in reply.related) AtomChoiceChip(label: q, selected: false, onTap: () => onAsk(q))],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The server marks bold as **…**; show it bold, without the stars.
  static TextSpan _bold(String text, TextStyle style) {
    final parts = text.split('**');
    return TextSpan(
      style: style,
      children: [
        for (final (i, part) in parts.indexed)
          if (part.isNotEmpty)
            TextSpan(
              text: part,
              style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w800) : null,
            ),
      ],
    );
  }

  static IconData _icon(String type) => switch (type) {
    'product' => Icons.visibility_outlined,
    'category' || 'brand' => Icons.grid_view_rounded,
    'whatsapp' => Icons.chat_outlined,
    'custom_order' => Icons.calculate_outlined,
    'offer' => Icons.chat_bubble_outline_rounded,
    'shop' => Icons.storefront_outlined,
    'faqs' => Icons.help_outline_rounded,
    'search' => Icons.search_rounded,
    _ => Icons.open_in_new_rounded,
  };
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final AskAtomPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AtomSpace.sm),
      decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('Per month · ${plan.months} months', style: AtomText.small)),
              Text(AtomFormat.rupees(plan.monthly), style: AtomText.heading.copyWith(color: AtomColors.primary)),
            ],
          ),
          const SizedBox(height: 4),
          _Line('Advance', AtomFormat.rupees(plan.advance)),
          _Line('Total payable', AtomFormat.rupees(plan.total)),
          const SizedBox(height: 4),
          Text('Estimate only. A verified seller confirms the final plan.', style: AtomText.small.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: AtomText.small)),
      Text(value, style: AtomText.label.copyWith(fontSize: 13)),
    ],
  );
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AtomSpace.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          label: 'Atom is typing',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AtomColors.white,
              border: Border.all(color: AtomColors.line),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AtomColors.primary)),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.waiting, required this.onSend, this.listening = false, this.onVoice});

  final TextEditingController controller;
  final bool waiting;
  final VoidCallback onSend;
  final bool listening;

  /// Null hides the mic (speech is not available on this phone).
  final VoidCallback? onVoice;

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    return Container(
      padding: EdgeInsets.fromLTRB(gutter, AtomSpace.xs, gutter, AtomSpace.sm),
      decoration: const BoxDecoration(
        color: AtomColors.white,
        border: Border(top: BorderSide(color: AtomColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(300)],
              onSubmitted: (_) => onSend(),
              style: AtomText.body.copyWith(fontSize: 15, color: AtomColors.ink),
              decoration: InputDecoration(
                hintText: listening ? 'Listening… speak now' : 'Ask about a product or plan…',
                semanticCounterText: 'Ask Atom a question',
                filled: true,
                fillColor: AtomColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AtomRadius.pill), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AtomRadius.pill), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AtomRadius.pill),
                  borderSide: const BorderSide(color: AtomColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AtomSpace.md, vertical: 12),
              ),
            ),
          ),
          if (onVoice != null) ...[
            const SizedBox(width: AtomSpace.xs),
            Semantics(
              liveRegion: true,
              child: Tooltip(
                message: listening ? 'Stop listening' : 'Speak your question',
                child: Material(
                  color: listening ? AtomColors.rose : AtomColors.surface,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: waiting && !listening ? null : onVoice,
                    child: SizedBox.square(
                      dimension: AtomSize.iconButton,
                      child: Icon(
                        listening ? Icons.stop_rounded : Icons.mic_none_rounded,
                        color: listening ? AtomColors.white : AtomColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: AtomSpace.xs),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final enabled = !waiting && value.text.trim().isNotEmpty;
              return Tooltip(
                message: 'Send',
                child: Material(
                  color: enabled ? AtomColors.primary : AtomColors.primary.withValues(alpha: 0.45),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: enabled ? onSend : null,
                    child: const SizedBox.square(
                      dimension: AtomSize.iconButton,
                      child: Icon(Icons.send_rounded, color: AtomColors.white, size: 20),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
