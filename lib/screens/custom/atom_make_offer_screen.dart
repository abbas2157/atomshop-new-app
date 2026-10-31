import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/atom_http.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_account_providers.dart';
import '../../state/atom_order_providers.dart';
import '../../state/atom_outbox.dart';
import '../../state/atom_session.dart';
import '../../utils/atom_validators.dart';
import '../../widgets/atom_leave_guard.dart';
import '../../widgets/atom_city_area_fields.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_photo_hero.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';
import '../account/atom_custom_orders_screen.dart';
import '../account/atom_outbox_screen.dart';

/// Make an offer (canvas: "Make an offer"): not sure of the price? Tell us
/// what you want and a seller on Atomshop calls you. Saved as a lead; guests
/// welcome.
class AtomMakeOfferScreen extends ConsumerStatefulWidget {
  const AtomMakeOfferScreen({super.key});

  @override
  ConsumerState<AtomMakeOfferScreen> createState() => _AtomMakeOfferScreenState();
}

class _AtomMakeOfferScreenState extends ConsumerState<AtomMakeOfferScreen> {
  static const _maxPhotos = 5;

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _product = TextEditingController();
  final _phone = TextEditingController();
  int? _cityId;
  int? _areaId;
  bool _whatsApp = true;
  final List<String> _photos = [];
  bool _sending = false;

  /// Edited and not sent yet: leaving asks first.
  bool _dirty = false;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  bool _sent = false;

  /// Saved on the phone (offline) rather than sent.
  bool _queued = false;

