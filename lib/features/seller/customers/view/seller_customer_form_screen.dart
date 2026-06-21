import 'dart:io';

import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:atompro/features/seller/customers/repository/seller_customers_repository.dart';
import 'package:atompro/features/seller/customers/viewmodel/seller_customers_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Full-screen Add / Edit customer form.
///
/// Pass [existing] to open in EDIT mode (prefilled, with name/email/phone
/// read-only and a verification toggle). `existing == null` is CREATE mode.
class SellerCustomerFormScreen extends ConsumerStatefulWidget {
  final SellerCustomer? existing;

  const SellerCustomerFormScreen({super.key, this.existing});

  @override
  ConsumerState<SellerCustomerFormScreen> createState() =>
      _SellerCustomerFormScreenState();
}

class _SellerCustomerFormScreenState
    extends ConsumerState<SellerCustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();

  // Section anchors — used to scroll to the first section with a validation error.
  final _personalKey = GlobalKey();
  final _addressKey = GlobalKey();
  final _verificationKey = GlobalKey();

  // Personal
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _father = TextEditingController();
  final _cnic = TextEditingController();
  String _status = 'active';
  File? _picture;

  // Address
  int? _cityId;
  int? _areaId;
  final _address = TextEditingController();
  final _residencePhone = TextEditingController();
  final _officeAddress = TextEditingController();
  final _officePhone = TextEditingController();

  // Verification
  bool _verified = false; // edit-only required toggle
  final _notVerifiedReason = TextEditingController();
  String? _work;
  bool _addressFound = false;
  String _house = 'rent';
  bool _physicalMeet = false;
  File? _idFront;
  File? _idBack;
  File? _selfie;

  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      final p = existing.profile;
      _name.text = existing.name;
      _phone.text = existing.phone;
      _email.text = existing.email == 'Not available' ? '' : existing.email;
      _father.text = p.fatherName == 'Not available' ? '' : p.fatherName;
      _cnic.text = p.cnicNo == 'Not available' ? '' : p.cnicNo;
      _status = _statusOptions.any((o) => o.value == existing.status)
          ? existing.status
          : 'active';
      _cityId = p.cityId > 0 ? p.cityId : null;
      _areaId = p.areaId > 0 ? p.areaId : null;
      _address.text = p.address == 'Not available' ? '' : p.address;
      _residencePhone.text =
          p.residencePhone == 'Not available' ? '' : p.residencePhone;
      _officeAddress.text =
          p.officeAddress == 'Not available' ? '' : p.officeAddress;
      _officePhone.text = p.officePhone == 'Not available' ? '' : p.officePhone;
      _verified = p.verified;
      _notVerifiedReason.text =
          p.notVerifiedReason == 'Not available' ? '' : p.notVerifiedReason;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _father.dispose();
    _cnic.dispose();
    _address.dispose();
    _residencePhone.dispose();
    _officeAddress.dispose();
    _officePhone.dispose();
    _notVerifiedReason.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ValueChanged<File> onPicked) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1400,
    );
    if (picked == null) return;
    onPicked(File(picked.path));
  }

  GlobalKey? _firstInvalidSection() {
    if (!_isEdit) {
      if (_required(_name.text) != null ||
          _phoneValidator(_phone.text) != null ||
          _optionalEmailValidator(_email.text) != null) {
        return _personalKey;
      }
    }
    if (_required(_father.text) != null || _cnicValidator(_cnic.text) != null) {
      return _personalKey;
    }
    if (_cityId == null || _areaId == null || _required(_address.text) != null) {
      return _addressKey;
    }
    if (_isEdit && !_verified && _required(_notVerifiedReason.text) != null) {
      return _verificationKey;
    }
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
    // Surface inline errors, then jump to the first section that has one.
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
      final repo = ref.read(sellerCustomersRepositoryProvider);
      if (_isEdit) {
        await repo.updateCustomer(
          customerUuid: widget.existing!.uuid,
          fatherName: _father.text.trim(),
          cnicNo: _cnic.text.trim(),
          status: _status,
          cityId: _cityId.toString(),
          areaId: _areaId.toString(),
          address: _address.text.trim(),
          residencePhone: _residencePhone.text.trim(),
          officeAddress: _officeAddress.text.trim(),
          officePhone: _officePhone.text.trim(),
          verified: _verified,
          notVerifiedReason: _verified ? null : _notVerifiedReason.text.trim(),
          work: _verified ? _work : null,
          addressFound: _verified ? (_addressFound ? '1' : '0') : null,
          house: _verified ? _house : null,
          customerPhysicalMeet: _verified ? (_physicalMeet ? '1' : '0') : null,
          picture: _picture,
          idCardFrontSide: _verified ? _idFront : null,
          idCardBackSide: _verified ? _idBack : null,
          selfieWithCustomer: _verified ? _selfie : null,
        );
        ref.invalidate(sellerCustomerProfileProvider(widget.existing!.uuid));
      } else {
        await repo.storeCustomer(
          name: _name.text.trim(),
          fatherName: _father.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          cnicNo: _cnic.text.trim(),
          status: _status,
          cityId: _cityId.toString(),
          areaId: _areaId.toString(),
          address: _address.text.trim(),
          residencePhone: _residencePhone.text.trim(),
          officeAddress: _officeAddress.text.trim(),
          officePhone: _officePhone.text.trim(),
          work: _work,
          addressFound: _addressFound ? '1' : '0',
          house: _house,
          customerPhysicalMeet: _physicalMeet ? '1' : '0',
          picture: _picture,
          idCardFrontSide: _idFront,
          idCardBackSide: _idBack,
          selfieWithCustomer: _selfie,
        );
      }
      ref.invalidate(sellerCustomersProvider);
      ref.invalidate(sellerCustomersNotificationCountProvider);
      if (!mounted) return;
      Navigator.pop(context, true);
      SnackbarService().showSuccessSnackBar(
        _isEdit
            ? 'Customer updated successfully.'
            : 'Customer added successfully.',
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
                    title: _isEdit ? 'Edit Customer' : 'Add Customer',
                    subtitle: _isEdit
                        ? widget.existing!.name
                        : 'Create a new customer record',
                    actions: const [
                      SellerNotificationBell(),
                      SellerHeaderProfileButton(),
                    ],
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
          // ── Personal Information ────────────────────────────────────
          SellerSectionHeader(
            key: _personalKey,
            title: 'Personal Information',
          ),
          const Gap.v(AppSpace.sm),
          SellerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Prominent profile-picture picker.
                Center(child: _AvatarPicker(
                  file: _picture,
                  name: _name.text,
                  existingUrl: ApiEndpoints.publicAsset(widget.existing?.profile.picture ?? ''),
                  onTap: _saving
                      ? null
                      : () => _pickImage((f) => setState(() => _picture = f)),
                )),
                const Gap.v(AppSpace.md),
                if (_isEdit) ...[
                  _ReadOnlyField(label: 'Name', value: _name.text),
                  _ReadOnlyField(label: 'Phone', value: _phone.text),
                  _ReadOnlyField(
                    label: 'Email',
                    value: _email.text.isEmpty ? '—' : _email.text,
                  ),
                ] else ...[
                  _FormTextField(
                    controller: _name,
                    label: 'Name',
                    enabled: !_saving,
                    validator: _required,
                  ),
                  _FormTextField(
                    controller: _phone,
                    label: 'Phone',
                    enabled: !_saving,
                    keyboardType: TextInputType.phone,
                    validator: _phoneValidator,
                  ),
                  _FormTextField(
                    controller: _email,
                    label: 'Email (optional)',
                    enabled: !_saving,
                    keyboardType: TextInputType.emailAddress,
                    validator: _optionalEmailValidator,
                  ),
                ],
                _FormTextField(
                  controller: _father,
                  label: 'Father Name',
                  enabled: !_saving,
                  validator: _required,
                ),
                _FormTextField(
                  controller: _cnic,
                  label: 'CNIC',
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  validator: _cnicValidator,
                  inputFormatters: [CnicInputFormatter()],
                ),
                _FormDropdown<String>(
                  label: 'Status',
                  value: _status,
                  enabled: !_saving,
                  items: _statusOptions
                      .map((o) => DropdownMenuItem(
                            value: o.value,
                            child: Text(o.label),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v ?? 'active'),
                  isLast: true,
                ),
              ],
            ),
          ),
          const Gap.v(AppSpace.md),

          // ── Address ─────────────────────────────────────────────────
          SellerSectionHeader(
            key: _addressKey,
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
                  data: (cities) {
                    final sel = cities.where((c) => c.id == _cityId).firstOrNull;
                    return _SearchPickerField(
                      label: 'City',
                      selectedTitle: sel?.title,
                      enabled: !_saving,
                      onTap: () async {
                        final dark = context.sellerIsDark;
                        final result = await showModalBottomSheet<SellerCustomerArea>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => Theme(
                            data: dark ? SellerTheme.dark : SellerTheme.light,
                            child: _SearchPickerSheet(title: 'Select City', items: cities, selectedId: _cityId),
                          ),
                        );
                        if (result != null) setState(() { _cityId = result.id; _areaId = null; });
                      },
                    );
                  },
                ),
                if (_cityId != null) _buildAreaDropdown(c, text),
                _FormTextField(
                  controller: _address,
                  label: 'Address',
                  enabled: !_saving,
                  maxLines: 3,
                  validator: _required,
                ),
                _FormTextField(
                  controller: _residencePhone,
                  label: 'Residence Phone (optional)',
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                ),
                _FormTextField(
                  controller: _officeAddress,
                  label: 'Office Address (optional)',
                  enabled: !_saving,
                ),
                _FormTextField(
                  controller: _officePhone,
                  label: 'Office Phone (optional)',
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  isLast: true,
                ),
              ],
            ),
          ),
          const Gap.v(AppSpace.md),

          // ── Verification ────────────────────────────────────────────
          SellerSectionHeader(
            key: _verificationKey,
            title: 'Verification',
          ),
          const Gap.v(AppSpace.sm),
          SellerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isEdit) ...[
                  _ToggleRow(
                    label: 'Verified',
                    value: _verified,
                    enabled: !_saving,
                    onChanged: (v) => setState(() => _verified = v),
                  ),
                  const Gap.v(AppSpace.sm),
                  if (!_verified)
                    _FormTextField(
                      controller: _notVerifiedReason,
                      label: 'Not Verified Reason',
                      enabled: !_saving,
                      maxLines: 2,
                      validator: _required,
                      isLast: true,
                    )
                  else
                    ..._buildVerificationFields(c, text),
                ] else
                  ..._buildVerificationFields(c, text),
              ],
            ),
          ),
        ],
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
            label: _isEdit ? 'Update Customer' : 'Save Customer',
            loading: _saving,
            onPressed: _saving ? null : _submit,
            icon: Icons.save_outlined,
          ),
        ),
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
      data: (areas) {
        final sel = areas.where((a) => a.id == _areaId).firstOrNull;
        return _SearchPickerField(
          label: 'Area',
          selectedTitle: sel?.title,
          enabled: !_saving,
          onTap: () async {
            final dark = context.sellerIsDark;
            final result = await showModalBottomSheet<SellerCustomerArea>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => Theme(
                data: dark ? SellerTheme.dark : SellerTheme.light,
                child: _SearchPickerSheet(title: 'Select Area', items: areas, selectedId: _areaId),
              ),
            );
            if (result != null) setState(() => _areaId = result.id);
          },
        );
      },
    );
  }

  // Work / address-found / house / physical-meet + 3 doc files.
  List<Widget> _buildVerificationFields(SellerColors c, SellerTextTheme text) {
    return [
      _FormDropdown<String>(
        label: 'Work (optional)',
        value: _work,
        enabled: !_saving,
        items: _workOptions
            .map((o) => DropdownMenuItem(
                  value: o.value,
                  child: Text(o.label),
                ))
            .toList(),
        onChanged: (v) => setState(() => _work = v),
      ),
      _ToggleRow(
        label: 'Address Found',
        value: _addressFound,
        enabled: !_saving,
        onChanged: (v) => setState(() => _addressFound = v),
      ),
      const Gap.v(AppSpace.sm),
      _SegmentedField(
        label: 'House',
        options: const [_Option('rent', 'Rent'), _Option('self', 'Self')],
        value: _house,
        enabled: !_saving,
        onChanged: (v) => setState(() => _house = v),
      ),
      const Gap.v(AppSpace.sm),
      _ToggleRow(
        label: 'Physical Meet',
        value: _physicalMeet,
        enabled: !_saving,
        onChanged: (v) => setState(() => _physicalMeet = v),
      ),
      const Gap.v(AppSpace.sm),
      Row(
        children: [
          Expanded(
            child: _FileButton(
              label: _idFront == null ? 'ID Front' : 'Front Selected',
              hasFile: _idFront != null,
              onTap: _saving
                  ? null
                  : () => _pickImage((f) => setState(() => _idFront = f)),
            ),
          ),
          const Gap.h(AppSpace.xs),
          Expanded(
            child: _FileButton(
              label: _idBack == null ? 'ID Back' : 'Back Selected',
              hasFile: _idBack != null,
              onTap: _saving
                  ? null
                  : () => _pickImage((f) => setState(() => _idBack = f)),
            ),
          ),
        ],
      ),
      const Gap.v(AppSpace.sm),
      _FileButton(
        label: _selfie == null ? 'Selfie With Customer' : 'Selfie Selected',
        hasFile: _selfie != null,
        onTap: _saving
            ? null
            : () => _pickImage((f) => setState(() => _selfie = f)),
      ),
    ];
  }
}

