// ============================================================
//  seller_sales_team_form_screen.dart  —  Design System v2
//
//  Full-screen Add / Edit team-member form. Mirrors the
//  customer form (sectioned cards + scroll-to-error + sticky
//  bottom save). Handles the TWO-UUID model:
//    • edit prefill   → sellerSalesTeamEditProvider(member.uuid)
//    • update submit  → updateMember(userUuid: member.user.uuid)
// ============================================================

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/customers/viewmodel/seller_customers_viewmodel.dart';
import 'package:atompro/features/seller/sales_team/model/seller_sales_team_model.dart';
import 'package:atompro/features/seller/sales_team/repository/seller_sales_team_repository.dart';
import 'package:atompro/features/seller/sales_team/viewmodel/seller_sales_team_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen Add / Edit team-member form.
///
/// Pass [existing] to open in EDIT mode (prefilled, with email/phone
/// read-only). `existing == null` is CREATE mode.
class SellerSalesTeamFormScreen extends ConsumerStatefulWidget {
  final SellerSalesTeamMember? existing;

  const SellerSalesTeamFormScreen({super.key, this.existing});

  @override
  ConsumerState<SellerSalesTeamFormScreen> createState() =>
      _SellerSalesTeamFormScreenState();
}

class _SellerSalesTeamFormScreenState
    extends ConsumerState<SellerSalesTeamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();

  // Section anchors — used to scroll to the first section with an error.
  final _personalKey = GlobalKey();
  final _addressKey = GlobalKey();

  // Personal
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _active = true;
  String _memberType = 'sale';
  String _memberRole = 'sale-officer';
  bool _amos = false;

  // Address
  int? _cityId;
  int? _areaId;
  final _address = TextEditingController();

  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _name.text = existing.user.name;
      _email.text = existing.user.email == 'Not available'
          ? ''
          : existing.user.email;
      _phone.text = existing.user.phone == 'Not available'
          ? ''
          : existing.user.phone;
      _active = existing.active;
      _memberType = _memberTypeOptions.any((o) => o.value == existing.memberType)
          ? existing.memberType
          : 'sale';
      _memberRole = _memberRoleOptions.any((o) => o.value == existing.memberRole)
          ? existing.memberRole
          : 'sale-officer';
      _amos = existing.user.role.toLowerCase() == 'amos';
      _cityId = existing.cityId > 0 ? existing.cityId : null;
      _areaId = existing.areaId > 0 ? existing.areaId : null;
      _address.text = existing.address == 'Not available' ? '' : existing.address;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey? _firstInvalidSection() {
    if (_required(_name.text) != null) return _personalKey;
    if (!_isEdit &&
        (_emailValidator(_email.text) != null ||
            _phoneValidator(_phone.text) != null)) {
      return _personalKey;
    }
    if (_cityId == null || _areaId == null) return _addressKey;
    return null;
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: AppMotion.base,
      curve: AppMotion.standard,
      alignment: 0.05,
    );
  }

  Future<void> _submit() async {
    final fieldsValid = _formKey.currentState?.validate() ?? false;
    final invalidSection = _firstInvalidSection();
    if (invalidSection != null) {
      await _scrollToSection(invalidSection);
      SnackbarService().showErrorSnackBar(
        _cityId == null
            ? 'Please select a city.'
            : _areaId == null
                ? 'Please select an area.'
                : 'Please complete the highlighted fields.',
      );
      return;
    }
    if (!fieldsValid) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(sellerSalesTeamRepositoryProvider);
      if (_isEdit) {
        await repo.updateMember(
          userUuid: widget.existing!.user.uuid,
          name: _name.text.trim(),
          active: _active,
          memberType: _memberType,
          memberRole: _memberRole,
          cityId: _cityId.toString(),
          areaId: _areaId.toString(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          amosAssistantManager: _amos,
        );
        ref.invalidate(sellerSalesTeamEditProvider(widget.existing!.uuid));
      } else {
        await repo.storeMember(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          active: _active,
          memberType: _memberType,
          memberRole: _memberRole,
          cityId: _cityId.toString(),
          areaId: _areaId.toString(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          amosAssistantManager: _amos,
        );
      }
      ref.invalidate(sellerSalesTeamProvider);
      if (!mounted) return;
      Navigator.pop(context, true);
      SnackbarService().showSuccessSnackBar(
        _isEdit ? 'Changes saved.' : 'Member added successfully.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SellerThemeScope(
      child: Builder(
        builder: (context) {
          final c = context.sellerColors;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: c.isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: c.canvas,
              body: Column(
                children: [
                  SellerGradientHeader(
                    leading: SellerIconBadge(
                      icon: _isEdit
                          ? Icons.edit_outlined
                          : Icons.person_add_alt_1_outlined,
                      tone: SellerTone(
                        fg: Colors.white,
                        bg: Colors.white.withValues(alpha: 0.16),
                        border: Colors.white.withValues(alpha: 0.20),
                      ),
                      size: 48,
                      iconSize: 26,
                      radius: AppRadius.lg,
                    ),
                    title: _isEdit ? 'Edit Team Member' : 'Add Team Member',
                    subtitle: _isEdit
                        ? widget.existing!.user.name
                        : 'Create a new sales or recovery member',
                  ),
                  Expanded(child: _buildForm(context)),
                ],
              ),
              bottomNavigationBar: _buildBottomBar(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final citiesState = ref.watch(sellerCustomerCitiesProvider);

    return Form(
      key: _formKey,
      child: ListView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.md,
          AppSpace.md,
          AppSpace.xxl,
        ),
        children: [
          // ── Personal Details ─────────────────────────────────────────
          SellerSectionHeader(
            key: _personalKey,
            overline: 'Member',
            title: 'Personal Details',
          ),
          const Gap.v(AppSpace.sm),
          SellerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FormTextField(
                  controller: _name,
                  label: 'Name',
                  enabled: !_saving,
                  validator: _required,
                ),
                if (_isEdit) ...[
                  _ReadOnlyField(
                    label: 'Email',
                    value: _email.text.isEmpty ? '—' : _email.text,
                  ),
                  _ReadOnlyField(
                    label: 'Phone',
                    value: _phone.text.isEmpty ? '—' : _phone.text,
                  ),
                ] else ...[
                  _FormTextField(
                    controller: _email,
                    label: 'Email',
                    enabled: !_saving,
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),
                  _FormTextField(
                    controller: _phone,
                    label: 'Phone',
                    enabled: !_saving,
                    keyboardType: TextInputType.phone,
                    validator: _phoneValidator,
                  ),
                ],
                _FormDropdown<String>(
                  label: 'Member Type',
                  value: _memberType,
                  enabled: !_saving,
                  items: _memberTypeOptions
                      .map((o) => DropdownMenuItem(
                            value: o.value,
                            child: Text(o.label),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _memberType = v ?? _memberType),
                ),
                _FormDropdown<String>(
                  label: 'Member Role',
                  value: _memberRole,
                  enabled: !_saving,
                  items: _memberRoleOptions
                      .map((o) => DropdownMenuItem(
                            value: o.value,
                            child: Text(o.label),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _memberRole = v ?? _memberRole),
                ),
                _ToggleRow(
                  label: 'Active',
                  value: _active,
                  enabled: !_saving,
                  onChanged: (v) => setState(() => _active = v),
                ),
                const Gap.v(AppSpace.sm),
                _ToggleRow(
                  label: 'Enable AMOS dashboard access',
                  value: _amos,
                  enabled: !_saving,
                  onChanged: (v) => setState(() => _amos = v),
                ),
              ],
            ),
          ),
          const Gap.v(AppSpace.md),

          // ── Address ──────────────────────────────────────────────────
          SellerSectionHeader(
            key: _addressKey,
            overline: 'Location',
            title: 'Address',
          ),
          const Gap.v(AppSpace.sm),
          SellerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                citiesState.when(
                  loading: () => _DropdownPlaceholder(c: c),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: Text(
                      _cleanError(error),
                      style: text.bodySm.copyWith(color: c.danger),
                    ),
                  ),
                  data: (cities) => _FormDropdown<int>(
                    label: 'City',
                    value: cities.any((city) => city.id == _cityId)
                        ? _cityId
                        : null,
                    enabled: !_saving,
                    items: cities
                        .map((city) => DropdownMenuItem(
                              value: city.id,
                              child: Text(city.title),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _cityId = v;
                      _areaId = null;
                    }),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                if (_cityId != null) _buildAreaDropdown(c, text),
                _FormTextField(
                  controller: _address,
                  label: 'Address (optional)',
                  enabled: !_saving,
                  maxLines: 3,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaDropdown(SellerColors c, SellerTextTheme text) {
    final areasState = ref.watch(sellerCustomerAreasProvider(_cityId!));
    return areasState.when(
      loading: () => _DropdownPlaceholder(c: c),
      error: (error, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.sm),
        child: Text(
          _cleanError(error),
          style: text.bodySm.copyWith(color: c.danger),
        ),
      ),
      data: (areas) => _FormDropdown<int>(
        label: 'Area',
        value: areas.any((a) => a.id == _areaId) ? _areaId : null,
        enabled: !_saving,
        items: areas
            .map((area) => DropdownMenuItem(
                  value: area.id,
                  child: Text(area.title),
                ))
            .toList(),
        onChanged: (v) => setState(() => _areaId = v),
        validator: (v) => v == null ? 'Required' : null,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final c = context.sellerColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.sm,
            AppSpace.md,
            AppSpace.sm,
          ),
          child: SellerButton(
            label: _isEdit ? 'Save Changes' : 'Add Member',
            loading: _saving,
            onPressed: _saving ? null : _submit,
            icon: Icons.save_outlined,
          ),
        ),
      ),
    );
  }
}

// ── Options ───────────────────────────────────────────────────────────────
const _memberTypeOptions = <_Option>[
  _Option('sale', 'Sales Team'),
  _Option('recovery', 'Recovery Team'),
];

const _memberRoleOptions = <_Option>[
  _Option('manager', 'Manager'),
  _Option('sale-officer', 'Sale Officer'),
  _Option('recovery-officer', 'Recovery Officer'),
  _Option('verification-inquiry-officer', 'Verification / Inquiry Officer'),
];

class _Option {
  final String value;
  final String label;
  const _Option(this.value, this.label);
}

// ── Read-only static field (email / phone in edit mode) ─────────────────────
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: text.caption),
            const Gap.v(AppSpace.xxs),
            Text(
              value.isEmpty ? '—' : value,
              style: text.bodySm.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Themed dropdown form field ──────────────────────────────────────────────
class _FormDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final bool enabled;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final bool isLast;

  const _FormDropdown({
    required this.label,
    required this.value,
    required this.enabled,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpace.sm),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: _inputDecoration(c, label),
        style: context.sellerText.body,
        dropdownColor: c.surface,
        items: items,
        onChanged: enabled ? onChanged : null,
        validator: validator,
      ),
    );
  }
}

// ── Slim loading bar while a dropdown's data loads ──────────────────────────
class _DropdownPlaceholder extends StatelessWidget {
  final SellerColors c;
  const _DropdownPlaceholder({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: LinearProgressIndicator(
        minHeight: 2,
        color: c.accent,
        backgroundColor: c.surfaceMuted,
      ),
    );
  }
}

// ── Labelled boolean toggle row ─────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.bodySm.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: c.accent,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool isLast;

  const _FormTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpace.sm),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: context.sellerText.body,
        decoration: _inputDecoration(c, label),
      ),
    );
  }
}

InputDecoration _inputDecoration(SellerColors c, String label) {
  const radius = AppRadius.md;
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
    filled: true,
    fillColor: c.surfaceAlt,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpace.md,
      vertical: AppSpace.sm,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: c.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: c.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: c.accent, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: c.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: c.danger, width: 1.6),
    ),
  );
}

// ── Validators ──────────────────────────────────────────────────────────────
String? _required(String? value) {
  if ((value ?? '').trim().isEmpty) return 'Required';
  return null;
}

String? _emailValidator(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Required';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
    return 'Enter a valid email';
  }
  return null;
}

String? _phoneValidator(String? value) {
  final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
  if (digits.length < 10) return 'Enter a valid phone number';
  return null;
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
