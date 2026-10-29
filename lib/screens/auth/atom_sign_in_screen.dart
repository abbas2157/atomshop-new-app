import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_auth.dart';
import '../../data/atom_http.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';
import '../info/atom_legal_screen.dart';
import 'atom_auth_common.dart';
import 'atom_code_screen.dart';

/// Sign in (canvas: "Sign in"): phone or email and password, or a code on
/// WhatsApp. Customers only; the same login works on the website and AtomPay.
class AtomSignInScreen extends ConsumerStatefulWidget {
  const AtomSignInScreen({super.key});

  @override
  ConsumerState<AtomSignInScreen> createState() => _AtomSignInScreenState();
}

class _AtomSignInScreenState extends ConsumerState<AtomSignInScreen> {
  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _sendingCode = false;
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // A second tap before the button repaints must not send twice.
    if (_busy || _sendingCode) return;
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(atomAuthApiProvider).signIn(login: _login.text, password: _password.text);
      await afterSignIn(ref);
      if (mounted) AtomNav.finishAuth(context);
    } on NeedsVerification catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AtomNav.code(context, e.code, CodePurpose.register, login: _login.text.trim());
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = atomMessage(e);
        });
      }
    }
  }

  Future<void> _sendCode() async {
    // A second tap before the button repaints must not send twice.
    if (_busy || _sendingCode) return;
    FocusScope.of(context).unfocus();
    final problem = validateLogin(_login.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _sendingCode = true;
      _error = null;
    });
    try {
      final code = await ref.read(atomAuthApiProvider).requestLoginCode(_login.text);
      if (!mounted) return;
      setState(() => _sendingCode = false);
      AtomNav.code(context, code, CodePurpose.login, login: _login.text.trim());
    } catch (e) {
      if (mounted) {
        setState(() {
          _sendingCode = false;
          _error = atomMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    // Light status-bar icons over the dark header.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AtomPageWidth(
          child: Form(
            key: _form,
            child: AutofillGroup(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DarkHeader(onGuest: () => AtomNav.finishAuth(context)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(gutter, AtomSpace.lg, gutter, AtomSpace.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AtomSegmented<int>(
                          items: const {0: 'Sign in', 1: 'Create account'},
                          value: 0,
                          onChanged: (v) {
                            if (v == 1) AtomNav.register(context, replace: true);
                          },
                        ),
                        const SizedBox(height: AtomSpace.lg),
                        AtomTextField(
                          label: 'Phone number or email',
                          controller: _login,
                          hint: '0300 1234567',
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username, AutofillHints.telephoneNumber],
                          validator: validateLogin,
                        ),
                        const SizedBox(height: 14),
                        AtomPasswordField(controller: _password, validator: (v) => (v ?? '').isEmpty ? 'Enter your password.' : null, onSubmitted: _signIn),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AtomButton(
                            label: 'Forgot password?',
                            icon: Icons.lock_reset_rounded,
                            variant: AtomButtonVariant.text,
                            size: AtomButtonSize.small,
                            onPressed: () => AtomNav.forgotPassword(context, login: _login.text.trim()),
                          ),
                        ),
                        AuthError(_error),
                        const SizedBox(height: AtomSpace.sm),
                        AtomButton(label: 'Sign in', icon: Icons.login_rounded, expand: true, loading: _busy, onPressed: _busy ? null : _signIn),
                        if (AtomAuthApi.supportsCodeSignIn) ...[
                        const SizedBox(height: AtomSpace.md),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AtomSpace.sm),
                              child: Text('or', style: AtomText.small),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: AtomSpace.md),
                        AtomButton(
                          label: 'Get a code on WhatsApp',
                          icon: Icons.chat_outlined,
                          variant: AtomButtonVariant.secondary,
                          expand: true,
                          loading: _sendingCode,
                          onPressed: _sendingCode ? null : _sendCode,
                        ),
                        ],
                        const SizedBox(height: AtomSpace.lg),
                        AuthLinks(
                          parts: [
                            ('By continuing you agree to the ', null),
                            ('Terms of use', () => AtomNav.legal(context, tab: LegalTab.terms)),
                            (' and ', null),
                            ('Privacy policy', () => AtomNav.legal(context, tab: LegalTab.privacy)),
                            ('.', null),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkHeader extends StatelessWidget {
  const _DarkHeader({required this.onGuest});

  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    return Container(
      decoration: const BoxDecoration(
        color: AtomColors.ink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(gutter, MediaQuery.paddingOf(context).top + AtomSpace.sm, gutter, AtomSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (Navigator.of(context).canPop()) ...[
                AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', dark: true, onPressed: () => Navigator.of(context).maybePop()),
                const SizedBox(width: AtomSpace.sm),
              ],
              Expanded(
                child: Text(
                  'Atomshop.pk',
                  style: AtomText.subheading.copyWith(color: AtomColors.white, fontWeight: FontWeight.w800),
                ),
              ),
              Material(
                color: Colors.transparent,
                shape: StadiumBorder(side: BorderSide(color: AtomColors.white.withValues(alpha: 0.3))),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onGuest,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 40),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 16, color: AtomColors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Continue as guest',
                            style: AtomText.small.copyWith(color: AtomColors.white, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AtomSpace.lg),
          Text('ONE ACCOUNT', style: AtomText.eyebrow.copyWith(color: AtomColors.amber)),
          const SizedBox(height: 6),
          Semantics(
            header: true,
            child: Text('Sign in to track your plans', style: AtomText.title.copyWith(color: AtomColors.white)),
          ),
          const SizedBox(height: 6),
          Text('The same login works on atomshop.pk and AtomPay.', style: AtomText.body.copyWith(color: AtomColors.onDark)),
        ],
      ),
    );
  }
}
