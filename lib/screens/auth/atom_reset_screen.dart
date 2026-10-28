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

/// New password (canvas: "New password"): the code, then a new password.
/// Saving signs the customer in.
class AtomResetScreen extends ConsumerStatefulWidget {
  const AtomResetScreen({super.key, required this.code});

  final CodeSent code;

  @override
  ConsumerState<AtomResetScreen> createState() => _AtomResetScreenState();
}

class _AtomResetScreenState extends ConsumerState<AtomResetScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  /// Kept after a correct code, so a refused password doesn't spend the
  /// code again.
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    _password.addListener(_onPassword);
  }

  void _onPassword() => setState(() {});

  @override
  void dispose() {
    _password.removeListener(_onPassword);
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = ref.read(atomAuthApiProvider);
    try {
      _resetToken ??= await api.verifyReset(resetId: widget.code.id, code: _code.text.trim());
      await api.resetPassword(resetToken: _resetToken!, password: _password.text);
      await afterSignIn(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password saved. You are signed in.')));
      AtomNav.finishAuth(context);
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
    final where = widget.code.byWhatsApp ? 'WhatsApp' : 'email';
    return AuthScaffold(
      bottom: AtomButton(label: 'Save and sign in', icon: Icons.lock_outline_rounded, expand: true, loading: _busy, onPressed: _busy ? null : _save),
      children: [
        AuthTitle(
          title: 'Set a new password',
          subtitle: Text(
            'Enter the code we sent to $where${widget.code.phoneMasked.isEmpty ? '' : ' on ${widget.code.phoneMasked}'}, then choose a new password.',
            style: AtomText.body,
          ),
        ),
        const SizedBox(height: AtomSpace.lg),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Code', style: AtomText.label),
                const SizedBox(height: 6),
                AtomCodeField(controller: _code, length: 6),
                const SizedBox(height: AtomSpace.md),
                AtomPasswordField(
                  controller: _password,
                  label: 'New password',
                  hint: 'At least 8 characters',
                  newPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: validateNewPassword,
                ),
                const SizedBox(height: AtomSpace.xs),
                _Strength(password: _password.text),
                const SizedBox(height: 14),
                AtomPasswordField(
                  controller: _confirm,
                  label: 'Confirm new password',
                  newPassword: true,
                  onSubmitted: _save,
                  validator: (v) => v != _password.text ? 'The passwords do not match.' : null,
                ),
              ],
            ),
          ),
        ),
        AuthError(_error),
      ],
    );
  }
}

/// Four-segment strength meter: length 8+, a digit, mixed case, a symbol.
class _Strength extends StatelessWidget {
  const _Strength({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final score = [
      password.length >= 8,
      RegExp(r'\d').hasMatch(password),
      RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password),
      RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    ].where((ok) => ok).length;
    final (label, color) = switch (score) {
      <= 1 => ('Weak password', AtomColors.rose),
      2 => ('Fair password', AtomColors.amberInk),
      3 => ('Good password', AtomColors.green),
      _ => ('Strong password', AtomColors.green),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(color: i < score ? color : AtomColors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const SizedBox(width: 4),
          Text(label, style: AtomText.small.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
