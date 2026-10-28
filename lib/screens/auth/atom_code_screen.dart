import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_auth.dart';
import '../../data/atom_http.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_text_field.dart';
import 'atom_auth_common.dart';

/// Why the code was sent.
enum CodePurpose { register, login }

/// Enter the code (canvas: "Verify code"): step 2 of sign-up, or signing in
/// with a code instead of a password.
class AtomCodeScreen extends ConsumerStatefulWidget {
  const AtomCodeScreen({super.key, required this.code, required this.purpose, this.login = ''});

  final CodeSent code;
  final CodePurpose purpose;

  /// Phone or email the code went to (for "Change" and resend).
  final String login;

  @override
  ConsumerState<AtomCodeScreen> createState() => _AtomCodeScreenState();
}

class _AtomCodeScreenState extends ConsumerState<AtomCodeScreen> {
  static const _length = 6;
  static const _wait = 60;

  final _code = TextEditingController();
  late CodeSent _sent = widget.code;
  Timer? _timer;
  int _secondsLeft = _wait;
  bool _busy = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _wait;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length < _length) {
      setState(() => _error = 'Enter the $_length-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = ref.read(atomAuthApiProvider);
    try {
      if (widget.purpose == CodePurpose.register) {
        await api.verifyRegistration(userUuid: _sent.id, code: code);
        await afterSignIn(ref);
        if (mounted) AtomNav.location(context, signUpStep: true);
      } else {
        await api.verifyLoginCode(challengeId: _sent.id, code: code);
        await afterSignIn(ref);
        if (mounted) AtomNav.finishAuth(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = atomMessage(e);
          _code.clear();
        });
      }
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    final api = ref.read(atomAuthApiProvider);
    try {
      final sent = widget.purpose == CodePurpose.register ? await api.resendRegistration(_sent.id) : await api.requestLoginCode(widget.login);
      if (!mounted) return;
      setState(() {
        _sent = sent.id.isEmpty ? _sent : sent;
        _resending = false;
        _startTimer();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A new code is on its way.')));
    } catch (e) {
      if (mounted) {
        setState(() {
          _resending = false;
          _error = atomMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final where = _sent.byWhatsApp ? 'WhatsApp' : 'email';
    final to = _sent.phoneMasked.isNotEmpty ? _sent.phoneMasked : widget.login;
    final minutes = _secondsLeft ~/ 60;
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return AuthScaffold(
      step: widget.purpose == CodePurpose.register ? 'Step 2 of 3' : null,
      bottom: AtomButton(label: 'Verify', icon: Icons.check_rounded, expand: true, loading: _busy, onPressed: _busy ? null : _verify),
      children: [
        const AuthIconTile(icon: Icons.mark_chat_unread_outlined),
        const SizedBox(height: AtomSpace.md),
        AuthTitle(
          title: 'Enter the code',
          subtitle: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(to.isEmpty ? 'We sent a $_length-digit code to $where. ' : 'We sent a $_length-digit code to $where on ', style: AtomText.body),
              if (to.isNotEmpty) Text('$to. ', style: AtomText.body.copyWith(color: AtomColors.ink, fontWeight: FontWeight.w800)),
              AuthLinks(center: false, parts: [('Change', () => Navigator.of(context).maybePop())]),
            ],
          ),
        ),
        if (_sent.channels.contains('email') && _sent.byWhatsApp) ...[
          const SizedBox(height: 6),
          Text('We also sent it to your email.', style: AtomText.small),
        ],
        const SizedBox(height: AtomSpace.lg),
        AtomCodeField(
          controller: _code,
          length: _length,
          errorText: _error,
          onCompleted: (_) {
            if (!_busy) _verify();
          },
        ),
        const SizedBox(height: AtomSpace.md),
        if (_secondsLeft > 0)
          Text.rich(TextSpan(children: [
            TextSpan(text: "Didn't get it? Resend in ", style: AtomText.body),
            TextSpan(text: '$minutes:$seconds', style: AtomText.label),
          ]))
        else
          Align(
            alignment: Alignment.centerLeft,
            child: AtomButton(
              label: 'Resend code',
              icon: Icons.refresh_rounded,
              variant: AtomButtonVariant.secondary,
              size: AtomButtonSize.small,
              loading: _resending,
              onPressed: _resending ? null : _resend,
            ),
          ),
      ],
    );
  }
}
