import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/session_manager.dart';
import '../../data/atom_auth.dart';
import '../../data/atom_http.dart';
import '../../data/atom_order.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_delivery_area.dart';
import '../../state/atom_account_providers.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../state/atom_order_providers.dart';
import '../../state/atom_outbox.dart';
import '../../state/atom_session.dart';
import '../../widgets/atom_select_field.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_states.dart';
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
  final _address = TextEditingController();
  final _phone = TextEditingController();

  /// The account endpoint saves the area together with an address and a
  /// mobile number, so signed-in customers give those here too.
  bool _needsPhone = false;
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
    final address = await SessionManager.getAddress() ?? '';
    final phone = await SessionManager.getPhone() ?? '';
    if (!mounted) return;
    setState(() {
      if (_address.text.isEmpty) _address.text = address;
      _needsPhone = phone.isEmpty && AtomAuthApi.pendingPhone.isEmpty;
      if (_cityId != null) return;
      _cityId = city;
      _areaId = area;
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
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
    final signedIn = ref.read(atomSignedInProvider);
    if (signedIn && _address.text.trim().length < 5) {
      setState(() => _error = 'Enter your home address.');
      return;
    }
    if (signedIn && _needsPhone && validatePhone(_phone.text) != null) {
      setState(() => _error = validatePhone(_phone.text));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String title(List<AtomPlace>? list, int id) => list?.where((p) => p.id == id).firstOrNull?.title ?? '';
    final cityTitle = title(ref.read(citiesProvider).value, city);
    final areaTitle = title(ref.read(areasProvider(city)).value, area);
    var queued = false;
    try {
      if (signedIn) {
        // Offline, the change is kept on the phone and sent once back online.
        final address = _address.text.trim();
        final r = await ref.read(outboxProvider.notifier).submit(OutboxKind.location, {
          'city_id': city,
          'area_id': area,
          'address': address,
          'phone': _phone.text.trim(),
        });
        queued = r.queued;
        if (queued) {
          await ref.read(atomAuthApiProvider).keepLocally(address: address, city: AtomRef(city, cityTitle), area: AtomRef(area, areaTitle));
        }
        refreshAccount(ref);
      }
      // Kept on this phone with the names, so Home can say where we deliver.
      await ref.read(deliveryAreaProvider.notifier).save(DeliveryArea(cityId: city, cityTitle: cityTitle, areaId: area, areaTitle: areaTitle));
      if (!mounted) return;
      if (widget.signUpStep) {
        AtomNav.finishAuth(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(queued ? "You're offline. Your area is saved on this phone and sent when you're back online." : 'Delivery area saved.'),
        ));
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
            // A searchable list, like every select in the app.
            return AtomSelectField<AtomPlace>(
              title: 'Choose your city',
              searchHint: 'Search cities',
              hint: 'Select city',
              options: list,
              label: (c) => c.title,
              selected: list.where((c) => c.id == city).firstOrNull,
              onChanged: (c) => setState(() {
                if (c.id != _cityId) _areaId = null;
                _cityId = c.id;
              }),
            );
          },
        ),
        const SizedBox(height: AtomSpace.lg),
        Text('Area', style: AtomText.label),
        const SizedBox(height: AtomSpace.xs),
        // A searchable select like the city (Lahore alone has hundreds of
        // areas), so the fields below stay in view.
        if (city == null)
          Text('Choose a city first.', style: AtomText.small)
        else
          AtomAsync<List<AtomPlace>>(
            value: ref.watch(areasProvider(city)),
            compactError: true,
            onRetry: () => ref.invalidate(areasProvider(city)),
            loading: const AtomSkeleton(height: 50, radius: AtomRadius.input),
            data: (areas) => AtomSelectField<AtomPlace>(
              title: 'Choose your area',
              searchHint: 'Search your area',
              hint: 'Select area',
              options: areas,
              label: (a) => a.title,
              selected: areas.where((a) => a.id == _areaId).firstOrNull,
              onChanged: (a) => setState(() => _areaId = a.id),
            ),
          ),
        if (ref.watch(atomSignedInProvider)) ...[
          const SizedBox(height: AtomSpace.lg),
          AtomTextField(label: 'Home address', controller: _address, hint: 'House, street and block', maxLines: 2),
          if (_needsPhone) ...[
            const SizedBox(height: 14),
            AtomTextField(label: 'Mobile number', controller: _phone, hint: '03001234567', keyboardType: TextInputType.phone),
          ],
        ],
        AuthError(_error),
      ],
    );
  }
}
