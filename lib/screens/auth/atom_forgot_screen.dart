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

/// Forgot password (canvas: "Forgot password"). Also how a guest who ordered
/// sets a password: their order is saved to their phone number.
class AtomForgotScreen extends ConsumerStatefulWidget {
  const AtomForgotScreen({super.key, this.login = ''});

  final String login;

  @override
  ConsumerState<AtomForgotScreen> createState() => _AtomForgotScreenState();
}

class _AtomForgotScreenState extends ConsumerState<AtomForgotScreen> {
  final _form = GlobalKey<FormState>();
  late final _login = TextEditingController(text: widget.login);
  bool _byEmail = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    // A second tap before the button repaints must not send twice.
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await ref.read(atomAuthApiProvider).forgotPassword(login: _login.text, byEmail: _byEmail);
      if (!mounted) return;
      setState(() => _busy = false);
      AtomNav.resetPassword(context, code);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = atomMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      bottom: AtomButton(label: 'Send code', icon: Icons.send_rounded, expand: true, loading: _busy, onPressed: _busy ? null : _send),
      children: [
        const AuthIconTile(icon: Icons.lock_outline_rounded, amber: true),
        const SizedBox(height: AtomSpace.md),
        AuthTitle(
          title: 'Forgot your password?',
          subtitle: Text("Enter the phone number or email on your account. We'll send you a code to set a new password.", style: AtomText.body),
        ),
        const SizedBox(height: AtomSpace.lg),
        Form(
          key: _form,
          child: AtomTextField(
            label: 'Phone number or email',
            controller: _login,
            hint: '03001234567',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username],
            textInputAction: TextInputAction.done,
            validator: validateLogin,
          ),
        ),
        const SizedBox(height: AtomSpace.lg),
        Semantics(header: true, child: Text('Send the code by', style: AtomText.label)),
        const SizedBox(height: AtomSpace.xs),
        _ChannelRow(label: 'WhatsApp', icon: Icons.chat_outlined, selected: !_byEmail, onTap: () => setState(() => _byEmail = false)),
        const SizedBox(height: AtomSpace.xs),
        _ChannelRow(label: 'Email', icon: Icons.mail_outline_rounded, selected: _byEmail, onTap: () => setState(() => _byEmail = true)),
        AuthError(_error),
      ],
    );
  }
}

/// Full-width radio row.
class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AtomColors.primarySoft : AtomColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtomRadius.input),
          side: BorderSide(color: selected ? AtomColors.primary : AtomColors.line2, width: selected ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AtomSpace.md),
              child: Row(
                children: [
                  Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: selected ? AtomColors.primary : AtomColors.muted),
                  const SizedBox(width: AtomSpace.sm),
                  Icon(icon, size: 20, color: AtomColors.body),
                  const SizedBox(width: AtomSpace.xs),
                  Text(label, style: AtomText.label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
