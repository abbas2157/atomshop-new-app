// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_orders_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MyOrdersViewModel)
const myOrdersViewModelProvider = MyOrdersViewModelProvider._();

final class MyOrdersViewModelProvider
    extends $NotifierProvider<MyOrdersViewModel, AsyncValue<MyOrdersResponse>> {
  const MyOrdersViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myOrdersViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myOrdersViewModelHash();

  @$internal
  @override
  MyOrdersViewModel create() => MyOrdersViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<MyOrdersResponse> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<MyOrdersResponse>>(value),
    );
  }
}

String _$myOrdersViewModelHash() => r'e4d0692bf2eabdb086667c2dcc3ec21cfca4d2cc';

abstract class _$MyOrdersViewModel
    extends $Notifier<AsyncValue<MyOrdersResponse>> {
  AsyncValue<MyOrdersResponse> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<MyOrdersResponse>, AsyncValue<MyOrdersResponse>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<MyOrdersResponse>,
                AsyncValue<MyOrdersResponse>
              >,
              AsyncValue<MyOrdersResponse>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
