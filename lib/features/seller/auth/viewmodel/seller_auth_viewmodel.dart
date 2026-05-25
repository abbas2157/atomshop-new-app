import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/routes/app_route_constants.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/auth/repository/seller_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerAuthViewModelProvider =
    NotifierProvider<SellerAuthViewModel, AsyncValue<void>>(
      SellerAuthViewModel.new,
    );

class SellerAuthViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(sellerAuthRepositoryProvider)
          .login(email: email, password: password);
      state = const AsyncValue.data(null);
      SnackbarService().showSuccessSnackBar('Welcome back!');
      await AppNavigator.clearStackAndPush(AppRoutes.sellerShell);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await ref.read(sellerAuthRepositoryProvider).logout();
    state = const AsyncValue.data(null);
    await AppNavigator.clearStackAndPush(AppRoutes.sellerLogin);
  }

  String _cleanError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) return 'Unable to login. Please try again.';
    return message;
  }
}
