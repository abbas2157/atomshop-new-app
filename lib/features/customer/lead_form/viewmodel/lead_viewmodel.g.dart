// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LeadViewModel)
const leadViewModelProvider = LeadViewModelProvider._();

final class LeadViewModelProvider
    extends $NotifierProvider<LeadViewModel, LeadState> {
  const LeadViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadViewModelHash();

  @$internal
  @override
  LeadViewModel create() => LeadViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadState>(value),
    );
  }
}

String _$leadViewModelHash() => r'913e2f7b44296adc7f01ef7fe6c70f0af72929ca';

abstract class _$LeadViewModel extends $Notifier<LeadState> {
  LeadState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<LeadState, LeadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeadState, LeadState>,
              LeadState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
