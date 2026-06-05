import 'dart:io';

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/auth/viewmodel/seller_auth_viewmodel.dart';
import 'package:atompro/features/seller/fee_charge/view/seller_fee_charge_screen.dart';
import 'package:atompro/features/seller/investments/view/seller_investments_screen.dart';
import 'package:atompro/features/seller/profile/model/seller_profile_model.dart';
import 'package:atompro/features/seller/profile/repository/seller_profile_repository.dart';
import 'package:atompro/features/seller/profile/viewmodel/seller_profile_viewmodel.dart';
import 'package:atompro/features/seller/sales_team/view/seller_sales_team_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

abstract final class _P {
  static const bg = Color(0xFFF4F6FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFE);
  static const brand = Color(0xFF3B5BDB);
  static const brandDark = Color(0xFF1A2980);
  static const text = Color(0xFF101828);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE4E8F5);
  static const danger = Color(0xFFEF4444);
}

class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerProfileBundleProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _P.bg,
        body: SafeArea(
          child: state.when(
            loading: () => const _LoadingView(),
            error: (error, _) => _ErrorView(
              message: _cleanError(error),
              onRetry: () => ref.invalidate(sellerProfileBundleProvider),
            ),
            data: (bundle) => RefreshIndicator(
              color: _P.brand,
              onRefresh: () async {
                ref.invalidate(sellerProfileBundleProvider);
                await ref.read(sellerProfileBundleProvider.future);
              },
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  _Header(
                    bundle: bundle,
                    onPickImage: () => _updatePicture(context, ref),
                    onLogout: () => _confirmLogout(context, ref),
                  ),
                  const SizedBox(height: 14),

                  // ACCOUNT
                  _SectionCard(
                    title: 'Account',
                    icon: Icons.person_outline_rounded,
                    trailing: _EditButton(
                      onTap: () =>
                          _showUserInfoSheet(context, ref, bundle),
                    ),
                    child: Column(
                      children: [
                        _GRow('Name', bundle.profile.name,
                            'Phone', bundle.profile.phone),
                        _GRow('Email', bundle.profile.email,
                            'Status', bundle.profile.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // SELLER INFO
                  _SectionCard(
                    title: 'Seller Info',
                    icon: Icons.badge_outlined,
                    trailing: _EditButton(
                      onTap: () =>
                          _showSellerInfoSheet(context, ref, bundle),
                    ),
                    child: Column(
                      children: [
                        _GRow('Seller Code', bundle.sellerInfo.code,
                            'CNIC', bundle.sellerInfo.cnicNumber),
                        _GRow('Website', bundle.sellerInfo.website,
                            'WhatsApp', bundle.sellerInfo.whatsappPhone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // BUSINESS INFO
                  _SectionCard(
                    title: 'Business Info',
                    icon: Icons.storefront_outlined,
                    trailing: _EditButton(
                      onTap: () =>
                          _showBusinessInfoSheet(context, ref, bundle),
                    ),
                    child: Column(
                      children: [
                        _GRow('Business', bundle.sellerInfo.businessName,
                            'City', bundle.sellerInfo.cityTitle),
                        _GRow('Address', bundle.sellerInfo.address,
                            'Investment', bundle.sellerInfo.investmentCapacity),
                        _GRow('Experience',
                            bundle.sellerInfo.previousExperience,
                            'Business Phone',
                            bundle.sellerInfo.businessPhone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ACTIVE COVERAGE AREAS — own section, always visible
                  _SectionCard(
                    title: 'Active Coverage Areas',
                    icon: Icons.location_on_outlined,
                    child: bundle.sellerInfo.activeAreas.isEmpty
                        ? const Text(
                            'No active areas assigned yet.',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: bundle.sellerInfo.activeAreas
                                .map(
                                  (area) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _P.brand.withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            _P.brand.withValues(alpha: 0.20),
                                      ),
                                    ),
                                    child: Text(
                                      area.title,
                                      style: const TextStyle(
                                        color: _P.brand,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // SECURITY
                  _SecurityCard(
                    onChangePassword: () =>
                        _showPasswordSheet(context, ref),
                  ),
                  const SizedBox(height: 12),

                  // QUICK ACTIONS
                  _ProfileActionCard(
                    icon: Icons.groups_2_outlined,
                    title: 'Sales Team',
                    subtitle: 'Manage sales and recovery members',
                    color: _P.brand,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SellerSalesTeamScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ProfileActionCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Fee Charge',
                    subtitle: 'Review seller fees and payments',
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SellerFeeChargeScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ProfileActionCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Investments',
                    subtitle: 'Track investment records and status',
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SellerInvestmentsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updatePicture(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return;

    try {
      await ref
          .read(sellerProfileRepositoryProvider)
          .updateProfilePicture(File(picked.path));
      ref.invalidate(sellerProfileBundleProvider);
      SnackbarService().showSuccessSnackBar('Profile picture updated.');
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout from Seller Mode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(sellerAuthViewModelProvider.notifier).logout();
  }
}

class _Header extends StatelessWidget {
  final SellerProfileBundle bundle;
  final VoidCallback onPickImage;
  final VoidCallback onLogout;

  const _Header({
    required this.bundle,
    required this.onPickImage,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final seller = bundle.sellerInfo;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_P.brandDark, _P.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _P.brand.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                child: Text(
                  _initials(bundle.profile.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              _HeaderIconButton(
                tooltip: 'Change picture',
                icon: Icons.photo_camera_outlined,
                onTap: onPickImage,
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                tooltip: 'Logout',
                icon: Icons.logout_rounded,
                onTap: onLogout,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            seller.businessName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bundle.profile.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(
                icon: Icons.verified_outlined,
                label: seller.verified ? 'Verified' : 'Not verified',
                accentColor: seller.verified
                    ? const Color(0xFF10B981)  // green when verified
                    : const Color(0xFFF59E0B), // amber when not
              ),
              if (seller.topRated)
                const _HeaderChip(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Top rated',
                ),
              _HeaderChip(icon: Icons.qr_code_2_rounded, label: seller.code),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
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

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accentColor; // when set, uses colored bg instead of white

  const _HeaderChip({
    required this.icon,
    required this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = accentColor ?? Colors.white;
    final bgAlpha = accentColor != null ? 0.20 : 0.12;
    final borderAlpha = accentColor != null ? 0.40 : 0.16;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: borderAlpha)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable section card ────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
            decoration: BoxDecoration(
              color: _P.brand.withValues(alpha: 0.05),
              border: const Border(bottom: BorderSide(color: _P.border)),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: _P.brand),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: _P.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _P.brand.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, size: 12, color: _P.brand),
            SizedBox(width: 4),
            Text(
              'Edit',
              style: TextStyle(
                color: _P.brand,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2-column grid ────────────────────────────────────────────────────────────
class _GRow extends StatelessWidget {
  final String l1, v1, l2, v2;
  const _GRow(this.l1, this.v1, this.l2, this.v2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _GCell(label: l1, value: v1)),
          if (l2.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(child: _GCell(label: l2, value: v2)),
          ],
        ],
      ),
    );
  }
}

class _GCell extends StatelessWidget {
  final String label;
  final String value;
  const _GCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _P.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty || value == 'Not available' ? '—' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _P.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final VoidCallback onChangePassword;

  const _SecurityCard({required this.onChangePassword});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _P.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _P.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.lock_outline_rounded, color: _P.danger),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security',
                  style: TextStyle(
                    color: _P.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Manage seller account password',
                  style: TextStyle(
                    color: _P.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onChangePassword,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _P.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _P.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _P.muted),
          ],
        ),
      ),
    );
  }
}

Future<void> _showUserInfoSheet(
  BuildContext context,
  WidgetRef ref,
  SellerProfileBundle bundle,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _UserInfoSheet(bundle: bundle),
  );
}

Future<void> _showSellerInfoSheet(
  BuildContext context,
  WidgetRef ref,
  SellerProfileBundle bundle,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SellerInfoSheet(bundle: bundle),
  );
}

Future<void> _showBusinessInfoSheet(
  BuildContext context,
  WidgetRef ref,
  SellerProfileBundle bundle,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BusinessInfoSheet(bundle: bundle),
  );
}

Future<void> _showPasswordSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PasswordSheet(),
  );
}

class _UserInfoSheet extends ConsumerStatefulWidget {
  final SellerProfileBundle bundle;

  const _UserInfoSheet({required this.bundle});

  @override
  ConsumerState<_UserInfoSheet> createState() => _UserInfoSheetState();
}

class _UserInfoSheetState extends ConsumerState<_UserInfoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.bundle.profile;
    _name = TextEditingController(text: profile.name);
    _email = TextEditingController(text: profile.email);
    _phone = TextEditingController(text: profile.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _submitMutation(
      ref: ref,
      setSaving: (value) => setState(() => _saving = value),
      mutation: () => ref
          .read(sellerProfileRepositoryProvider)
          .updateUserInfo(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
          ),
      success: 'Profile updated.',
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Edit Account',
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
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            _SheetTextField(
              controller: _phone,
              label: 'Phone',
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              validator: _required,
            ),
            _SheetButton(label: 'Save Account', loading: _saving, onTap: _save),
          ],
        ),
      ),
    );
  }
}

class _SellerInfoSheet extends ConsumerStatefulWidget {
  final SellerProfileBundle bundle;

  const _SellerInfoSheet({required this.bundle});

  @override
  ConsumerState<_SellerInfoSheet> createState() => _SellerInfoSheetState();
}

class _SellerInfoSheetState extends ConsumerState<_SellerInfoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _cnic;
  late final TextEditingController _website;
  late String _feeType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seller = widget.bundle.sellerInfo;
    _name = TextEditingController(text: seller.name);
    _cnic = TextEditingController(text: seller.cnicNumber);
    _website = TextEditingController(
      text: seller.website == 'Not available' ? '' : seller.website,
    );
    _feeType = seller.feeChargeType == 'fixed' ? 'fixed' : 'percentage';
  }

  @override
  void dispose() {
    _name.dispose();
    _cnic.dispose();
    _website.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _submitMutation(
      ref: ref,
      setSaving: (value) => setState(() => _saving = value),
      mutation: () => ref
          .read(sellerProfileRepositoryProvider)
          .updateSellerInfo(
            name: _name.text.trim(),
            cnicNumber: _cnic.text.trim(),
            website: _website.text.trim(),
            feeChargeType: _feeType,
          ),
      success: 'Seller info updated.',
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Edit Seller Info',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _SheetTextField(
              controller: _name,
              label: 'Seller Name',
              enabled: !_saving,
              validator: _required,
            ),
            _SheetTextField(
              controller: _cnic,
              label: 'CNIC',
              enabled: !_saving,
              validator: _required,
            ),
            _SheetTextField(
              controller: _website,
              label: 'Website',
              enabled: !_saving,
            ),
            DropdownButtonFormField<String>(
              initialValue: _feeType,
              decoration: _sheetDecoration('Fee Charge Type'),
              items: const [
                DropdownMenuItem(
                  value: 'percentage',
                  child: Text('Percentage'),
                ),
                DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _feeType = value ?? _feeType),
            ),
            const SizedBox(height: 14),
            _SheetButton(
              label: 'Save Seller Info',
              loading: _saving,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessInfoSheet extends ConsumerStatefulWidget {
  final SellerProfileBundle bundle;

  const _BusinessInfoSheet({required this.bundle});

  @override
  ConsumerState<_BusinessInfoSheet> createState() => _BusinessInfoSheetState();
}

class _BusinessInfoSheetState extends ConsumerState<_BusinessInfoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessName;
  late final TextEditingController _investment;
  late final TextEditingController _experience;
  late final TextEditingController _cityId;
  late final TextEditingController _address;
  late final TextEditingController _areaIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seller = widget.bundle.sellerInfo;
    final business = widget.bundle.businessInfo;
    _businessName = TextEditingController(text: seller.businessName);
    _investment = TextEditingController(text: seller.investmentCapacity);
    _experience = TextEditingController(text: seller.previousExperience);
    _cityId = TextEditingController(
      text: (business.sellerCityId == 0 ? seller.cityId : business.sellerCityId)
          .toString(),
    );
    _address = TextEditingController(text: seller.address);
    _areaIds = TextEditingController(text: business.sellerAreaIds.join(', '));
  }

  @override
  void dispose() {
    _businessName.dispose();
    _investment.dispose();
    _experience.dispose();
    _cityId.dispose();
    _address.dispose();
    _areaIds.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _submitMutation(
      ref: ref,
      setSaving: (value) => setState(() => _saving = value),
      mutation: () => ref
          .read(sellerProfileRepositoryProvider)
          .updateBusinessInfo(
            businessName: _businessName.text.trim(),
            investmentCapacity: _investment.text.trim(),
            previousExperience: _experience.text.trim(),
            cityId: _cityId.text.trim(),
            address: _address.text.trim(),
            areaIds: _parseIds(_areaIds.text),
          ),
      success: 'Business info updated.',
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cityCount = widget.bundle.businessInfo.cities.length;
    final areaCount = widget.bundle.businessInfo.areas.length;
    return _SheetShell(
      title: 'Edit Business Info',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _SheetTextField(
              controller: _businessName,
              label: 'Business Name',
              enabled: !_saving,
              validator: _required,
            ),
            _SheetTextField(
              controller: _investment,
              label: 'Investment Capacity',
              enabled: !_saving,
              validator: _required,
            ),
            _SheetTextField(
              controller: _experience,
              label: 'Previous Experience',
              enabled: !_saving,
              validator: _required,
            ),
            _SheetTextField(
              controller: _cityId,
              label: 'City ID ($cityCount available)',
              enabled: !_saving,
              keyboardType: TextInputType.number,
              validator: _required,
            ),
            _SheetTextField(
              controller: _address,
              label: 'Address',
              enabled: !_saving,
              maxLines: 3,
              validator: _required,
            ),
            _SheetTextField(
              controller: _areaIds,
              label: 'Area IDs ($areaCount available, comma separated)',
              enabled: !_saving,
              keyboardType: TextInputType.text,
              validator: _required,
            ),
            _SheetButton(
              label: 'Save Business Info',
              loading: _saving,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordSheet extends ConsumerStatefulWidget {
  const _PasswordSheet();

  @override
  ConsumerState<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends ConsumerState<_PasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _submitMutation(
      ref: ref,
      setSaving: (value) => setState(() => _saving = value),
      mutation: () => ref
          .read(sellerProfileRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
            confirmNewPassword: _confirm.text,
          ),
      success: 'Password changed.',
      context: context,
      invalidateProfile: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Change Password',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _SheetTextField(
              controller: _current,
              label: 'Current Password',
              enabled: !_saving,
              obscureText: true,
              validator: _required,
            ),
            _SheetTextField(
              controller: _new,
              label: 'New Password',
              enabled: !_saving,
              obscureText: true,
              validator: (value) {
                if ((value ?? '').length < 8) {
                  return 'Password must be at least 8 characters.';
                }
                return null;
              },
            ),
            _SheetTextField(
              controller: _confirm,
              label: 'Confirm New Password',
              enabled: !_saving,
              obscureText: true,
              validator: (value) {
                if (value != _new.text) return 'Passwords do not match.';
                return null;
              },
            ),
            _SheetButton(
              label: 'Change Password',
              loading: _saving,
              onTap: _save,
            ),
          ],
        ),
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
          color: _P.surface,
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
                      color: _P.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: _P.text,
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
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.obscureText = false,
    this.maxLines = 1,
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
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
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
          backgroundColor: _P.brand,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: _P.brand));
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _P.danger, size: 34),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _P.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _sheetDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: _P.surfaceAlt,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _P.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _P.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _P.brand, width: 1.4),
    ),
  );
}

Future<void> _submitMutation({
  required WidgetRef ref,
  required ValueChanged<bool> setSaving,
  required Future<void> Function() mutation,
  required String success,
  required BuildContext context,
  bool invalidateProfile = true,
}) async {
  setSaving(true);
  try {
    await mutation();
    if (invalidateProfile) ref.invalidate(sellerProfileBundleProvider);
    if (context.mounted) Navigator.pop(context);
    SnackbarService().showSuccessSnackBar(success);
  } catch (e) {
    SnackbarService().showErrorSnackBar(_cleanError(e));
  } finally {
    setSaving(false);
  }
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

List<int> _parseIds(String value) {
  return value
      .split(',')
      .map((item) => int.tryParse(item.trim()) ?? 0)
      .where((item) => item > 0)
      .toList(growable: false);
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'S';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts[1].characters.first}'
      .toUpperCase();
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
