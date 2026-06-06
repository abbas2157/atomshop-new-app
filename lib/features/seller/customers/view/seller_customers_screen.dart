import 'dart:io';

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:atompro/features/seller/customers/repository/seller_customers_repository.dart';
import 'package:atompro/features/seller/customers/view/seller_customer_details_screen.dart';
import 'package:atompro/features/seller/customers/viewmodel/seller_customers_viewmodel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class SellerCustomersScreen extends ConsumerStatefulWidget {
  const SellerCustomersScreen({super.key});

  @override
  ConsumerState<SellerCustomersScreen> createState() =>
      _SellerCustomersScreenState();
}

class _SellerCustomersScreenState extends ConsumerState<SellerCustomersScreen> {
  SellerCustomerScope _scope = SellerCustomerScope.mine;
  int _page = 1;
  String _search = '';
  final _searchCtrl = TextEditingController();

  SellerCustomersQuery get _query =>
      SellerCustomersQuery(scope: _scope, page: _page);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddCustomerSheet() =>
      showSellerAddCustomerSheet(context, ref);

  Future<void> _importCustomers() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );
      final path = picked?.files.single.path;
      if (path == null) return;
      await ref
          .read(sellerCustomersRepositoryProvider)
          .importCustomers(File(path));
      ref.invalidate(sellerCustomersProvider(_query));
      ref.invalidate(sellerCustomersNotificationCountProvider);
      SnackbarService().showSuccessSnackBar('Customers imported.');
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  Future<void> _openImportSample() async {
    try {
      final path = await ref
          .read(sellerCustomersRepositoryProvider)
          .downloadImportSample();
      await SellerFileService.openLocalFile(path);
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final state = ref.watch(sellerCustomersProvider(_query));
    final notificationState = ref.watch(
      sellerCustomersNotificationCountProvider,
    );

    final notifCount = notificationState.asData?.value;
    final subtitle = notifCount == null
        ? 'Manage seller customer records'
        : '$notifCount new customer notifications';

    // Map scope index → SellerCustomerScope enum
    final scopeIndex = SellerCustomerScope.values.indexOf(_scope);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.canvas,
        body: Column(
          children: [
            // ── Gradient header ──────────────────────────────────────────
            SellerGradientHeader(
              leading: SellerIconBadge(
                icon: Icons.groups_2_outlined,
                tone: SellerTone(
                  fg: Colors.white,
                  bg: Colors.white.withValues(alpha: 0.16),
                  border: Colors.white.withValues(alpha: 0.20),
                ),
                size: 48,
                iconSize: 26,
                radius: AppRadius.lg,
              ),
              title: 'Customers',
              subtitle: subtitle,
              actions: [
                SellerHeaderIconButton(
                  icon: Icons.download_outlined,
                  onTap: _openImportSample,
                  tooltip: 'Sample file',
                ),
                SellerHeaderIconButton(
                  icon: Icons.upload_file_outlined,
                  onTap: _importCustomers,
                  tooltip: 'Import customers',
                ),
                SellerHeaderIconButton(
                  icon: Icons.person_add_alt_1_outlined,
                  onTap: _showAddCustomerSheet,
                  tooltip: 'Add customer',
                ),
              ],
            ),
            // ── Search + scope ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.md,
                AppSpace.md,
                AppSpace.xs,
              ),
              child: SellerSearchField(
                controller: _searchCtrl,
                hint: 'Search by name, phone, CNIC…',
                onChanged: (v) => setState(() {
                  _search = v;
                  _page = 1;
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.xs,
                AppSpace.md,
                AppSpace.xs,
              ),
              child: SellerSegmentedTabs(
                labels: SellerCustomerScope.values
                    .map((s) => s.shortLabel)
                    .toList(),
                selectedIndex: scopeIndex,
                onChanged: (i) => setState(() {
                  _scope = SellerCustomerScope.values[i];
                  _page = 1;
                  _search = '';
                  _searchCtrl.clear();
                }),
              ),
            ),
            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerCustomersProvider(_query));
                  ref.invalidate(sellerCustomersNotificationCountProvider);
                  await ref.read(sellerCustomersProvider(_query).future);
                },
                child: state.when(
                  loading: () => const SellerListSkeleton(),
                  error: (error, _) => SellerErrorState(
                    message: _cleanError(error),
                    onRetry: () =>
                        ref.invalidate(sellerCustomersProvider(_query)),
                  ),
                  data: (data) {
                    final customers = _filter(data.customers, _search);
                    return ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: AppInsets.pageWithNav,
                      children: [
                        // Summary strip
                        _SummaryStrip(
                          label: _scope.label,
                          total: data.pagination.total,
                          from: data.pagination.from,
                          to: data.pagination.to,
                        ),
                        const Gap.v(AppSpace.sm),
                        // Customer list or empty
                        if (customers.isEmpty)
                          SellerEmptyState(
                            icon: Icons.person_search_outlined,
                            title: 'No customers found',
                            message: _search.isNotEmpty
                                ? 'Try a different search term.'
                                : 'Add your first customer to get started.',
                          )
                        else
                          ...customers.map(
                            (customer) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpace.sm,
                              ),
                              child: _CustomerCard(
                                customer: customer,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SellerCustomerDetailsScreen(
                                      customerUuid: customer.uuid,
                                      initialCustomer: customer,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Pagination
                        _PaginationBar(
                          pagination: data.pagination,
                          text: text,
                          c: c,
                          onPrevious: data.pagination.hasPrevious
                              ? () => setState(() => _page--)
                              : null,
                          onNext: data.pagination.hasNext
                              ? () => setState(() => _page++)
                              : null,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary strip ─────────────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final String label;
  final int total;
  final int? from;
  final int? to;

  const _SummaryStrip({
    required this.label,
    required this.total,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return SellerCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.titleSm,
            ),
          ),
          Text(
            total == 0 ? '0 records' : '${from ?? 0}–${to ?? 0} of $total',
            style: text.caption.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Customer card ─────────────────────────────────────────────────────────────
class _CustomerCard extends StatelessWidget {
  final SellerCustomer customer;
  final VoidCallback onTap;

  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final verified = customer.verified;
    final location = customer.profile.location;

    return SellerCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      accentEdge: verified ? c.success : c.warning,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.sm,
          AppSpace.sm,
          AppSpace.md,
          AppSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Name + avatar + status pill ─────────────────────────────
            Row(
              children: [
                SellerMonogram(name: customer.name, size: 40),
                const Gap.h(AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSm,
                      ),
                      const Gap.v(AppSpace.xxs),
                      Text(
                        customer.phone,
                        style: text.bodySm,
                      ),
                    ],
                  ),
                ),
                SellerStatusPill(
                  label: verified ? 'Verified' : 'Pending',
                  tone: verified ? c.successTone : c.warningTone,
                ),
              ],
            ),
            const Gap.v(AppSpace.xs),
            Divider(color: c.divider, height: 1),
            const Gap.v(AppSpace.xs),
            // ── Location & address ──────────────────────────────────────
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: location.isEmpty ? 'Location N/A' : location,
            ),
            const Gap.v(AppSpace.xxs + 1),
            _InfoRow(
              icon: Icons.home_outlined,
              label: customer.profile.address,
            ),
            const Gap.v(AppSpace.xxs + 1),
            // ── Joined + date ────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.public_outlined, size: 13, color: c.textTertiary),
                const Gap.h(AppSpace.xxs),
                Text(
                  customer.joinedThrough,
                  style: text.caption,
                ),
                const Gap.h(AppSpace.xs),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: c.textTertiary,
                ),
                const Gap.h(AppSpace.xxs),
                Text(
                  customer.formattedCreatedAt,
                  style: text.caption,
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: c.textTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Row(
      children: [
        Icon(icon, size: 13, color: c.textTertiary),
        const Gap.h(AppSpace.xxs),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySm.copyWith(color: c.textPrimary),
          ),
        ),
      ],
    );
  }
}

// ── Pagination bar ────────────────────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final SellerCustomersPagination pagination;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final SellerTextTheme text;
  final SellerColors c;

  const _PaginationBar({
    required this.pagination,
    required this.onPrevious,
    required this.onNext,
    required this.text,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    if (pagination.lastPage <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs),
      child: Row(
        children: [
          Expanded(
            child: SellerButton.secondary(
              label: 'Previous',
              icon: Icons.chevron_left_rounded,
              onPressed: onPrevious,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            child: Text(
              '${pagination.currentPage} / ${pagination.lastPage}',
              style: text.labelSm.copyWith(color: c.textSecondary),
            ),
          ),
          Expanded(
            child: SellerButton.secondary(
              label: 'Next',
              trailingIcon: Icons.chevron_right_rounded,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Customer Sheet ────────────────────────────────────────────────────────
/// Opens the add-customer form. Reusable from the global + action so
/// "New customer" creates in one tap instead of just navigating.
Future<void> showSellerAddCustomerSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final dark = context.sellerIsDark;
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: const _AddCustomerSheet(),
    ),
  );
  if (changed == true) {
    ref.invalidate(sellerCustomersProvider);
    ref.invalidate(sellerCustomersNotificationCountProvider);
  }
}

class _AddCustomerSheet extends ConsumerStatefulWidget {
  const _AddCustomerSheet();

  @override
  ConsumerState<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends ConsumerState<_AddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _father = TextEditingController();
  final _cnic = TextEditingController();
  final _cityId = TextEditingController(text: '1');
  final _address = TextEditingController();
  int? _areaId;
  File? _front;
  File? _back;
  bool _saving = false;

  int get _selectedCityId => int.tryParse(_cityId.text.trim()) ?? 1;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _father.dispose();
    _cnic.dispose();
    _cityId.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickFront() async => _pickImage(front: true);
  Future<void> _pickBack() async => _pickImage(front: false);

  Future<void> _pickImage({required bool front}) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1400,
    );
    if (picked == null) return;
    setState(() {
      if (front) {
        _front = File(picked.path);
      } else {
        _back = File(picked.path);
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_areaId == null) {
      SnackbarService().showErrorSnackBar('Select an area.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(sellerCustomersRepositoryProvider).storeCustomer(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            fatherName: _father.text.trim(),
            cnicNo: _cnic.text.trim(),
            cityId: _cityId.text.trim(),
            areaId: _areaId.toString(),
            address: _address.text.trim(),
            idCardFrontSide: _front,
            idCardBackSide: _back,
          );
      if (!mounted) return;
      SnackbarService().showSuccessSnackBar('Customer added.');
      Navigator.pop(context, true);
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final areasState = ref.watch(sellerCustomerAreasProvider(_selectedCityId));
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.sheet,
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
          AppSpace.md,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.borderStrong,
                        borderRadius: AppRadius.brPill,
                      ),
                    ),
                  ),
                  const Gap.v(AppSpace.md),
                  Text('Add Customer', style: text.titleMd),
                  const Gap.v(AppSpace.md),
                  _SheetTextField(
                    controller: _name,
                    label: 'Name',
                    enabled: !_saving,
                    validator: _required,
                  ),
                  _SheetTextField(
                    controller: _phone,
                    label: 'Phone',
                    enabled: !_saving,
                    keyboardType: TextInputType.phone,
                    validator: _phoneValidator,
                  ),
                  _SheetTextField(
                    controller: _email,
                    label: 'Email',
                    enabled: !_saving,
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),
                  _SheetTextField(
                    controller: _father,
                    label: 'Father Name',
                    enabled: !_saving,
                    validator: _required,
                  ),
                  _SheetTextField(
                    controller: _cnic,
                    label: 'CNIC',
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    validator: _cnicValidator,
                  ),
                  _SheetTextField(
                    controller: _cityId,
                    label: 'City ID',
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    validator: _required,
                    onChanged: (_) => setState(() => _areaId = null),
                  ),
                  areasState.when(
                    loading: () => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.sm),
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: c.accent,
                        backgroundColor: c.surfaceMuted,
                      ),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.sm),
                      child: Text(
                        _cleanError(error),
                        style: text.bodySm.copyWith(color: c.danger),
                      ),
                    ),
                    data: (areas) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.sm),
                      child: DropdownButtonFormField<int>(
                        initialValue: _areaId,
                        decoration: _inputDecoration(c, 'Area'),
                        items: areas
                            .map(
                              (area) => DropdownMenuItem(
                                value: area.id,
                                child: Text(area.title),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _areaId = value),
                        validator: (value) =>
                            value == null ? 'Required' : null,
                      ),
                    ),
                  ),
                  _SheetTextField(
                    controller: _address,
                    label: 'Address',
                    enabled: !_saving,
                    maxLines: 3,
                    validator: _required,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _FileButton(
                          label:
                              _front == null ? 'CNIC Front' : 'Front Selected',
                          hasFile: _front != null,
                          onTap: _saving ? null : _pickFront,
                        ),
                      ),
                      const Gap.h(AppSpace.xs),
                      Expanded(
                        child: _FileButton(
                          label:
                              _back == null ? 'CNIC Back' : 'Back Selected',
                          hasFile: _back != null,
                          onTap: _saving ? null : _pickBack,
                        ),
                      ),
                    ],
                  ),
                  const Gap.v(AppSpace.md),
                  SellerButton(
                    label: 'Save Customer',
                    loading: _saving,
                    onPressed: _submit,
                    icon: Icons.save_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
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

// ── Pure business-logic helpers (unchanged) ───────────────────────────────────
List<SellerCustomer> _filter(List<SellerCustomer> customers, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return customers;
  return customers
      .where((customer) {
        return customer.name.toLowerCase().contains(q) ||
            customer.phone.toLowerCase().contains(q) ||
            customer.email.toLowerCase().contains(q) ||
            customer.profile.cnicNo.toLowerCase().contains(q) ||
            customer.profile.identifier.toLowerCase().contains(q);
      })
      .toList(growable: false);
}

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

String? _cnicValidator(String? value) {
  final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
  if (digits.length < 13) return 'Enter a valid CNIC';
  return null;
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
