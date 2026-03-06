// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_repo.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supplierRepo)
const supplierRepoProvider = SupplierRepoProvider._();

final class SupplierRepoProvider
    extends $FunctionalProvider<SupplierRepo, SupplierRepo, SupplierRepo>
    with $Provider<SupplierRepo> {
  const SupplierRepoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supplierRepoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supplierRepoHash();

  @$internal
  @override
  $ProviderElement<SupplierRepo> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupplierRepo create(Ref ref) {
    return supplierRepo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupplierRepo value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupplierRepo>(value),
    );
  }
}

String _$supplierRepoHash() => r'c18fd4b7a0b738bd2f88159da0f3f68e884e48e5';