  @override
  void initState() {
    super.initState();
    ref.read(orderPrefillProvider.future).then((p) {
      if (!mounted) return;
      if (_name.text.isEmpty) _name.text = p.name;
      if (_phone.text.isEmpty) _phone.text = p.phone;
      if (_cityId == null && p.cityId != null) {
        setState(() {
          _cityId = p.cityId;
          _areaId = p.areaId;
        });
      }
      // Filling in from the account is not the customer typing.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _dirty) setState(() => _dirty = false);
      });
    }).ignore();
  }

  @override
  void dispose() {
    _name.dispose();
    _product.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    try {
      final files = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 85, limit: _maxPhotos - _photos.length);
      if (!mounted || files.isEmpty) return;
      setState(() => _photos.addAll(files.map((f) => f.path).take(_maxPhotos - _photos.length)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open your photos.')));
    }
  }

  Future<void> _submit() async {
    // A second tap before the button repaints must not send twice.
    if (_sending) return;
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      // Offline, the offer is kept on the phone and sent once back online.
      final r = await ref.read(outboxProvider.notifier).submit(
        OutboxKind.offer,
        {
          'full_name': _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
          'phone': _phone.text.trim(),
          'city_id': _cityId!,
          'area_id': _areaId,
          'product': _product.text.trim(),
          'on_whatsapp': _whatsApp,
        },
        files: List.of(_photos),
      );
      if (!mounted) return;
      ref.invalidate(offersProvider);
      setState(() {
        _sending = false;
        _sent = true;
        _queued = r.queued;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(atomMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) return _Sent(signedIn: ref.watch(atomSignedInProvider), queued: _queued);

    return AtomLeaveGuard(
      dirty: _dirty,
      child: Form(
        key: _form,
        onChanged: _markDirty,
        child: AtomPage(
          title: 'Make an offer',
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AtomButton(label: 'Submit request', icon: Icons.send_rounded, expand: true, loading: _sending, onPressed: _sending ? null : _submit),
              const SizedBox(height: AtomSpace.xs),
              Text(
                'A seller contacts you to confirm the price and plan.',
                textAlign: TextAlign.center,
                style: AtomText.small.copyWith(color: AtomColors.body),
              ),
            ],
          ),
          hero: const AtomPhotoHero(
            asset: 'assets/images/slide-verified-sellers.jpg',
            alt: 'Sellers reviewing a request on a tablet',
            eyebrow: 'Make an offer',
            title: 'Tell us what you want. A seller calls you.',
            height: 230,
          ),
          children: [
            Row(
              children: [
                for (final (i, text) in const [(1, 'Choose any product'), (2, 'Send this form'), (3, 'Get it at home')]) ...[
                  if (i > 1) const SizedBox(width: AtomSpace.xs),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: AtomColors.primary, shape: BoxShape.circle),
                            child: Text(
                              '$i',
                              style: AtomText.small.copyWith(color: AtomColors.white, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            text,
                            style: AtomText.small.copyWith(color: AtomColors.ink, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AtomSpace.md),
            AtomTextField(
              label: 'Full name',
              controller: _name,
              hint: 'Enter your full name',
              autofillHints: const [AutofillHints.name],
              textCapitalization: TextCapitalization.words,
              validator: validatePersonName,
            ),
            const SizedBox(height: 14),
            AtomTextField(
              label: 'Product',
              controller: _product,
              hint: 'e.g. iPhone 15 Pro Max',
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(255)],
              validator: (v) => (v ?? '').trim().isEmpty ? 'Tell us which product you want.' : null,
            ),
            const SizedBox(height: 14),
            AtomCityAreaFields(
              cityId: _cityId,
              areaId: _areaId,
              areaRequired: false,
              onCity: (id) => setState(() {
                if (id != _cityId) _areaId = null;
                _cityId = id;
              }),
              onArea: (id) => setState(() => _areaId = id),
            ),
            const SizedBox(height: 14),
            AtomTextField(
              label: 'Contact number',
              controller: _phone,
              hint: '03001234567',
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')), LengthLimitingTextInputFormatter(20)],
              validator: validatePhone,
            ),
            const SizedBox(height: AtomSpace.sm),
            Container(
              decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                value: _whatsApp,
                onChanged: (v) => setState(() => _whatsApp = v),
                title: Text('This number is on WhatsApp', style: AtomText.label),
                activeThumbColor: AtomColors.white,
                activeTrackColor: AtomColors.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 14),
            if (_photos.isNotEmpty) ...[
              Wrap(
                spacing: AtomSpace.xs,
                runSpacing: AtomSpace.xs,
                children: [
                  for (final (i, path) in _photos.indexed)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(File(path), width: 72, height: 72, fit: BoxFit.cover, cacheWidth: 216),
                        ),
                        Positioned(
                          top: -10,
                          right: -10,
                          child: IconButton.filled(
                            tooltip: 'Remove photo ${i + 1}',
                            iconSize: 16,
                            style: IconButton.styleFrom(backgroundColor: AtomColors.ink, minimumSize: const Size(32, 32)),
                            icon: const Icon(Icons.close_rounded, color: AtomColors.white),
                            onPressed: () => setState(() => _photos.removeAt(i)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AtomSpace.xs),
            ],
            if (_photos.length < _maxPhotos)
              AtomCard(
                onTap: _addPhotos,
                borderColor: AtomColors.line2,
                child: Row(
                  children: [
                    const Icon(Icons.upload_rounded, color: AtomColors.primary),
                    const SizedBox(width: AtomSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add product photos', style: AtomText.label.copyWith(color: AtomColors.primary)),
                          Text('PNG, JPG or JPEG. You can add up to $_maxPhotos.', style: AtomText.small),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Sent extends ConsumerWidget {
  const _Sent({required this.signedIn, required this.queued});

  final bool signedIn;

  /// Kept on the phone until the connection is back.
  final bool queued;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: AtomPageWidth(
          child: ListView(
            padding: EdgeInsets.fromLTRB(context.atomGutter, AtomSpace.xl + AtomSpace.md, context.atomGutter, AtomSpace.lg),
            children: [
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(color: queued ? AtomColors.amberSoft : AtomColors.greenSoft, shape: BoxShape.circle),
                  child: Icon(queued ? Icons.schedule_send_rounded : Icons.check_rounded, size: 44, color: queued ? AtomColors.amberInk : AtomColors.green),
                ),
              ),
              const SizedBox(height: 14),
              Semantics(
                header: true,
                child: Text(queued ? 'Request saved' : 'Request sent', textAlign: TextAlign.center, style: AtomText.title.copyWith(fontSize: 26)),
              ),
              const SizedBox(height: AtomSpace.xs),
              Text(
                queued
                    ? "You're offline, so your request is saved on this phone. It is sent as soon as you're back online, then a seller in your area contacts you."
                    : 'A seller in your area contacts you to confirm the price and plan.',
                textAlign: TextAlign.center,
                style: AtomText.body.copyWith(fontSize: 15),
              ),
              const SizedBox(height: AtomSpace.xl),
              if (queued) ...[
                AtomButton(
                  label: 'See what is waiting to send',
                  icon: Icons.schedule_send_rounded,
                  expand: true,
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AtomOutboxScreen())),
                ),
                const SizedBox(height: 10),
              ] else if (signedIn) ...[
                AtomButton(
                  label: 'Track my offers',
                  icon: Icons.chat_bubble_outline_rounded,
                  expand: true,
                  // Replaces this screen, so back from the list doesn't return here.
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AtomCustomOrdersScreen(showOffers: true))),
                ),
                const SizedBox(height: 10),
              ],
              AtomButton(
                label: 'Keep shopping',
                icon: Icons.shopping_bag_outlined,
                expand: true,
                variant: signedIn || queued ? AtomButtonVariant.text : AtomButtonVariant.primary,
                onPressed: () => AtomNav.toTab(context, ref, AtomTab.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
