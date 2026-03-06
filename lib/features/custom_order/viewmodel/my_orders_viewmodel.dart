import 'dart:async';
import 'package:atompro/core/auth/session_manager.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/custom_order/model/my_order_model.dart';
import 'package:atompro/features/custom_order/repository/custom_order_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_orders_viewmodel.g.dart';

@riverpod
class MyOrdersViewModel extends _$MyOrdersViewModel {
  @override
  AsyncValue<MyOrdersResponse> build() {
    fetchOrders();
    return const AsyncValue.loading();
  }

  Future<void> fetchOrders() async {
    state = const AsyncValue.loading();
    try {
      final response = await ref
          .read(customOrderRepositoryProvider)
          .getmyorder();
      print("My Orders API response: $response");

      if (response['success'] == true) {
        final data = MyOrdersResponse.fromJson(
          response as Map<String, dynamic>,
        );
        state = AsyncValue.data(data);
      } else {
        final msg = response['message'] ?? 'Failed to load orders.';
        state = AsyncValue.error(msg, StackTrace.current);
        SnackbarService().showErrorSnackBar(msg.toString());
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      SnackbarService().showErrorSnackBar(
        'Failed to load orders. Please try again.',
      );
    }
  }
}
