import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/sales_team/model/seller_sales_team_model.dart';
import 'package:atompro/features/seller/sales_team/repository/seller_sales_team_repository.dart';
import 'package:atompro/features/seller/sales_team/viewmodel/seller_sales_team_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class _T {
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

class SellerSalesTeamScreen extends ConsumerStatefulWidget {
  const SellerSalesTeamScreen({super.key});

  @override
  ConsumerState<SellerSalesTeamScreen> createState() =>
      _SellerSalesTeamScreenState();
}

class _SellerSalesTeamScreenState extends ConsumerState<SellerSalesTeamScreen> {
  int _page = 1;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddSheet() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TeamMemberSheet(),
    );
    if (changed == true) ref.invalidate(sellerSalesTeamProvider(_page));
  }

  Future<void> _showEditSheet(SellerSalesTeamMember member) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TeamMemberEditLoader(member: member),
    );
    if (changed == true) ref.invalidate(sellerSalesTeamProvider(_page));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerSalesTeamProvider(_page));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _T.bg,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: _showAddSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_T.brandDark, _T.brand],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _T.brand.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_add_alt_1_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Add Member',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: _T.bg,
          surfaceTintColor: _T.bg,
          titleSpacing: 0,
          title: const Text(
            'Sales Team',
            style: TextStyle(
              color: _T.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(sellerSalesTeamProvider(_page)),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: _T.brand,
            onRefresh: () async {
              ref.invalidate(sellerSalesTeamProvider(_page));
              await ref.read(sellerSalesTeamProvider(_page).future);
            },
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
              children: [
                _Header(),
                const SizedBox(height: 12),
                _SearchBox(
                  controller: _searchCtrl,
                  onChanged: (value) => setState(() => _search = value),
                ),
                const SizedBox(height: 14),
                state.when(
                  loading: () => const _TeamSkeleton(),
                  error: (error, _) => _ErrorCard(
                    message: _cleanError(error),
                    onRetry: () =>
                        ref.invalidate(sellerSalesTeamProvider(_page)),
                  ),
                  data: (data) {
                    final members = _filter(data.members, _search);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RangeStrip(
                          total: data.pagination.total,
                          from: data.pagination.from,
                          to: data.pagination.to,
                        ),
                        const SizedBox(height: 12),
                        if (members.isEmpty)
                          const _EmptyState()
                        else
                          ...members.map(
                            (member) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TeamMemberCard(
                                member: member,
                                onEdit: () => _showEditSheet(member),
                                onPerformance: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SellerSalesTeamPerformanceScreen(
                                          member: member,
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

class SellerSalesTeamPerformanceScreen extends ConsumerWidget {
  final SellerSalesTeamMember member;

  const SellerSalesTeamPerformanceScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerSalesTeamPerformanceProvider(member.uuid));
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.bg,
        surfaceTintColor: _T.bg,
        title: const Text('Performance'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            _MemberHero(member: member),
            const SizedBox(height: 12),
            state.when(
              loading: () => const _SectionLoading(),
              error: (error, _) => _ErrorCard(
                message: _cleanError(error),
                onRetry: () => ref.invalidate(
                  sellerSalesTeamPerformanceProvider(member.uuid),
                ),
              ),
              data: (performance) {
                if (performance.metrics.isEmpty) {
                  return const _EmptyState(label: 'No performance data found.');
                }
                return _MetricsSection(metrics: performance.metrics);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_T.brandDark, _T.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _T.brand.withValues(alpha: 0.24),
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
                  'Sales Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Manage field sales and recovery members',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      decoration: InputDecoration(
        hintText: 'Search by name, phone, email, role',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: _T.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _T.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _T.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _T.brand, width: 1.4),
        ),
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final SellerSalesTeamMember member;
  final VoidCallback onEdit;
  final VoidCallback onPerformance;

  const _TeamMemberCard({
    required this.member,
    required this.onEdit,
    required this.onPerformance,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = member.active ? _T.success : _T.warning;
    final location = member.location;
    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Name + status ─────────────────────────────────
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _T.brand.withValues(alpha: 0.1),
                            child: Text(
                              _initials(member.user.name),
                              style: const TextStyle(
                                color: _T.brand,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _T.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  member.user.phone,
                                  style: const TextStyle(
                                    color: _T.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StatusPill(
                            label: member.active ? 'Active' : 'Inactive',
                            fg: accentColor,
                            bg: accentColor.withValues(alpha: 0.12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: _T.border),
                      const SizedBox(height: 8),

                      // ── Location ──────────────────────────────────────
                      _CardRow(
                        icon: Icons.location_on_outlined,
                        label: location.isEmpty ? 'Location N/A' : location,
                      ),
                      const SizedBox(height: 5),

                      // ── Role + type ───────────────────────────────────
                      _CardRow(
                        icon: Icons.badge_outlined,
                        label: '${member.memberRole} · ${member.memberType}',
                      ),
                      const SizedBox(height: 5),

                      // ── Date ─────────────────────────────────────────
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: _T.muted),
                          const SizedBox(width: 4),
                          Text(
                            member.formattedCreatedAt,
                            style: const TextStyle(
                              color: _T.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Actions ───────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onPerformance,
                              icon: const Icon(Icons.bar_chart_outlined,
                                  size: 15),
                              label: const Text('Performance'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _T.brand,
                                side: const BorderSide(color: _T.border),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined, size: 15),
                              label: const Text('Edit'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _T.brand,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CardRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _T.muted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _T.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamMemberSheet extends ConsumerStatefulWidget {
  final SellerSalesTeamMember? member;

  const _TeamMemberSheet({this.member});

  @override
  ConsumerState<_TeamMemberSheet> createState() => _TeamMemberSheetState();
}

class _TeamMemberEditLoader extends ConsumerWidget {
  final SellerSalesTeamMember member;

  const _TeamMemberEditLoader({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerSalesTeamEditProvider(member.uuid));
    return state.when(
      loading: () => _SheetShell(
        title: 'Edit Team Member',
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator(color: _T.brand)),
        ),
      ),
      error: (error, _) => _SheetShell(
        title: 'Edit Team Member',
        child: _ErrorCard(
          message: _cleanError(error),
          onRetry: () =>
              ref.invalidate(sellerSalesTeamEditProvider(member.uuid)),
        ),
      ),
      data: (data) => _TeamMemberSheet(member: data.member),
    );
  }
}

class _TeamMemberSheetState extends ConsumerState<_TeamMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _cityId;
  late final TextEditingController _areaId;
  String _memberType = 'sales';
  bool _active = true;
  bool _saving = false;

  bool get _editing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _name = TextEditingController(text: member?.user.name ?? '');
    _email = TextEditingController(text: member?.user.email ?? '');
    _phone = TextEditingController(text: member?.user.phone ?? '');
    _cityId = TextEditingController(text: (member?.cityId ?? 1).toString());
    _areaId = TextEditingController(text: (member?.areaId ?? 1).toString());
    _memberType = member?.memberType == 'recovery' ? 'recovery' : 'sales';
    _active = member?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _cityId.dispose();
    _areaId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(sellerSalesTeamRepositoryProvider);
      if (_editing) {
        await repo.updateMember(
          memberUuid: widget.member!.uuid,
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          memberType: _memberType,
          cityId: _cityId.text.trim(),
          areaId: _areaId.text.trim(),
          active: _active,
        );
      } else {
        await repo.storeMember(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          memberType: _memberType,
          cityId: _cityId.text.trim(),
          areaId: _areaId.text.trim(),
          active: _active,
        );
      }
      if (!mounted) return;
      SnackbarService().showSuccessSnackBar(
        _editing ? 'Team member updated.' : 'Team member added.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: _editing ? 'Edit Team Member' : 'Add Team Member',
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
              controller: _email,
              label: 'Email',
              enabled: !_saving && !_editing,
              keyboardType: TextInputType.emailAddress,
              validator: _editing ? null : _emailValidator,
            ),
            _SheetTextField(
              controller: _phone,
              label: 'Phone',
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              validator: _phoneValidator,
            ),
            DropdownButtonFormField<String>(
              initialValue: _memberType,
              decoration: _sheetDecoration('Member Type'),
              items: const [
                DropdownMenuItem(value: 'sales', child: Text('Sales')),
                DropdownMenuItem(value: 'recovery', child: Text('Recovery')),
              ],
              onChanged: _saving
                  ? null
                  : (value) =>
                        setState(() => _memberType = value ?? _memberType),
            ),
            const SizedBox(height: 12),
            _SheetTextField(
              controller: _cityId,
              label: 'City ID',
              enabled: !_saving,
              keyboardType: TextInputType.number,
              validator: _required,
            ),
            _SheetTextField(
              controller: _areaId,
              label: 'Area ID',
              enabled: !_saving,
              keyboardType: TextInputType.number,
              validator: _required,
            ),
            SwitchListTile.adaptive(
              value: _active,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _active = value),
              title: const Text(
                'Active',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            _SheetButton(
              label: _editing ? 'Update Member' : 'Save Member',
              loading: _saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberHero extends StatelessWidget {
  final SellerSalesTeamMember member;

  const _MemberHero({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: _T.brand.withValues(alpha: 0.1),
            child: Text(
              _initials(member.user.name),
              style: const TextStyle(
                color: _T.brand,
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
                  member.user.name,
                  style: const TextStyle(
                    color: _T.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${member.memberType} - ${member.user.phone}',
                  style: const TextStyle(
                    color: _T.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsSection extends StatelessWidget {
  final Map<String, String> metrics;

  const _MetricsSection({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        children: metrics.entries
            .map((entry) => _InfoRow(label: entry.key, value: entry.value))
            .toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _T.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _T.text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
          color: _T.surface,
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
                      color: _T.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: _T.text,
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
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
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
          backgroundColor: _T.brand,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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

class _RangeStrip extends StatelessWidget {
  final int total;
  final int? from;
  final int? to;

  const _RangeStrip({
    required this.total,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Team Members',
              style: TextStyle(
                color: _T.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            total == 0 ? '0 records' : '${from ?? 0}-${to ?? 0} of $total',
            style: const TextStyle(
              color: _T.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final SellerSalesTeamPagination pagination;
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
    return Row(
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
              color: _T.muted,
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
    );
  }
}

class _TeamSkeleton extends StatelessWidget {
  const _TeamSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          height: 178,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _T.border),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: _T.brand),
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
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: _T.danger),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _T.text, fontWeight: FontWeight.w700),
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
  final String label;

  const _EmptyState({this.label = 'No team members found.'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.groups_2_outlined, color: _T.muted, size: 32),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: _T.text, fontWeight: FontWeight.w900),
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
    fillColor: _T.surfaceAlt,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _T.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _T.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _T.brand, width: 1.4),
    ),
  );
}

List<SellerSalesTeamMember> _filter(
  List<SellerSalesTeamMember> members,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return members;
  return members
      .where((member) {
        return member.user.name.toLowerCase().contains(q) ||
            member.user.email.toLowerCase().contains(q) ||
            member.user.phone.toLowerCase().contains(q) ||
            member.memberType.toLowerCase().contains(q) ||
            member.memberRole.toLowerCase().contains(q);
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

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'T';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
      .toUpperCase();
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
