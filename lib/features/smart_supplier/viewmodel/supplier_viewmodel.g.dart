// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SupplierViewmodel)
const supplierViewmodelProvider = SupplierViewmodelProvider._();

final class SupplierViewmodelProvider
    extends $NotifierProvider<SupplierViewmodel, SupplierState> {
  const SupplierViewmodelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supplierViewmodelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supplierViewmodelHash();

  @$internal
  @override
  SupplierViewmodel create() => SupplierViewmodel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupplierState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupplierState>(value),
    );
  }
}

String _$supplierViewmodelHash() => r'6b8c2bd25072fe8c8f71c4d67ecff369d5336b34';

abstract class _$SupplierViewmodel extends $Notifier<SupplierState> {
  SupplierState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SupplierState, SupplierState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SupplierState, SupplierState>,
              SupplierState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
