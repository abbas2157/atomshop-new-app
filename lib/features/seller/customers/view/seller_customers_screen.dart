import 'dart:io';

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:atompro/features/seller/customers/repository/seller_customers_repository.dart';
import 'package:atompro/features/seller/customers/view/seller_customer_details_screen.dart';
import 'package:atompro/features/seller/customers/viewmodel/seller_customers_viewmodel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

abstract final class _C {
  static const bg = Color(0xFFF4F6FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFE);
  static const brand = Color(0xFF3B5BDB);
  static const brandDark = Color(0xFF1A2980);
  static const text = Color(0xFF101828);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE4E8F5);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
}

class SellerCustomersScreen extends ConsumerStatefulWidget {
  const SellerCustomersScreen({super.key});

  @override
  ConsumerState<SellerCustomersScreen> createState() =>
      _SellerCustomersScreenState();
}

class _SellerCustomersScreenState extends ConsumerState<SellerCustomersScreen> {
  final SellerCustomerScope _scope = SellerCustomerScope.mine;
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

  Future<void> _showAddCustomerSheet() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddCustomerSheet(),
    );
    if (changed == true) {
      ref.invalidate(sellerCustomersProvider(_query));
      ref.invalidate(sellerCustomersNotificationCountProvider);
    }
  }

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
    final state = ref.watch(sellerCustomersProvider(_query));
    final notificationState = ref.watch(
      sellerCustomersNotificationCountProvider,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'seller_add_customer',
          onPressed: _showAddCustomerSheet,
          backgroundColor: _C.brand,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Add'),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: _C.brand,
            onRefresh: () async {
              ref.invalidate(sellerCustomersProvider(_query));
              ref.invalidate(sellerCustomersNotificationCountProvider);
              await ref.read(sellerCustomersProvider(_query).future);
            },
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 118),
              children: [
                _Header(
                  notificationState: notificationState,
                  onImport: _importCustomers,
                  onSample: _openImportSample,
                ),
                const SizedBox(height: 14),
                _SearchBox(
                  controller: _searchCtrl,
                  onChanged: (value) => setState(() => _search = value),
                ),
                const SizedBox(height: 14),
                state.when(
                  loading: () => const _CustomerListSkeleton(),
                  error: (error, _) => _ErrorCard(
                    message: _cleanError(error),
                    onRetry: () =>
                        ref.invalidate(sellerCustomersProvider(_query)),
                  ),
                  data: (data) {
                    final customers = _filter(data.customers, _search);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SummaryStrip(
                          label: _scope.label,
                          total: data.pagination.total,
                          from: data.pagination.from,
                          to: data.pagination.to,
                        ),
                        const SizedBox(height: 12),
                        if (customers.isEmpty)
                          const _EmptyState()
                        else
                          ...customers.map(
                            (customer) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CustomerCard(
                                customer: customer,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SellerCustomerDetailsScreen(
                                      customerUuid: customer.uuid,
                                      initialCustomer: customer,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        _PaginationBar(
                          pagination: data.pagination,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AsyncValue<int> notificationState;
  final VoidCallback onImport;
  final VoidCallback onSample;

  const _Header({
    required this.notificationState,
    required this.onImport,
    required this.onSample,
  });

  @override
  Widget build(BuildContext context) {
    final count = notificationState.asData?.value;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.brandDark, _C.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _C.brand.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: const Icon(
              Icons.groups_2_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  count == null
                      ? 'Manage seller customer records'
                      : '$count new customer notifications',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _HeaderAction(
            tooltip: 'Sample file',
            icon: Icons.download_outlined,
            onTap: onSample,
          ),
          const SizedBox(width: 8),
          _HeaderAction(
            tooltip: 'Import customers',
            icon: Icons.upload_file_outlined,
            onTap: onImport,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search current page by name, phone, CNIC',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: _C.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _C.brand, width: 1.4),
        ),
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _C.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            total == 0 ? '0 records' : '${from ?? 0}-${to ?? 0} of $total',
            style: const TextStyle(
              color: _C.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final SellerCustomer customer;
  final VoidCallback onTap;

  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _C.brand.withValues(alpha: 0.1),
                  child: Text(
                    _initials(customer.name),
                    style: const TextStyle(
                      color: _C.brand,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _C.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer.phone,
                        style: const TextStyle(
                          color: _C.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: customer.verified ? 'Verified' : 'Pending',
                  fg: customer.verified ? _C.success : _C.warning,
                  bg: (customer.verified ? _C.success : _C.warning).withValues(
                    alpha: 0.12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                _MiniInfo(
                  icon: Icons.badge_outlined,
                  label: customer.profile.identifier,
                ),
                const SizedBox(width: 8),
                _MiniInfo(
                  icon: Icons.public_outlined,
                  label: customer.joinedThrough,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    customer.profile.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _C.muted,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: _C.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _C.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: _C.brand),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _C.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _StatusPill({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final SellerCustomersPagination pagination;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.pagination,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (pagination.lastPage <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Previous'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${pagination.currentPage}/${pagination.lastPage}',
              style: const TextStyle(
                color: _C.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Next'),
            ),
          ),
        ],
      ),
    );
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
      await ref
          .read(sellerCustomersRepositoryProvider)
          .storeCustomer(
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
    final areasState = ref.watch(sellerCustomerAreasProvider(_selectedCityId));
    return _SheetShell(
      title: 'Add Customer',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
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
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _cleanError(error),
                  style: const TextStyle(
                    color: _C.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              data: (areas) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<int>(
                  initialValue: _areaId,
                  decoration: _sheetDecoration('Area'),
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
                  validator: (value) => value == null ? 'Required' : null,
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
                    label: _front == null ? 'CNIC Front' : 'Front Selected',
                    onTap: _saving ? null : _pickFront,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FileButton(
                    label: _back == null ? 'CNIC Back' : 'Back Selected',
                    onTap: _saving ? null : _pickBack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SheetButton(
              label: 'Save Customer',
              loading: _saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _FileButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _FileButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.image_outlined, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        foregroundColor: _C.brand,
        side: const BorderSide(color: _C.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _C.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: _C.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        decoration: _sheetDecoration(label),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _SheetButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: _C.brand,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _CustomerListSkeleton extends StatelessWidget {
  const _CustomerListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          height: 142,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.border),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: _C.danger),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _C.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_search_outlined, color: _C.muted, size: 32),
          SizedBox(height: 10),
          Text(
            'No customers found.',
            style: TextStyle(color: _C.text, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

InputDecoration _sheetDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: _C.surfaceAlt,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _C.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _C.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _C.brand, width: 1.4),
    ),
  );
}

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

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'C';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
      .toUpperCase();
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
