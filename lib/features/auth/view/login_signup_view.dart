import 'package:atompro/core/common/utils/utils.dart';
import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/core/common/widgets/custom_text_field.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/core/style/extensions.dart';
import 'package:atompro/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _AuthMode { login, signup, forgotEmail, forgotOtp, forgotSetPassword }

class ModernAuthScreen extends ConsumerStatefulWidget {
  const ModernAuthScreen({super.key});

  @override
  ConsumerState<ModernAuthScreen> createState() => _ModernAuthScreenState();
}

class _ModernAuthScreenState extends ConsumerState<ModernAuthScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  _AuthMode _authMode = _AuthMode.login;

  /// UUID received from sendForgotPasswordOtp — passed through OTP → setPassword
  String _forgotUuid = '';
  String _forgotEmail = '';

  // ── Form Keys ──────────────────────────────────────────────────────────────
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _forgotEmailFormKey = GlobalKey<FormState>();
  final _forgotOtpFormKey = GlobalKey<FormState>();
  final _forgotSetPasswordFormKey = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────────────────────────────────
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// 4 individual OTP digit controllers + focus nodes
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  // ── Animation Controllers ─────────────────────────────────────────────────
  late AnimationController _formAnimController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late AnimationController _logoAnimController;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;

  late AnimationController _cardAnimController;
  late Animation<Offset> _cardSlideAnim;
  late Animation<double> _cardFadeAnim;

  late AnimationController _fieldsAnimController;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _formAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formAnimController, curve: Curves.easeInOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0.25, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _formAnimController,
            curve: Curves.easeOutCubic,
          ),
        );

    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.elasticOut),
    );
    _logoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _cardAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
    _cardFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.easeOut),
    );

    _fieldsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _logoAnimController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _cardAnimController.forward();
        _formAnimController.forward();
        _fieldsAnimController.forward();
      }
    });
  }

  @override
  void dispose() {
    _formAnimController.dispose();
    _logoAnimController.dispose();
    _cardAnimController.dispose();
    _fieldsAnimController.dispose();
    _pulseController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _forgotEmailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  // ── Mode switching ─────────────────────────────────────────────────────────
  void _switchMode(_AuthMode newMode) {
    if (_authMode == newMode) return;
    setState(() => _authMode = newMode);
    _formAnimController.reset();
    _fieldsAnimController.reset();
    _formAnimController.forward();
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _fieldsAnimController.forward();
    });
  }

  // ── Staggered field helper ─────────────────────────────────────────────────
  Widget _sf(Widget child, int index) {
    final start = (index * 0.12).clamp(0.0, 0.8);
    final end = (start + 0.55).clamp(0.0, 1.0);
    final fadeA = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fieldsAnimController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
    final slideA = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _fieldsAnimController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );
    return FadeTransition(
      opacity: fadeA,
      child: SlideTransition(position: slideA, child: child),
    );
  }

  // ── SnackBar helper ────────────────────────────────────────────────────────

  // ── Action Handlers ────────────────────────────────────────────────────────

  void _handleLogin() {
    if (_loginFormKey.currentState!.validate()) {
      ref
          .read(authViewModelProvider.notifier)
          .login(
            _loginEmailController.text.trim(),
            _loginPasswordController.text.trim(),
          );
    }
  }

  void _handleSignup() {
    if (_signupFormKey.currentState!.validate()) {
      ref
          .read(authViewModelProvider.notifier)
          .signup(
            name: _signupNameController.text.trim(),
            email: _signupEmailController.text.trim(),
            password: _signupPasswordController.text.trim(),
          );
    }
  }

  Future<void> _handleSendForgotOtp() async {
    if (!_forgotEmailFormKey.currentState!.validate()) return;
    final email = _forgotEmailController.text.trim();
    try {
      final uuid = await ref
          .read(authViewModelProvider.notifier)
          .sendForgotPasswordOtp(email);
      _forgotUuid = uuid;
      _forgotEmail = email;
      for (final c in _otpControllers) {
        c.clear();
      }
      _switchMode(_AuthMode.forgotOtp);
      // VM already showed "Reset code sent to email" snackbar
    } catch (_) {
      // VM already showed error snackbar
    }
  }

  Future<void> _handleVerifyForgotOtp() async {
    if (!_forgotOtpFormKey.currentState!.validate()) return;
    final code = _otpControllers.map((c) => c.text).join();
    try {
      await ref
          .read(authViewModelProvider.notifier)
          .verifyForgotPasswordOtp(_forgotUuid, code);
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _switchMode(_AuthMode.forgotSetPassword);
    } catch (_) {}
  }

  Future<void> _handleSetNewPassword() async {
    if (!_forgotSetPasswordFormKey.currentState!.validate()) return;
    try {
      await ref
          .read(authViewModelProvider.notifier)
          .setNewPassword(
            uuid: _forgotUuid,
            password: _newPasswordController.text.trim(),
          );
      // VM set state to data(null) — now handle post-success in view
      SnackbarService().showSuccessSnackBar(
        'Password reset successfully! Please log in.',
      );
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _forgotEmailController.clear();
      _forgotUuid = '';
      _switchMode(_AuthMode.login);
    } catch (_) {
      // VM already showed error snackbar — nothing to do here
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ColorPalette.backgroundBlueLight, ColorPalette.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  IconButton(
                    onPressed: () => AppNavigator.getBack(),
                    icon: const Icon(Icons.arrow_back_ios),
                  ).alignTopLeft,
                  _buildHeader(),
                  _buildCard(authState),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _logoAnimController,
      builder: (_, __) => FadeTransition(
        opacity: _logoFadeAnim,
        child: Transform.scale(
          scale: _logoScaleAnim.value,
          child: SizedBox(height: 170, width: 180, child: logo()),
        ),
      ),
    );
  }

  // ── Card wrapper ───────────────────────────────────────────────────────────
  Widget _buildCard(AsyncValue authState) {
    final showToggle =
        _authMode == _AuthMode.login || _authMode == _AuthMode.signup;

    return SlideTransition(
      position: _cardSlideAnim,
      child: FadeTransition(
        opacity: _cardFadeAnim,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: showToggle
                    ? _buildModeToggle()
                    : const SizedBox.shrink(),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _buildCurrentForm(authState),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentForm(AsyncValue authState) {
    switch (_authMode) {
      case _AuthMode.login:
        return _buildLoginForm(authState);
      case _AuthMode.signup:
        return _buildSignupForm(authState);
      case _AuthMode.forgotEmail:
        return _buildForgotEmailForm(authState);
      case _AuthMode.forgotOtp:
        return _buildForgotOtpForm(authState);
      case _AuthMode.forgotSetPassword:
        return _buildSetPasswordForm(authState);
    }
  }

  // ── Toggle ─────────────────────────────────────────────────────────────────
  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ColorPalette.surfaceGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeBtn(
              'Login',
              _authMode == _AuthMode.login,
              () => _switchMode(_AuthMode.login),
            ),
          ),
          Expanded(
            child: _buildModeBtn(
              'Sign Up',
              _authMode == _AuthMode.signup,
              () => _switchMode(_AuthMode.signup),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBtn(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? ColorPalette.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : ColorPalette.textSecondary,
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }

  // ── Login Form ─────────────────────────────────────────────────────────────
  Widget _buildLoginForm(AsyncValue authState) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sf(
            Text(
              'Welcome Back!',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            0,
          ),
          const SizedBox(height: 8),
          _sf(
            Text(
              'Continue your shopping journey with us..!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: ColorPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            1,
          ),
          const SizedBox(height: 32),
          _sf(
            CustomTextField(
              labelText: 'Email Address',
              hintText: 'yourname@email.com',
              controller: _loginEmailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Please enter email' : null,
            ),
            2,
          ),
          const SizedBox(height: 20),
          _sf(
            CustomTextField(
              labelText: 'Password',
              hintText: '••••••••',
              controller: _loginPasswordController,
              isPassword: true,
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Please enter password' : null,
              onSubmitted: (_) => _handleLogin(),
            ),
            3,
          ),
          const SizedBox(height: 8),
          _sf(
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _switchMode(_AuthMode.forgotEmail),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot Password?',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ColorPalette.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            4,
          ),
          const SizedBox(height: 16),
          _sf(
            ScaleTransition(
              scale: _pulseAnim,
              child: CustomButton(
                title: 'Login',
                onPressed: _handleLogin,
                isLoading: authState.isLoading,
                height: 56,
              ),
            ),
            5,
          ),
        ],
      ),
    );
  }

  // ── Signup Form ────────────────────────────────────────────────────────────
  Widget _buildSignupForm(AsyncValue authState) {
    return Form(
      key: _signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sf(
            Text(
              'Create Account',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            0,
          ),
          const SizedBox(height: 32),
          _sf(
            CustomTextField(
              labelText: 'Full Name',
              hintText: 'John Doe',
              controller: _signupNameController,
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              validator: (v) => v!.isEmpty ? 'Enter your name' : null,
            ),
            1,
          ),
          const SizedBox(height: 20),
          _sf(
            CustomTextField(
              labelText: 'Email Address',
              hintText: 'yourname@email.com',
              controller: _signupEmailController,
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              validator: (v) => v!.isEmpty ? 'Enter email' : null,
            ),
            2,
          ),
          const SizedBox(height: 20),
          _sf(
            CustomTextField(
              labelText: 'Password',
              hintText: 'Create a strong password',
              controller: _signupPasswordController,
              isPassword: true,
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
              onSubmitted: (_) => _handleSignup(),
            ),
            3,
          ),
          const SizedBox(height: 32),
          _sf(
            ScaleTransition(
              scale: _pulseAnim,
              child: CustomButton(
                title: 'Create Account',
                onPressed: _handleSignup,
                isLoading: authState.isLoading,
                height: 56,
              ),
            ),
            4,
          ),
        ],
      ),
    );
  }

  // ── Forgot — Step 1: Email ─────────────────────────────────────────────────
  Widget _buildForgotEmailForm(AsyncValue authState) {
    return Form(
      key: _forgotEmailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sf(_buildBackLink(() => _switchMode(_AuthMode.login)), 0),
          const SizedBox(height: 20),
          _sf(Center(child: _buildPulsingIcon(Icons.lock_reset_rounded)), 1),
          const SizedBox(height: 20),
          _sf(
            Text(
              'Forgot Password?',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            2,
          ),
          const SizedBox(height: 8),
          _sf(
            Text(
              "No worries! Enter your email and we'll send you a reset code.",
              style: AppTextStyles.bodyMedium.copyWith(
                color: ColorPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            3,
          ),
          const SizedBox(height: 32),
          _sf(
            CustomTextField(
              labelText: 'Email Address',
              hintText: 'yourname@email.com',
              controller: _forgotEmailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                  return 'Enter a valid email';
                }
                return null;
              },
              onSubmitted: (_) => _handleSendForgotOtp(),
            ),
            4,
          ),
          const SizedBox(height: 28),
          _sf(
            ScaleTransition(
              scale: _pulseAnim,
              child: CustomButton(
                title: 'Send Reset Code',
                onPressed: _handleSendForgotOtp,
                isLoading: authState.isLoading,
                height: 56,
              ),
            ),
            5,
          ),
        ],
      ),
    );
  }

  // ── Forgot — Step 2: OTP ───────────────────────────────────────────────────
  Widget _buildForgotOtpForm(AsyncValue authState) {
    return Form(
      key: _forgotOtpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sf(_buildBackLink(() => _switchMode(_AuthMode.forgotEmail)), 0),
          const SizedBox(height: 20),
          _sf(
            Center(child: _buildPulsingIcon(Icons.mark_email_read_outlined)),
            1,
          ),
          const SizedBox(height: 20),
          _sf(
            Text(
              'Check your email',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            2,
          ),
          const SizedBox(height: 8),
          _sf(
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.textSecondary,
                ),
                children: [
                  const TextSpan(text: 'We sent a 4-digit code to\n'),
                  TextSpan(
                    text: _forgotEmail,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ColorPalette.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            3,
          ),
          const SizedBox(height: 32),
          // ── 4-box OTP input ──
          _sf(_buildOtpRow(), 4),
          const SizedBox(height: 12),
          _sf(
            Center(
              child: TextButton(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(authViewModelProvider.notifier)
                              .sendForgotPasswordOtp(_forgotEmail);
                          // VM shows "Reset code sent to email" snackbar
                          // No UUID update needed — user already has it from step 1
                        } catch (_) {}
                      },
                child: Text(
                  'Resend Code',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ColorPalette.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            5,
          ),
          const SizedBox(height: 20),
          _sf(
            ScaleTransition(
              scale: _pulseAnim,
              child: CustomButton(
                title: 'Verify Code',
                onPressed: _handleVerifyForgotOtp,
                isLoading: authState.isLoading,
                height: 56,
              ),
            ),
            6,
          ),
        ],
      ),
    );
  }

  /// 4 individual digit boxes for OTP
  Widget _buildOtpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (i) {
        return SizedBox(
          width: 60,
          height: 60,
          child: TextFormField(
            controller: _otpControllers[i],
            focusNode: _otpFocusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: ColorPalette.surfaceGray,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: ColorPalette.secondary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              filled: true,
              fillColor: ColorPalette.surfaceGray.withOpacity(0.4),
            ),
            validator: (v) => (v == null || v.isEmpty) ? '' : null,
            onChanged: (v) {
              if (v.length == 1 && i < 3) {
                _otpFocusNodes[i + 1].requestFocus();
              }
              if (v.isEmpty && i > 0) {
                _otpFocusNodes[i - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  // ── Forgot — Step 3: Set New Password ─────────────────────────────────────
  Widget _buildSetPasswordForm(AsyncValue authState) {
    return Form(
      key: _forgotSetPasswordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sf(Center(child: _buildPulsingIcon(Icons.lock_open_rounded)), 0),
          const SizedBox(height: 20),
          _sf(
            Text(
              'Set New Password',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            1,
          ),
          const SizedBox(height: 8),
          _sf(
            Text(
              'Your new password must be different from your previous one.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: ColorPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            2,
          ),
          const SizedBox(height: 32),
          _sf(
            CustomTextField(
              labelText: 'New Password',
              hintText: 'Create a strong password',
              controller: _newPasswordController,
              isPassword: true,
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter a password';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            3,
          ),
          const SizedBox(height: 20),
          _sf(
            CustomTextField(
              labelText: 'Confirm Password',
              hintText: 'Re-enter your password',
              controller: _confirmPasswordController,
              isPassword: true,
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please confirm your password';
                }
                if (v != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              onSubmitted: (_) => _handleSetNewPassword(),
            ),
            4,
          ),
          const SizedBox(height: 32),
          _sf(
            ScaleTransition(
              scale: _pulseAnim,
              child: CustomButton(
                title: 'Reset Password',
                onPressed: _handleSetNewPassword,
                isLoading: authState.isLoading,
                height: 56,
              ),
            ),
            5,
          ),
        ],
      ),
    );
  }

  // ── Shared UI pieces ───────────────────────────────────────────────────────
  Widget _buildBackLink(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_ios, size: 16, color: ColorPalette.secondary),
          const SizedBox(width: 4),
          Text(
            'Back',
            style: AppTextStyles.bodySmall.copyWith(
              color: ColorPalette.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingIcon(IconData icon) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorPalette.secondary.withOpacity(0.12),
              ),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorPalette.secondary.withOpacity(0.18),
            ),
            child: Icon(icon, size: 28, color: ColorPalette.secondary),
          ),
        ],
      ),
    );
  }
}
