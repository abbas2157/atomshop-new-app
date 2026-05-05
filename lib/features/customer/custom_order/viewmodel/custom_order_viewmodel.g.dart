// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_order_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CustomOrderViewModel)
const customOrderViewModelProvider = CustomOrderViewModelProvider._();

final class CustomOrderViewModelProvider
    extends $NotifierProvider<CustomOrderViewModel, CustomOrderState> {
  const CustomOrderViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customOrderViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customOrderViewModelHash();

  @$internal
  @override
  CustomOrderViewModel create() => CustomOrderViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomOrderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomOrderState>(value),
    );
  }
}

String _$customOrderViewModelHash() =>
    r'1e3d3ffe95a170645361bf8eda16593a8e5bfcf3';

abstract class _$CustomOrderViewModel extends $Notifier<CustomOrderState> {
  CustomOrderState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CustomOrderState, CustomOrderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CustomOrderState, CustomOrderState>,
              CustomOrderState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