// ── Prominent circular profile-picture picker ──────────────────────────────────
class _AvatarPicker extends StatelessWidget {
  final File? file;
  final String name;
  final VoidCallback? onTap;
  final String existingUrl;

  const _AvatarPicker({
    required this.file,
    required this.name,
    required this.onTap,
    this.existingUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    const size = 96.0;

    Widget avatar;
    if (file != null) {
      avatar = Image.file(file!, fit: BoxFit.cover, width: size, height: size);
    } else if (existingUrl.isNotEmpty) {
      avatar = CachedNetworkImage(
        imageUrl: existingUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorWidget: (_, _, _) => Icon(Icons.person_outline_rounded, size: 44, color: c.accent),
        placeholder: (_, _) => Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: c.accent))),
      );
    } else {
      avatar = Icon(Icons.person_outline_rounded, size: 44, color: c.accent);
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.accentSurface,
                  border: Border.all(color: c.accent, width: 1.6),
                ),
                clipBehavior: Clip.antiAlias,
                child: avatar,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpace.xxs),
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 15,
                    color: c.onAccent,
                  ),
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.xs),
          Text(
            file == null ? 'Add profile picture' : 'Change picture',
            style: text.caption.copyWith(
              color: c.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// Status options for the customer record.
const _statusOptions = <_Option>[
  _Option('active', 'Active'),
  _Option('block', 'Block'),
  _Option('pending', 'Pending'),
  _Option('support', 'Support'),
];

// Work options. NOTE: `bussiness` is the INTENTIONAL stored spelling.
const _workOptions = <_Option>[
  _Option('job', 'Job'),
  _Option('bussiness', 'Business'),
  _Option('house-wife', 'House Wife'),
  _Option('student', 'Student'),
  _Option('freelancer', 'Freelancer'),
  _Option('self-employed', 'Self-Employed'),
  _Option('retired', 'Retired'),
  _Option('unemployed', 'Unemployed'),
  _Option('teacher', 'Teacher'),
  _Option('doctor', 'Doctor'),
  _Option('other', 'Other'),
];

class _Option {
  final String value;
  final String label;
  const _Option(this.value, this.label);
}

// Read-only static field (used for name/email/phone in edit mode).
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

// Themed dropdown form field.
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

// Slim loading bar shown while a dropdown's data loads.
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

// A labelled boolean toggle row.
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

// A 2-option segmented selector (used for House: rent / self).
class _SegmentedField extends StatelessWidget {
  final String label;
  final List<_Option> options;
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _SegmentedField({
    required this.label,
    required this.options,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.label),
        const Gap.v(AppSpace.xs),
        Wrap(
          spacing: AppSpace.xs,
          children: options.map((o) {
            final selected = o.value == value;
            return GestureDetector(
              onTap: enabled ? () => onChanged(o.value) : null,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: selected ? c.accent : c.surface,
                  borderRadius: AppRadius.brPill,
                  border: Border.all(color: selected ? c.accent : c.border),
                ),
                child: Text(
                  o.label,
                  style: text.labelSm.copyWith(
                    color: selected ? c.onAccent : c.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FileButton extends StatelessWidget {
  final String label;
  final bool hasFile;
  final VoidCallback? onTap;

  const _FileButton({
    required this.label,
    required this.hasFile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        decoration: BoxDecoration(
          color: hasFile ? c.accentSurface : c.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: hasFile ? c.accent : c.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 17,
              color: hasFile ? c.accent : c.textSecondary,
            ),
            const Gap.h(AppSpace.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySm.copyWith(
                  color: hasFile ? c.accent : c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
  final List<TextInputFormatter>? inputFormatters;
  final bool isLast;

  const _FormTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
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
        inputFormatters: inputFormatters,
        style: context.sellerText.body,
        decoration: _inputDecoration(c, label),
      ),
    );
  }
}

/// Masks CNIC input as `00000-0000000-0` (13 digits max).
class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = digits.length > 13 ? digits.substring(0, 13) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      buffer.write(trimmed[i]);
      if (i == 4 || i == 11) {
        if (i != trimmed.length - 1) buffer.write('-');
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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

// ── Searchable picker field ──────────────────────────────────────────────────

class _SearchPickerField extends StatelessWidget {
  final String label;
  final String? selectedTitle;
  final bool enabled;
  final bool isLast;
  final VoidCallback onTap;

  const _SearchPickerField({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.selectedTitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final hasValue = selectedTitle != null;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpace.sm),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: InputDecorator(
          decoration: _inputDecoration(c, label),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? selectedTitle! : '',
                  style: text.body.copyWith(
                    color: hasValue ? c.textPrimary : c.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchPickerSheet extends StatefulWidget {
  final String title;
  final List<SellerCustomerArea> items;
  final int? selectedId;

  const _SearchPickerSheet({
    required this.title,
    required this.items,
    this.selectedId,
  });

  @override
  State<_SearchPickerSheet> createState() => _SearchPickerSheetState();
}

class _SearchPickerSheetState extends State<_SearchPickerSheet> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<SellerCustomerArea> get _filtered {
    if (_q.isEmpty) return widget.items;
    final q = _q.toLowerCase();
    return widget.items.where((i) => i.title.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final filtered = _filtered;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      child: Column(
        children: [
          const Gap.v(AppSpace.sm),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: c.borderStrong, borderRadius: AppRadius.brPill),
            ),
          ),
          const Gap.v(AppSpace.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.title, style: text.titleMd),
            ),
          ),
          const Gap.v(AppSpace.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              style: text.bodySm.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search…',
                hintStyle: text.bodySm.copyWith(color: c.textTertiary),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: c.textTertiary),
                suffixIcon: _q.isNotEmpty
                    ? GestureDetector(
                        onTap: () { _ctrl.clear(); setState(() => _q = ''); },
                        child: Icon(Icons.clear_rounded, size: 18, color: c.textTertiary),
                      )
                    : null,
                filled: true,
                fillColor: c.canvas,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
                border: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: c.border)),
                enabledBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: c.border)),
                focusedBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: c.accent, width: 1.5)),
              ),
            ),
          ),
          const Gap.v(AppSpace.sm),
          Divider(height: 1, color: c.divider),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('No results', style: text.bodySm.copyWith(color: c.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: c.divider, indent: AppSpace.md),
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      final active = item.id == widget.selectedId;
                      return InkWell(
                        onTap: () => Navigator.pop(context, item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm + 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: text.bodySm.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: active ? c.accent : c.textPrimary,
                                  ),
                                ),
                              ),
                              if (active) Icon(Icons.check_rounded, size: 18, color: c.accent),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpace.sm),
        ],
      ),
    );
  }
}

// ── Validators ──────────────────────────────────────────────────────────────
String? _required(String? value) {
  if ((value ?? '').trim().isEmpty) return 'Required';
  return null;
}

String? _optionalEmailValidator(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return null;
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

String? _cnicValidator(String? value) {
  final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
  if (digits.length < 13) return 'Enter a valid CNIC';
  return null;
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
