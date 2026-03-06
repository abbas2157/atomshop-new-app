// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_order_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(customOrderRepository)
const customOrderRepositoryProvider = CustomOrderRepositoryProvider._();

final class CustomOrderRepositoryProvider
    extends
        $FunctionalProvider<
          CustomOrderRepository,
          CustomOrderRepository,
          CustomOrderRepository
        >
    with $Provider<CustomOrderRepository> {
  const CustomOrderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customOrderRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customOrderRepositoryHash();

  @$internal
  @override
  $ProviderElement<CustomOrderRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CustomOrderRepository create(Ref ref) {
    return customOrderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomOrderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomOrderRepository>(value),
    );
  }
}

String _$customOrderRepositoryHash() =>
    r'356a6939dbd16e50100da8c06edc78494a95fa00';
