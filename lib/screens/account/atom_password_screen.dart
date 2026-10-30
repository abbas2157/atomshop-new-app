import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/session_manager.dart';
import '../../data/atom_auth.dart';
import '../../data/atom_http.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_text_field.dart';

/// Change password (canvas: "Change password").
class AtomPasswordScreen extends ConsumerStatefulWidget {
  const AtomPasswordScreen({super.key});

  @override
  ConsumerState<AtomPasswordScreen> createState() => _AtomPasswordScreenState();
}

class _AtomPasswordScreenState extends ConsumerState<AtomPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _forgot() async {
    final phone = await SessionManager.getPhone() ?? '';
    if (mounted) AtomNav.forgotPassword(context, login: phone);
  }

  Future<void> _save() async {
    // A second tap before the button repaints must not send twice.
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(atomAuthApiProvider).changePassword(current: _current.text, next: _next.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your password has been changed.')));
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(atomMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: AtomPage(
        title: 'Change password',
        bottom: AtomButton(label: 'Update password', icon: Icons.lock_outline_rounded, expand: true, loading: _saving, onPressed: _saving ? null : _save),
        children: [
          const SizedBox(height: AtomSpace.xs),
          AtomPasswordField(
            controller: _current,
            label: 'Current password',
            textInputAction: TextInputAction.next,
            validator: (v) => (v ?? '').isEmpty ? 'Enter your current password.' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgot,
              child: Text('Forgot it?', style: AtomText.label.copyWith(color: AtomColors.primary)),
            ),
          ),
          AtomPasswordField(
            controller: _next,
            label: 'New password',
            hint: 'At least 8 characters',
            newPassword: true,
            textInputAction: TextInputAction.next,
            validator: (v) {
              final t = v ?? '';
              if (t.length < 8) return 'Use at least 8 characters.';
              if (t == _current.text) return 'Choose a password different from the current one.';
              return null;
            },
          ),
          const SizedBox(height: 14),
          AtomPasswordField(
            controller: _confirm,
            label: 'Confirm new password',
            newPassword: true,
            onSubmitted: _save,
            validator: (v) => v == _next.text ? null : 'The passwords do not match.',
          ),
          const SizedBox(height: AtomSpace.md),
          const AtomNotice(icon: Icons.info_outline_rounded, text: 'This changes your password for both Atomshop and AtomPay.'),
        ],
      ),
    );
  }
}
