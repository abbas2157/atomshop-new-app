// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_seller_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SmartSellerViewmodel)
const smartSellerViewmodelProvider = SmartSellerViewmodelProvider._();

final class SmartSellerViewmodelProvider
    extends $NotifierProvider<SmartSellerViewmodel, SmartSellerState> {
  const SmartSellerViewmodelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartSellerViewmodelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartSellerViewmodelHash();

  @$internal
  @override
  SmartSellerViewmodel create() => SmartSellerViewmodel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SmartSellerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SmartSellerState>(value),
    );
  }
}

String _$smartSellerViewmodelHash() =>
    r'da1209de428577a4f78bd6e0c825b9cd02b8180d';

abstract class _$SmartSellerViewmodel extends $Notifier<SmartSellerState> {
  SmartSellerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SmartSellerState, SmartSellerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SmartSellerState, SmartSellerState>,
              SmartSellerState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
