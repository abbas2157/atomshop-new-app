import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_http.dart';
import '../../data/atom_order.dart';
import '../../data/atom_product_detail.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../state/atom_order_providers.dart';
import '../../state/atom_session.dart';
import '../../utils/atom_format.dart';
import '../../utils/atom_validators.dart';
import '../../widgets/atom_leave_guard.dart';
import '../../widgets/atom_city_area_fields.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_network_image.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';

/// Step 2 of ordering (canvas: "Place order"): delivery details. Guests
/// order without an account, as on the website; a signed-in customer's
/// details are filled in. The server prices the order; this screen only
/// shows the figures the product page looked up.
class AtomOrderScreen extends ConsumerStatefulWidget {
  const AtomOrderScreen({super.key, required this.choice});

  final ProductOrderChoice choice;

  @override
  ConsumerState<AtomOrderScreen> createState() => _AtomOrderScreenState();
}

class _AtomOrderScreenState extends ConsumerState<AtomOrderScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  int? _cityId;
  int? _areaId;
  bool _sending = false;

  /// Edited and not sent yet: leaving asks first.
  bool _dirty = false;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  /// One id for this order form, sent with every attempt.
  final String _requestId = atomRequestId();

  @override
  void initState() {
    super.initState();
    // Fill what a signed-in customer already gave us, without overwriting
    // anything typed meanwhile.
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
      // Filling in from the account is not the customer typing.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _dirty) setState(() => _dirty = false);
      });
    }).ignore();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // A second tap before the button repaints must not send twice.
    if (_sending) return;
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;

    setState(() => _sending = true);
    try {
      final receipt = await ref
          .read(atomOrderApiProvider)
          .place(
            requestId: _requestId,
            widget.choice,
            OrderContact(
              fullName: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
              phone: _phone.text.trim(),
              email: _email.text.trim(),
              cityId: _cityId!,
              areaId: _areaId!,
              address: _address.text.trim(),
            ),
          );
      if (!mounted) return;
      AtomNav.orderPlaced(context, receipt);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(atomErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final signedIn = ref.watch(atomSignedInProvider);
    final area = ref.watch(appConfigProvider).value?.deliveryArea ?? '';
    final mode = widget.choice.mode;

    final (title, cta) = switch (mode) {
      PayMode.installment => ('Order on installments', 'Place installment order'),
      PayMode.atompay => ('Buy with AtomPay', 'Place AtomPay order'),
      PayMode.cash => ('Buy now', 'Place order'),
    };
    final notice = mode == PayMode.atompay
        ? 'AtomPay reviews and approves this order. Next you complete your AtomPay profile with the same phone number.'
        : 'Sent to verified sellers in your area. The seller calls you to confirm ${mode == PayMode.cash ? 'the order' : 'the plan'} before any payment.';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: AtomLeaveGuard(
            dirty: _dirty,
            child: Form(
              key: _form,
              onChanged: _markDirty,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, AtomSpace.sm),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AtomColors.line)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
                              const SizedBox(width: AtomSpace.sm),
                              Expanded(
                                child: Semantics(header: true, child: Text(title, style: AtomText.heading.copyWith(fontSize: 20))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const _Steps(current: 2),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(gutter, AtomSpace.md, gutter, AtomSpace.lg),
                    sliver: SliverList.list(
                      children: [
                        _Summary(choice: widget.choice),
                        if (!signedIn) ...[
                          const SizedBox(height: AtomSpace.sm),
                          AtomLinkCard(
                            icon: Icons.login_rounded,
                            title: 'Ordering as a guest',
                            message: 'Have an account? Sign in',
                            onTap: () => AtomNav.signIn(context),
                          ),
                        ],
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
                        if (area.isNotEmpty) ...[const SizedBox(height: 6), Text('Delivery in $area only', style: AtomText.small)],
                        const SizedBox(height: 14),
                        AtomTextField(
                          label: 'Delivery address',
                          controller: _address,
                          hint: 'House, street and block',
                          maxLines: 2,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.fullStreetAddress],
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'Enter your delivery address.';
                            if (t.length > 500) return 'Keep the address under 500 characters.';
                            return null;
                          },
                        ),
                        const SizedBox(height: AtomSpace.md),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AtomColors.primarySoft, borderRadius: BorderRadius.circular(18)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.verified_user_outlined, size: 20, color: AtomColors.primary),
                              const SizedBox(width: AtomSpace.sm),
                              Expanded(
                                child: Text(notice, style: AtomText.body.copyWith(fontSize: 13, color: AtomColors.primaryDark)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AtomColors.white,
          border: Border(top: BorderSide(color: AtomColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: AtomPageWidth(
            child: Padding(
              padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, AtomSpace.sm),
              child: AtomButton(label: cta, icon: Icons.send_rounded, expand: true, loading: _sending, onPressed: _sending ? null : _submit),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plan · Your details · Done.
class _Steps extends StatelessWidget {
  const _Steps({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    Widget step(int n, String label) {
      final done = n < current;
      final on = n == current;
      final color = done ? AtomColors.green : (on ? AtomColors.primary : AtomColors.muted);
      return Semantics(
        label:
            '$label${done
                ? ', done'
                : on
                ? ', current step'
                : ''}',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done || on ? color : null,
                shape: BoxShape.circle,
                border: done || on ? null : Border.all(color: AtomColors.line2, width: 1.5),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 13, color: AtomColors.white)
                  : Text(
                      '$n',
                      style: AtomText.small.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: on ? AtomColors.white : AtomColors.muted),
                    ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AtomText.small.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    Widget line(bool done) => Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: AtomSpace.xs),
        decoration: BoxDecoration(color: done ? AtomColors.green : AtomColors.line, borderRadius: BorderRadius.circular(2)),
      ),
    );

    return Row(children: [step(1, 'Plan'), line(current > 1), step(2, 'Your details'), line(current > 2), step(3, 'Done')]);
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.choice});

  final ProductOrderChoice choice;

  @override
  Widget build(BuildContext context) {
    final p = choice.product;
    final title = [p.title, if (choice.storage != null && p.storages.length > 1) choice.storage!.title].join(' · ');
    final quote = choice.quote;
    final atompay = choice.atompay;

    final (detail, left, right) = switch (choice.mode) {
      PayMode.installment => (
        [if (choice.colour != null) choice.colour!.title, '${quote?.months} months', '${quote?.advancePercent}% advance'].join(' · '),
        ('Advance', quote?.advance),
        quote?.monthly,
      ),
      PayMode.atompay => (
        [if (choice.colour != null) choice.colour!.title, 'AtomPay', '${atompay?.months} months', 'no advance'].join(' · '),
        ('Total', atompay?.total),
        atompay?.monthly,
      ),
      PayMode.cash => ([if (choice.colour != null) choice.colour!.title, 'Pay in full'].join(' · '), ('Payable', choice.price), null),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(AtomRadius.card)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AtomColors.white, borderRadius: BorderRadius.circular(14)),
            child: AtomNetworkImage(p.picture, fit: BoxFit.contain, placeholderIcon: Icons.smartphone_outlined),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AtomText.label.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(detail, style: AtomText.body.copyWith(fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${left.$1} ', style: AtomText.body.copyWith(fontSize: 13)),
                            TextSpan(text: AtomFormat.rupees(left.$2), style: AtomText.label.copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    if (right != null)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: AtomFormat.rupees(right),
                              style: AtomText.label.copyWith(fontSize: 13, color: AtomColors.primary),
                            ),
                            TextSpan(text: '/mo', style: AtomText.body.copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
