// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_form_repo.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(leadFormRepo)
const leadFormRepoProvider = LeadFormRepoProvider._();

final class LeadFormRepoProvider
    extends $FunctionalProvider<LeadFormRepo, LeadFormRepo, LeadFormRepo>
    with $Provider<LeadFormRepo> {
  const LeadFormRepoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadFormRepoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadFormRepoHash();

  @$internal
  @override
  $ProviderElement<LeadFormRepo> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LeadFormRepo create(Ref ref) {
    return leadFormRepo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadFormRepo value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadFormRepo>(value),
    );
  }
}

String _$leadFormRepoHash() => r'ab7ba8e642c12ba4efcefa201d739bd061778bd8';
