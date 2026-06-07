import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/features/seller/auth/viewmodel/seller_auth_viewmodel.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerLoginScreen extends ConsumerStatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  ConsumerState<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends ConsumerState<SellerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _switchToCustomerMode() => AppNavigator.goToCustomerMode();

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(sellerAuthViewModelProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(sellerAuthViewModelProvider).isLoading;

    // Pushed as its own route → wrap in the seller theme scope for dark mode.
    return SellerThemeScope(
      child: Builder(
        builder: (context) {
          final c = context.sellerColors;
          final text = context.sellerText;
          return Scaffold(
            backgroundColor: c.canvas,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                          color: c.surface,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: isLoading ? null : _switchToCustomerMode,
                            child: SizedBox(
                              width: 42,
                              height: 42,
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Gap.v(AppSpace.xxl),
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: c.headerGradient,
                          borderRadius: AppRadius.brXl,
                          boxShadow: c.floatingShadow,
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      const Gap.v(AppSpace.lg),
                      Text('Seller Login', style: text.display),
                      const Gap.v(AppSpace.xs),
                      Text(
                        'Sign in to manage customers, leads, orders, '
                        'installments, and recovery from Seller Mode.',
                        style: text.bodySm,
                      ),
                      const Gap.v(AppSpace.xl),
                      _LoginField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Email is required';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const Gap.v(AppSpace.md),
                      _LoginField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: c.textTertiary,
                            size: 20,
                          ),
                        ),
                        validator: (value) => (value ?? '').isEmpty
                            ? 'Password is required'
                            : null,
                      ),
                      const Gap.v(AppSpace.xl),
                      SellerButton(
                        label: 'Login',
                        loading: isLoading,
                        onPressed: isLoading ? null : _submit,
                      ),
                      const Gap.v(AppSpace.sm),
                      SellerButton.secondary(
                        label: 'Switch to Customer Mode',
                        icon: Icons.shopping_bag_outlined,
                        onPressed: isLoading ? null : _switchToCustomerMode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _LoginField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.label),
        const Gap.v(AppSpace.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: text.body,
          cursorColor: c.accent,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: c.textTertiary, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: c.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.md,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: c.accent, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: c.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: c.danger, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
