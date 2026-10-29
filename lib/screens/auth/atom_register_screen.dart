import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_auth.dart';
import '../../data/atom_http.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../widgets/atom_logo.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_text_field.dart';
import '../info/atom_legal_screen.dart';
import 'atom_auth_common.dart';
import 'atom_code_screen.dart';

/// Create account, step 1 of 3 (canvas: "Create account"). The account
/// endpoint needs an email and sends the code there; step 2 checks it,
/// step 3 saves the delivery area with the mobile number.
class AtomRegisterScreen extends ConsumerStatefulWidget {
  const AtomRegisterScreen({super.key});

  @override
  ConsumerState<AtomRegisterScreen> createState() => _AtomRegisterScreenState();
}

class _AtomRegisterScreenState extends ConsumerState<AtomRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _agreed = false;
  bool _busy = false;
  String? _error;
  AtomApiException? _fieldErrors;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _server(String field) => _fieldErrors?.fieldError(field);

  Future<void> _submit() async {
    // A second tap before the button repaints must not send twice.
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _fieldErrors = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await ref.read(atomAuthApiProvider).register(
            name: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
      if (!mounted) return;
      setState(() => _busy = false);
      AtomNav.code(context, code, CodePurpose.register, login: _email.text.trim());
    } on AtomApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
        if (e.data.isNotEmpty) _fieldErrors = e;
      });
      _form.currentState?.validate();
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
      step: 'Step 1 of 3',
      bottom: AtomButton(
        label: 'Send code',
        icon: Icons.mail_outline_rounded,
        expand: true,
        loading: _busy,
        onPressed: _agreed && !_busy ? _submit : null,
      ),
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(alignment: Alignment.centerLeft, child: AtomLogo(height: 36)),
                const SizedBox(height: AtomSpace.md),
                AuthTitle(
                  title: 'Create your account',
                  subtitle: Text("We'll email you a code to confirm it's you.", style: AtomText.body),
                ),
                const SizedBox(height: AtomSpace.lg),
                AtomTextField(
                  label: 'Full name',
                  controller: _name,
                  hint: 'Enter your full name',
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) => validatePersonName(v) ?? _server('name'),
                ),
                const SizedBox(height: 14),
                AtomTextField(
                  label: 'Phone number',
                  controller: _phone,
                  hint: '03001234567',
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')), LengthLimitingTextInputFormatter(20)],
                  validator: (v) => validatePhone(v) ?? _server('phone'),
                ),
                const SizedBox(height: 14),
                AtomTextField(
                  label: 'Email',
                  controller: _email,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => ((v ?? '').trim().isEmpty ? 'Enter your email.' : validateOptionalEmail(v)) ?? _server('email'),
                ),
                const SizedBox(height: 14),
                AtomPasswordField(
                  controller: _password,
                  hint: 'At least 8 characters',
                  newPassword: true,
                  validator: (v) => validateNewPassword(v) ?? _server('password'),
                ),
                const SizedBox(height: AtomSpace.md),
                Semantics(
                  checked: _agreed,
                  child: InkWell(
                    onTap: () => setState(() => _agreed = !_agreed),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(value: _agreed, onChanged: (v) => setState(() => _agreed = v ?? false), activeColor: AtomColors.primary),
                        Expanded(
                          child: AuthLinks(center: false, parts: [
                            ('I agree to the ', null),
                            ('Terms of use', () => AtomNav.legal(context, tab: LegalTab.terms)),
                            (' and ', null),
                            ('Privacy policy', () => AtomNav.legal(context, tab: LegalTab.privacy)),
                            ('.', null),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
                AuthError(_error),
                const SizedBox(height: AtomSpace.md),
                AuthLinks(parts: [
                  ('Already have an account? ', null),
                  ('Sign in', () => AtomNav.signIn(context, replace: true)),
                  (' · ', null),
                  ('Continue as guest', () => AtomNav.finishAuth(context)),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
