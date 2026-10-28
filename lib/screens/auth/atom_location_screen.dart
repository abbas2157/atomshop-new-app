import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/auth/session_manager.dart';
import '../../data/atom_auth.dart';
import '../../data/atom_http.dart';
import '../../data/atom_order.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_account_providers.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../state/atom_order_providers.dart';
import '../../state/atom_session.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';
import 'atom_auth_common.dart';

/// Where should we deliver? (canvas: "City and area"). Step 3 of sign-up, or
/// the account's "City and area" / a guest's "Delivery area".
class AtomLocationScreen extends ConsumerStatefulWidget {
  const AtomLocationScreen({super.key, this.signUpStep = false});

  /// Step 3 of sign-up (else opened from the account).
  final bool signUpStep;

  @override
  ConsumerState<AtomLocationScreen> createState() => _AtomLocationScreenState();
}

class _AtomLocationScreenState extends ConsumerState<AtomLocationScreen> {
  final _search = TextEditingController();
  String _query = '';
  int? _cityId;
  int? _areaId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final city = int.tryParse(await SessionManager.getCityId() ?? '');
    final area = int.tryParse(await SessionManager.getAreaId() ?? '');
    if (!mounted || _cityId != null) return;
    setState(() {
      _cityId = city;
      _areaId = area;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // A second tap before the button repaints must not send twice.
    if (_busy) return;
    final city = _cityId, area = _areaId;
    if (city == null || area == null) {
      setState(() => _error = 'Choose your city and area.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (ref.read(atomSignedInProvider)) {
        await ref.read(atomAuthApiProvider).updateLocation(cityId: city, areaId: area);
        refreshAccount(ref);
      } else {
        // A guest's area stays on this phone (same keys a session uses).
        const storage = FlutterSecureStorage();
        await storage.write(key: 'city_id', value: '$city');
        await storage.write(key: 'area_id', value: '$area');
      }
      if (!mounted) return;
      if (widget.signUpStep) {
        AtomNav.finishAuth(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery area saved.')));
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = atomMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = ref.watch(citiesProvider);
    final area = ref.watch(appConfigProvider).value?.deliveryArea ?? '';
    final city = _cityId;

    return AuthScaffold(
      step: widget.signUpStep ? 'Step 3 of 3' : null,
      // The account was made in step 2; going back would re-enter a used code.
      showBack: !widget.signUpStep,
      bottom: AtomButton(
        label: widget.signUpStep ? 'Save and start shopping' : 'Save',
        icon: Icons.place_outlined,
        expand: true,
        loading: _busy,
        onPressed: _busy ? null : _save,
      ),
      children: [
        AuthTitle(
          title: 'Where should we deliver?',
          subtitle: Text(
            'We match you with verified sellers in your area.${area.isEmpty ? '' : ' Delivery is in $area only for now.'}',
            style: AtomText.body,
          ),
        ),
        const SizedBox(height: AtomSpace.lg),
        Text('City', style: AtomText.label),
        const SizedBox(height: AtomSpace.xs),
        AtomAsync<List<AtomPlace>>(
          value: cities,
          compactError: true,
          onRetry: () => ref.invalidate(citiesProvider),
          loading: const AtomSkeleton(width: 120, height: 42, radius: AtomRadius.pill),
          data: (list) {
            // One city today: pick it for the customer.
            if (city == null && list.length == 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _cityId == null) setState(() => _cityId = list.first.id);
              });
            }
            return Wrap(
              spacing: AtomSpace.xs,
              runSpacing: AtomSpace.xs,
              children: [
                for (final c in list)
                  AtomChoiceChip(
                    label: c.title,
                    dark: true,
                    selected: c.id == city,
                    onTap: () => setState(() {
                      if (c.id != _cityId) _areaId = null;
                      _cityId = c.id;
                    }),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AtomSpace.lg),
        Text('Area', style: AtomText.label),
        const SizedBox(height: AtomSpace.xs),
        AtomSearchField(controller: _search, hint: 'Search your area', onChanged: (q) => setState(() => _query = q)),
        const SizedBox(height: AtomSpace.sm),
        if (city == null)
          Text('Choose a city first.', style: AtomText.small)
        else
          AtomAsync<List<AtomPlace>>(
            value: ref.watch(areasProvider(city)),
            compactError: true,
            onRetry: () => ref.invalidate(areasProvider(city)),
            loading: const Column(children: [AtomSkeleton(height: 48), SizedBox(height: 8), AtomSkeleton(height: 48)]),
            data: (areas) {
              final q = _query.trim().toLowerCase();
              final shown = q.isEmpty ? areas : areas.where((a) => a.title.toLowerCase().contains(q)).toList();
              if (shown.isEmpty) return Text('No area matches "${_query.trim()}".', style: AtomText.body);
              return AtomCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < shown.length; i++) ...[
                      if (i > 0) const Divider(height: 1, color: AtomColors.line),
                      _AreaRow(place: shown[i], selected: shown[i].id == _areaId, onTap: () => setState(() => _areaId = shown[i].id)),
                    ],
                  ],
                ),
              );
            },
          ),
        AuthError(_error),
      ],
    );
  }
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.place, required this.selected, required this.onTap});

  final AtomPlace place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AtomSpace.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    place.title,
                    style: AtomText.label.copyWith(color: selected ? AtomColors.primary : AtomColors.ink, fontWeight: selected ? FontWeight.w800 : FontWeight.w600),
                  ),
                ),
                if (selected) const Icon(Icons.check_rounded, color: AtomColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
