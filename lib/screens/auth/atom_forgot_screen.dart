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
      final code = await ref.read(atomAuthApiProvider).forgotPassword(login: _login.text, byEmail: false);
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
        const SizedBox(height: AtomSpace.sm),
        Text('We send the code to your WhatsApp and, if your account has one, your email.', style: AtomText.small),
        AuthError(_error),
      ],
    );
  }
}
