import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/atom_account.dart';
import '../../data/atom_http.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_account_providers.dart';
import '../../state/atom_order_providers.dart';
import '../../state/atom_session.dart';
import '../../utils/atom_format.dart';
import '../../utils/atom_validators.dart';
import '../../widgets/atom_city_area_fields.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';
import 'atom_custom_placed_screen.dart';
import 'atom_custom_shared.dart';

/// Custom order, step 3 (canvas: "Your details"). Guests may order; the
/// server recomputes every figure when it saves the order.
class AtomCustomDetailsScreen extends ConsumerStatefulWidget {
  const AtomCustomDetailsScreen({super.key, required this.draft, required this.quote});

  final CustomDraft draft;
  final CustomQuote quote;

  @override
  ConsumerState<AtomCustomDetailsScreen> createState() => _AtomCustomDetailsScreenState();
}

class _AtomCustomDetailsScreenState extends ConsumerState<AtomCustomDetailsScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _link = TextEditingController();
  int? _cityId;
  int? _areaId;
  String? _photo;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    ref.read(orderPrefillProvider.future).then((p) {
      if (!mounted) return;
      void fill(TextEditingController c, String v) {
        if (c.text.isEmpty && v.isNotEmpty) c.text = v;
      }

      fill(_name, p.name);
      fill(_phone, p.phone);
      fill(_email, p.email);
      fill(_address, p.address);
      if (_cityId == null && p.cityId != null) {
        setState(() {
          _cityId = p.cityId;
          _areaId = p.areaId;
        });
      }
    }).ignore();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (file != null && mounted) setState(() => _photo = file.path);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open your photos.')));
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    final d = widget.draft;
    final phone = _phone.text.trim();
    setState(() => _sending = true);
    try {
      final placed = await ref.read(atomAccountApiProvider).placeCustomOrder(
        {
          'product_title': d.title,
          if (_link.text.trim().isNotEmpty) 'product_link': _link.text.trim(),
          'price': d.price,
          'advance': d.advance,
          'months': d.months,
          if (d.referenceCode.isNotEmpty) 'reference_code': d.referenceCode,
          'full_name': _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
          'phone': phone,
          if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
          'city_id': _cityId,
          'area_id': _areaId,
          'address': _address.text.trim(),
        },
        photos: [?_photo],
      );
      if (!mounted) return;
      refreshAccount(ref);
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AtomCustomPlacedScreen(placed: placed, phone: phone)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(atomMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(atomSignedInProvider);
    final q = widget.quote;

    return Form(
      key: _form,
      child: AtomPage(
        title: 'Your details',
        bottom: AtomButton(label: 'Submit custom order', icon: Icons.send_rounded, expand: true, loading: _sending, onPressed: _sending ? null : _submit),
        children: [
          const SizedBox(height: AtomSpace.xs),
          const CustomSteps(current: 3),
          const SizedBox(height: AtomSpace.md),
          if (!signedIn) ...[
            AtomLinkCard(
              icon: Icons.login_rounded,
              title: 'Ordering as a guest',
              message: 'Have an account? Sign in',
              onTap: () => AtomNav.signIn(context),
            ),
            const SizedBox(height: AtomSpace.sm),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(child: Text('${widget.draft.title} · ${q.months} months', style: AtomText.label)),
                Text.rich(TextSpan(children: [
                  TextSpan(text: AtomFormat.rupees(q.monthly), style: AtomText.label.copyWith(color: AtomColors.primary, fontWeight: FontWeight.w800)),
                  TextSpan(text: '/mo', style: AtomText.small),
                ])),
              ],
            ),
          ),
          const SizedBox(height: AtomSpace.md),
          AtomTextField(
            label: 'Full name',
            controller: _name,
            hint: 'As on your CNIC',
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
            validator: validatePersonName,
          ),
          const SizedBox(height: 14),
          AtomTextField(
            label: 'Phone number',
            controller: _phone,
            hint: '03xx xxxxxxx',
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')), LengthLimitingTextInputFormatter(20)],
            validator: validatePhone,
          ),
          const SizedBox(height: 14),
          AtomTextField(
            label: 'Email',
            optional: true,
            controller: _email,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: validateOptionalEmail,
          ),
          const SizedBox(height: 14),
          AtomCityAreaFields(
            cityId: _cityId,
            areaId: _areaId,
            onCity: (id) => setState(() {
              if (id != _cityId) _areaId = null;
              _cityId = id;
            }),
            onArea: (id) => setState(() => _areaId = id),
          ),
          const SizedBox(height: 14),
          AtomTextField(
            label: 'Delivery address',
            controller: _address,
            hint: 'House, street and block',
            maxLines: 2,
            autofillHints: const [AutofillHints.fullStreetAddress],
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return 'Enter your delivery address.';
              if (t.length > 500) return 'Keep the address under 500 characters.';
              return null;
            },
          ),
          const SizedBox(height: 14),
          AtomTextField(
            label: 'Product link',
            optional: true,
            controller: _link,
            hint: 'https://…',
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return null;
              final uri = Uri.tryParse(t);
              return uri != null && uri.hasScheme && uri.host.isNotEmpty ? null : 'Enter a full link, starting with https://';
            },
          ),
          const SizedBox(height: 14),
          Text.rich(TextSpan(text: 'Product photo', style: AtomText.label, children: [
            TextSpan(text: ' (optional)', style: AtomText.body.copyWith(fontSize: 13, color: AtomColors.muted)),
          ])),
          const SizedBox(height: 6),
          _photo == null
              ? AtomCard(
                  onTap: _pickPhoto,
                  borderColor: AtomColors.line2,
                  child: Row(
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, color: AtomColors.primary),
                      const SizedBox(width: AtomSpace.sm),
                      Text('Add a photo', style: AtomText.label.copyWith(color: AtomColors.primary)),
                    ],
                  ),
                )
              : Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(File(_photo!), width: 72, height: 72, fit: BoxFit.cover, cacheWidth: 216),
                    ),
                    const SizedBox(width: AtomSpace.sm),
                    AtomButton(
                      label: 'Remove',
                      icon: Icons.delete_outline_rounded,
                      variant: AtomButtonVariant.secondary,
                      size: AtomButtonSize.small,
                      onPressed: () => setState(() => _photo = null),
                    ),
                  ],
                ),
          const SizedBox(height: AtomSpace.md),
          const AtomNotice(icon: Icons.verified_user_outlined, text: 'Sent to verified sellers in your area. Not available with AtomPay.'),
        ],
      ),
    );
  }
}
