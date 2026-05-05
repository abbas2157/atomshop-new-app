// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city_area_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cityAreaRepository)
const cityAreaRepositoryProvider = CityAreaRepositoryProvider._();

final class CityAreaRepositoryProvider
    extends
        $FunctionalProvider<
          CityAreaRepository,
          CityAreaRepository,
          CityAreaRepository
        >
    with $Provider<CityAreaRepository> {
  const CityAreaRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cityAreaRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cityAreaRepositoryHash();

  @$internal
  @override
  $ProviderElement<CityAreaRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CityAreaRepository create(Ref ref) {
    return cityAreaRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CityAreaRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CityAreaRepository>(value),
    );
  }
}

String _$cityAreaRepositoryHash() =>
    r'fed72cfbd998c06f6de1ccacf9eec860b773da62';
