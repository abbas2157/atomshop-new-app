// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_seller_repo.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(smartSellerRepo)
const smartSellerRepoProvider = SmartSellerRepoProvider._();

final class SmartSellerRepoProvider
    extends
        $FunctionalProvider<SmartSellerRepo, SmartSellerRepo, SmartSellerRepo>
    with $Provider<SmartSellerRepo> {
  const SmartSellerRepoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartSellerRepoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartSellerRepoHash();

  @$internal
  @override
  $ProviderElement<SmartSellerRepo> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SmartSellerRepo create(Ref ref) {
    return smartSellerRepo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SmartSellerRepo value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SmartSellerRepo>(value),
    );
  }
}

String _$smartSellerRepoHash() => r'e3f266dd774e05eac8fb98f110d4d1963fa2cce2';
