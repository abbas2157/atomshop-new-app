// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city_area_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CityAreaViewModel)
const cityAreaViewModelProvider = CityAreaViewModelProvider._();

final class CityAreaViewModelProvider
    extends $NotifierProvider<CityAreaViewModel, CityAreaState> {
  const CityAreaViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cityAreaViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cityAreaViewModelHash();

  @$internal
  @override
  CityAreaViewModel create() => CityAreaViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CityAreaState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CityAreaState>(value),
    );
  }
}

String _$cityAreaViewModelHash() => r'932ba18f0b148775e9b02b58c1c516e2affe65aa';

abstract class _$CityAreaViewModel extends $Notifier<CityAreaState> {
  CityAreaState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CityAreaState, CityAreaState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CityAreaState, CityAreaState>,
              CityAreaState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
