import 'package:atompro/core/services/snackbar_services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:atompro/features/auth/repository/auth_repo.dart';
import 'package:atompro/core/auth/session_manager.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/routes/app_route_constants.dart';
part 'auth_viewmodel.g.dart';

@riverpod
class AuthViewModel extends _$AuthViewModel {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  // ── LOGIN ──────────────────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .login(email, password);
      if (response['success'] == true) {
        final data = response['data'];
        if (data['email_verified'] == true) {
          await SessionManager.saveUserSession(
            token: data['token'].toString(),
            userId: data['user']['id'].toString(),
            username: data['user']['name'].toString(),
            userUuid: data['user']['uuid'].toString(),
          );
          state = const AsyncValue.data(null);
          AppNavigator.clearStackAndPush(AppRoutes.homePage);
          SnackbarService().showSuccessSnackBar('Welcome back!');
        } else {
          state = const AsyncValue.data(null);
          AppNavigator.pushNamed(
            AppRoutes.verifyOTP,
            arguments: {'email': email, 'user_id': data['user_id'].toString()},
          );
        }
      } else {
        final msg = response['message'] ?? 'Login failed. Please try again.';
        state = AsyncValue.error(msg, StackTrace.current);
        SnackbarService().showErrorSnackBar(msg.toString());
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      SnackbarService().showErrorSnackBar(
        'Something went wrong. Please try again.',
      );
    }
  }

  // ── SIGNUP ─────────────────────────────────────────────────────────────────
  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .signup(name: name, email: email, password: password);
      if (response['success'] == true) {
        state = const AsyncValue.data(null);
        SnackbarService().showSuccessSnackBar(
          'Account created! Please verify your email.',
        );
        AppNavigator.pushNamed(
          AppRoutes.verifyOTP,
          arguments: {
            'email': email,
            'user_id': response['data']['user_id'].toString(),
          },
        );
      } else {
        final msg =
            response['data']?['email']?[0] ??
            'Signup failed. Please try again.';
        state = AsyncValue.error(msg, StackTrace.current);
        SnackbarService().showErrorSnackBar(msg.toString());
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      SnackbarService().showErrorSnackBar(
        'Something went wrong. Please try again.',
      );
    }
  }

  // ── OTP VERIFICATION (signup) ──────────────────────────────────────────────
  Future<void> verifyOtp(String userId, String code) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .verifyOtp(userId, code);
      if (response['success'] == true) {
        state = const AsyncValue.data(null);
        SnackbarService().showSuccessSnackBar(
          'Email verified! You can now log in.',
        );
        AppNavigator.clearStackAndPush(AppRoutes.authpage);
      } else {
        final msg = response['message'] ?? 'Invalid code. Please try again.';
        state = AsyncValue.error(msg, StackTrace.current);
        SnackbarService().showErrorSnackBar(msg.toString());
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      SnackbarService().showErrorSnackBar(
        'Something went wrong. Please try again.',
      );
    }
  }

  // ── RESEND OTP (signup) ────────────────────────────────────────────────────
  Future<void> resendOtp(String email) async {
    try {
      await ref.read(authRepositoryProvider).resendOtp(email);
      SnackbarService().showSuccessSnackBar(
        'Verification code resent to $email',
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      SnackbarService().showErrorSnackBar(
        'Failed to resend code. Please try again.',
      );
    }
  }

  // ── FORGOT — STEP 1: Send OTP ──────────────────────────────────────────────
  /// Returns uuid on success so the view can move to the next step.
  Future<String> sendForgotPasswordOtp(String email) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .sendForgotPasswordOtp(email);
      if (response['success'] == true) {
        final uuid = response['message']['user']['uuid'] as String;
        state = const AsyncValue.data(null);
        SnackbarService().showSuccessSnackBar('Reset code sent to $email');
        return uuid;
      } else {
        final msg = response['message'] ?? 'No account found with this email.';
        state = AsyncValue.error(msg, StackTrace.current);
        SnackbarService().showErrorSnackBar(msg.toString());
        throw msg;
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      SnackbarService().showErrorSnackBar(
        e.toString().contains('No account')
            ? e.toString()
            : 'Failed to send reset code. Please try again.',
      );
      rethrow;
    }
  }

  // ── FORGOT — STEP 2: Verify OTP ───────────────────────────────────────────
  Future<void> verifyForgotPasswordOtp(String uuid, String code) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .verifyForgotPasswordOtp(uuid, code);
      if (response['success'] == true) {
        state = const AsyncValue.data(null);
        SnackbarService().showSuccessSnackBar('Code verified successfully!');
      } else {
        final msg = response['message'] ?? 'Invalid code. Please try again.';
        state = AsyncValue.error(msg, StackTrace.current);
        SnackbarService().showErrorSnackBar(msg.toString());
        throw msg;
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      SnackbarService().showErrorSnackBar(
        e.toString().contains('Invalid')
            ? e.toString()
            : 'Verification failed. Please try again.',
      );
      rethrow;
    }
  }

  // ── FORGOT — STEP 3: Set New Password ─────────────────────────────────────
  Future<void> setNewPassword({
    required String uuid,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .setNewPassword(uuid: uuid, password: password);
      if (response['success'] == true) {
        state = const AsyncValue.data(null);
        // success snackbar + navigation handled per calling context
        // (forgot flow vs change password flow — each calls setNewPassword
        //  but needs different post-success behaviour, so we just set state
        //  and let the caller decide what to do next)
      } else {
        final msg = response['message'] ?? 'Failed to reset password.';
        state = AsyncValue.error(msg, StackTrace.current);
        SnackbarService().showErrorSnackBar(msg.toString());
        throw msg;
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      SnackbarService().showErrorSnackBar(
        'Failed to update password. Please try again.',
      );
      rethrow;
    }
  }

  // ── CHANGE PASSWORD ────────────────────────────────────────────────────────
  Future<void> changePassword({
    required String uuid,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .setNewPassword(uuid: uuid, password: newPassword);
      if (response['success'] == true) {
        state = const AsyncValue.data(null);
        SnackbarService().showSuccessSnackBar('Password updated successfully!');
        AppNavigator.getBack();
      } else {
        final msg = response['message'] ?? 'Failed to update password.';
        state = AsyncValue.error(msg, StackTrace.current);
        SnackbarService().showErrorSnackBar(msg.toString());
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      SnackbarService().showErrorSnackBar(
        'Failed to update password. Please try again.',
      );
    }
  }
}
