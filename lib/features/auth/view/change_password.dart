import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/core/common/widgets/custom_text_field.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  final String userUuid;
  const ChangePasswordScreen({super.key, required this.userUuid});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _entranceController;
  late Animation<Offset> _cardSlideAnim;
  late Animation<double> _cardFadeAnim;

  late AnimationController _fieldsController;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  late AnimationController _iconController;
  late Animation<double> _iconScaleAnim;
  late Animation<double> _iconFadeAnim;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _cardSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _cardFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _fieldsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconScaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
    _iconFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _iconController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _entranceController.forward();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _fieldsController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _fieldsController.dispose();
    _pulseController.dispose();
    _iconController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _sf(Widget child, int index) {
    final start = (index * 0.13).clamp(0.0, 0.8);
    final end = (start + 0.55).clamp(0.0, 1.0);
    final fadeA = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fieldsController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
    final slideA = Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _fieldsController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );
    return FadeTransition(
      opacity: fadeA,
      child: SlideTransition(position: slideA, child: child),
    );
  }

  // View only validates the form and calls the viewmodel — nothing else
  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authViewModelProvider.notifier)
          .changePassword(
            uuid: widget.userUuid,
            newPassword: _newPasswordController.text.trim(),
          );
    }
  }

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => AppNavigator.getBack(),
                        icon: const Icon(Icons.arrow_back_ios),
                        padding: EdgeInsets.zero,
                      ),
                      Text(
                        'Change Password',
                        style: AppTextStyles.h5.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _iconController,
                      _pulseController,
                    ]),
                    builder: (_, __) => FadeTransition(
                      opacity: _iconFadeAnim,
                      child: Transform.scale(
                        scale: _iconScaleAnim.value,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: _pulseAnim.value,
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ColorPalette.secondary.withOpacity(
                                      0.08,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ColorPalette.secondary.withOpacity(
                                    0.15,
                                  ),
                                ),
                                child: Icon(
                                  Icons.shield_outlined,
                                  size: 30,
                                  color: ColorPalette.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SlideTransition(
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
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _sf(
                                  Text(
                                    'Update your password',
                                    style: AppTextStyles.h4.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  0,
                                ),
                                const SizedBox(height: 8),
                                _sf(
                                  Text(
                                    'Keep your account safe with a strong password.',
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
                                    labelText: 'Current Password',
                                    hintText: 'Enter your current password',
                                    controller: _oldPasswordController,
                                    isPassword: true,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      size: 20,
                                    ),
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Please enter your current password'
                                        : null,
                                  ),
                                  2,
                                ),
                                const SizedBox(height: 20),
                                _sf(
                                  CustomTextField(
                                    labelText: 'New Password',
                                    hintText: 'Create a strong password',
                                    controller: _newPasswordController,
                                    isPassword: true,
                                    prefixIcon: const Icon(
                                      Icons.lock_reset_rounded,
                                      size: 20,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Please enter a new password';
                                      }
                                      if (v.length < 6) {
                                        return 'Minimum 6 characters';
                                      }
                                      if (v == _oldPasswordController.text) {
                                        return 'Must differ from current password';
                                      }
                                      return null;
                                    },
                                  ),
                                  3,
                                ),
                                const SizedBox(height: 20),
                                _sf(
                                  CustomTextField(
                                    labelText: 'Confirm New Password',
                                    hintText: 'Re-enter your new password',
                                    controller: _confirmPasswordController,
                                    isPassword: true,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      size: 20,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (v != _newPasswordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                    onSubmitted: (_) => _submit(),
                                  ),
                                  4,
                                ),
                                const SizedBox(height: 36),
                                _sf(
                                  ScaleTransition(
                                    scale: _pulseAnim,
                                    child: CustomButton(
                                      title: 'Update Password',
                                      onPressed: _submit,
                                      isLoading: authState.isLoading,
                                      height: 56,
                                    ),
                                  ),
                                  5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
