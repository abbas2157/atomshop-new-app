import 'dart:async';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/core/style/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart'; // New Package
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/features/auth/viewmodel/auth_viewmodel.dart';

class OTPVerifyScreen extends ConsumerStatefulWidget {
  final String email;
  final String userId;

  const OTPVerifyScreen({super.key, required this.email, required this.userId});

  @override
  ConsumerState<OTPVerifyScreen> createState() => _OTPVerifyScreenState();
}

class _OTPVerifyScreenState extends ConsumerState<OTPVerifyScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int _timerSeconds = 90;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerSeconds = 90);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Standard Pinput Theme
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: AppTextStyles.h4.copyWith(color: ColorPalette.secondary),
      decoration: BoxDecoration(
        color: ColorPalette.surfaceGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.border),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: ColorPalette.secondary, width: 2),
      ),
    );

    // Listen for state changes
    ref.listen(authViewModelProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          SnackbarService().showErrorSnackBar(error.toString());
        },
      );
    });

    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              IconButton(
                onPressed: () {
                  AppNavigator.getBack();
                },
                icon: Icon(Icons.arrow_back_ios),
              ).alignTopLeft,

              const SizedBox(height: 60),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildCard(authState, defaultPinTheme, focusedPinTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(
          Icons.mark_email_read_rounded,
          size: 80,
          color: ColorPalette.secondary,
        ),
        const SizedBox(height: 24),
        Text(
          'Verify Email',
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'A 4-digit code has been sent to\n${widget.email}',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: ColorPalette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    AsyncValue authState,
    PinTheme defaultTheme,
    PinTheme focusedTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Pinput(
            length: 4,
            controller: _otpController,
            focusNode: _focusNode,
            defaultPinTheme: defaultTheme,
            focusedPinTheme: focusedTheme,
            separatorBuilder: (index) => const SizedBox(width: 8),
            hapticFeedbackType: HapticFeedbackType.lightImpact,
            onCompleted: (pin) {
              ref
                  .read(authViewModelProvider.notifier)
                  .verifyOtp(widget.userId, pin);
            },
          ),
          const SizedBox(height: 32),
          CustomButton(
            title: 'Verify & Proceed',
            isLoading: authState.isLoading,
            onPressed: () {
              if (_otpController.text.length == 4) {
                ref
                    .read(authViewModelProvider.notifier)
                    .verifyOtp(widget.userId, _otpController.text);
              }
            },
          ),
          const SizedBox(height: 24),
          _buildResendSection(),
        ],
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        Text(
          _timerSeconds > 0
              ? "Resend code in ${_timerSeconds}s"
              : "Didn't receive code?",
          style: AppTextStyles.bodySmall.copyWith(
            color: ColorPalette.textSecondary,
          ),
        ),
        if (_timerSeconds == 0)
          TextButton(
            onPressed: () {
              _startTimer();
              ref.read(authViewModelProvider.notifier).resendOtp(widget.email);
            },
            child: Text(
              'Resend Now',
              style: AppTextStyles.bodySmall.copyWith(
                color: ColorPalette.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
