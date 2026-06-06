// ============================================================
//  seller_profile_screen.dart  —  v2 (Design System)
//
//  Rebuilt on the Seller Design System: unified tokens, colour
//  extension (light + dark), shared component library. 100% of
//  business logic, providers, API calls and navigation are
//  preserved — only presentation / styling has changed.
// ============================================================

import 'dart:io';

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/auth/viewmodel/seller_auth_viewmodel.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/fee_charge/view/seller_fee_charge_screen.dart';
import 'package:atompro/features/seller/investments/view/seller_investments_screen.dart';
import 'package:atompro/features/seller/profile/model/seller_profile_model.dart';
import 'package:atompro/features/seller/profile/repository/seller_profile_repository.dart';
import 'package:atompro/features/seller/profile/viewmodel/seller_profile_viewmodel.dart';
import 'package:atompro/features/seller/sales_team/view/seller_sales_team_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atompro/features/seller/subscription/view/seller_subscription_screen.dart';
import 'package:image_picker/image_picker.dart';

// ═══════════════════════════════════════════════════════════
//  ROOT SCREEN
// ═══════════════════════════════════════════════════════════
class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sellerColors;
    final state = ref.watch(sellerProfileBundleProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      body: state.when(
        loading: () => const _ProfileSkeleton(),
        error: (error, _) => SafeArea(
          child: SellerErrorState(
            message: _cleanError(error),
            onRetry: () => ref.invalidate(sellerProfileBundleProvider),
          ),
        ),
        data: (bundle) => Column(
          children: [
            _ProfileHeader(
              bundle: bundle,
              onPickImage: () => _updatePicture(context, ref),
              onLogout: () => _confirmLogout(context, ref),
            ),
            Expanded(
              child: RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerProfileBundleProvider);
                  await ref.read(sellerProfileBundleProvider.future);
                },
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: AppInsets.pageWithNav,
                  children: [
                    // ── Account ──────────────────────────────────────────
                    SellerSectionHeader(
                      overline: 'User',
                      title: 'Account',
                      actionLabel: 'Edit',
                      actionIcon: Icons.edit_outlined,
                      onAction: () =>
                          _showUserInfoSheet(context, ref, bundle),
                    ),
                    const Gap.v(AppSpace.sm),
                    SellerCard(
                      child: Column(
                        children: [
                          SellerDataRow(
                            label: 'Name',
                            value: bundle.profile.name,
                          ),
                          Divider(color: c.divider, height: 1),
                          SellerDataRow(
                            label: 'Phone',
                            value: bundle.profile.phone,
                          ),
                          Divider(color: c.divider, height: 1),
                          SellerDataRow(
                            label: 'Email',
                            value: bundle.profile.email,
                          ),
                          Divider(color: c.divider, height: 1),
                          SellerDataRow(
                            label: 'Status',
                            value: bundle.profile.status,
                          ),
                        ],
                      ),
                    ),
                    const Gap.v(AppSpace.lg),

                    // ── Seller Info ───────────────────────────────────────
                    SellerSectionHeader(
                      overline: 'Identity',
                      title: 'Seller Info',
                      actionLabel: 'Edit',
                      actionIcon: Icons.edit_outlined,
                      onAction: () =>
                          _showSellerInfoSheet(context, ref, bundle),
                    ),
                    const Gap.v(AppSpace.sm),
                    SellerCard(
                      child: Column(
                        children: [
                          SellerDataRow(
                            label: 'Seller Code',
                            value: bundle.sellerInfo.code,
                          ),
                          Divider(color: c.divider, height: 1),
                          SellerDataRow(
                            label: 'CNIC',
                            value: bundle.sellerInfo.cnicNumber,
                          ),
                          Divider(color: c.divider, height: 1),
                          SellerDataRow(
                            label: 'Website',
                            value: bundle.sellerInfo.website,
                          ),
                          Divider(color: c.divider, height: 1),
                          SellerDataRow(
                            label: 'WhatsApp',
                            value: bundle.sellerInfo.whatsappPhone,
                          ),
                        ],
                      ),
                    ),
                    const Gap.v(AppSpace.lg),

                    // ── Business Info ─────────────────────────────────────
                    SellerSectionHeader(
                      overline: 'Store',
                      title: 'Business Info',
                      actionLabel: 'Edit',
                      actionIcon: Icons.edit_outlined,
                      onAction: () =>
                          _showBusinessInfoSheet(context, ref, bundle),
                    ),
                    const Gap.v(AppSpace.sm),
                    SellerCard(
                      child: Column(
                        children: [
                          SellerDataRow(
                            label: 'Business',
                            value: bundle.sellerInfo.businessName,
                          ),
                          Divider(color: c.divider, height: 1),
                          SellerDataRow(
                            label: 'City',
                            value: bundle.sellerInfo.cityTitle,
                          ),
                          Divider(color: c.divider, height: 1),
                          SellerDataRow(
                            label: 'Address',
                            value: bundle.sellerInfo.address,
                          ),
                          Divider(color: c.divider, height: 1),
                          SellerDataRow(
                            label: 'Investment',
                            value: bundle.sellerInfo.investmentCapacity,
                          ),
                          Divider(color: c.divider, height: 1),
                          SellerDataRow(
                            label: 'Experience',
                            value: bundle.sellerInfo.previousExperience,
                          ),
                          Divider(color: c.divider, height: 1),
                          SellerDataRow(
                            label: 'Business Phone',
                            value: bundle.sellerInfo.businessPhone,
                          ),
                        ],
                      ),
                    ),
                    const Gap.v(AppSpace.lg),

                    // ── Active Coverage Areas ─────────────────────────────
                    const SellerSectionHeader(
                      overline: 'Logistics',
                      title: 'Active Coverage Areas',
                    ),
                    const Gap.v(AppSpace.sm),
                    SellerCard(
                      child: bundle.sellerInfo.activeAreas.isEmpty
                          ? Text(
                              'No active areas assigned yet.',
                              style: context.sellerText.bodySm,
                            )
                          : Wrap(
                              spacing: AppSpace.xs,
                              runSpacing: AppSpace.xs,
                              children: bundle.sellerInfo.activeAreas
                                  .map(
                                    (area) => SellerStatusPill(
                                      label: area.title,
                                      tone: c.accentTone,
                                      showDot: false,
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const Gap.v(AppSpace.lg),

                    // ── Security ──────────────────────────────────────────
                    const SellerSectionHeader(
                      overline: 'Privacy',
                      title: 'Security',
                    ),
                    const Gap.v(AppSpace.sm),
                    SellerCard(
                      onTap: () => _showPasswordSheet(context, ref),
                      child: Row(
                        children: [
                          SellerIconBadge(
                            icon: Icons.lock_outline_rounded,
                            tone: c.dangerTone,
                          ),
                          const Gap.h(AppSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Change Password',
                                  style: context.sellerText.titleSm,
                                ),
                                const Gap.v(AppSpace.xxs),
                                Text(
                                  'Manage seller account password',
                                  style: context.sellerText.bodySm,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: c.textTertiary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const Gap.v(AppSpace.lg),

                    // ── Quick Actions ─────────────────────────────────────
                    const SellerSectionHeader(
                      overline: 'Navigation',
                      title: 'Quick Actions',
                    ),
                    const Gap.v(AppSpace.sm),
                    _QuickActionCard(
                      icon: Icons.workspace_premium_outlined,
                      title: 'My Subscription Plan',
                      subtitle: 'View plan, pay fees & commission',
                      tone: c.violetTone,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerThemeScope(
                            child: Builder(
                              builder: (context) =>
                                  const SellerSubscriptionScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap.v(AppSpace.sm),
                    _QuickActionCard(
                      icon: Icons.groups_2_outlined,
                      title: 'Sales Team',
                      subtitle: 'Manage sales and recovery members',
                      tone: c.accentTone,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerThemeScope(
                            child: Builder(
                              builder: (context) =>
                                  const SellerSalesTeamScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap.v(AppSpace.sm),
                    _QuickActionCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Fee Charge',
                      subtitle: 'Review seller fees and payments',
                      tone: c.warningTone,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerThemeScope(
                            child: Builder(
                              builder: (context) =>
                                  const SellerFeeChargeScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap.v(AppSpace.sm),
                    _QuickActionCard(
                      icon: Icons.trending_up_rounded,
                      title: 'Investments',
                      subtitle: 'Track investment records and status',
                      tone: c.successTone,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerThemeScope(
                            child: Builder(
                              builder: (context) =>
                                  const SellerInvestmentsScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap.v(AppSpace.lg),

                    // ── Logout ────────────────────────────────────────────
                    SellerButton(
                      label: 'Log out',
                      variant: SellerButtonVariant.danger,
                      icon: Icons.logout_rounded,
                      onPressed: () => _confirmLogout(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    final ok = await _showLogoutDialog(context);
    if (ok == true && context.mounted) {
      await ref.read(sellerAuthViewModelProvider.notifier).logout();
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  HEADER
// ═══════════════════════════════════════════════════════════
class _ProfileHeader extends StatelessWidget {
  final SellerProfileBundle bundle;
  final VoidCallback onPickImage;
  final VoidCallback onLogout;

  const _ProfileHeader({
    required this.bundle,
    required this.onPickImage,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final seller = bundle.sellerInfo;

    return SellerGradientHeader(
      leading: SellerMonogram(name: bundle.profile.name, size: 46),
      title: seller.businessName,
      subtitle: bundle.profile.email,
      actions: [
        SellerHeaderIconButton(
          icon: Icons.photo_camera_outlined,
          onTap: onPickImage,
          tooltip: 'Change picture',
        ),
        SellerHeaderIconButton(
          icon: Icons.logout_rounded,
          onTap: onLogout,
          tooltip: 'Log out',
        ),
      ],
      bottom: Wrap(
        spacing: AppSpace.xs,
        runSpacing: AppSpace.xs,
        children: [
          _HeaderPill(
            icon: seller.verified
                ? Icons.verified_rounded
                : Icons.verified_outlined,
            label: seller.verified ? 'Verified' : 'Not verified',
            color: seller.verified ? c.success : c.warning,
          ),
          if (seller.topRated)
            const _HeaderPill(
              icon: Icons.workspace_premium_outlined,
              label: 'Top Rated',
            ),
          _HeaderPill(
            icon: Icons.qr_code_2_rounded,
            label: seller.code,
          ),
        ],
      ),
    );
  }
}

/// A frosted pill chip for the gradient header bottom row.
class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;

  /// When provided, tints the pill with this colour instead of white.
  final Color? color;

  const _HeaderPill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: color != null ? 0.18 : 0.12),
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: fg.withValues(alpha: color != null ? 0.35 : 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 13),
          const Gap.h(AppSpace.xxs + 1),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  QUICK ACTION CARD
// ═══════════════════════════════════════════════════════════
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final SellerTone tone;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return SellerCard(
      onTap: onTap,
      child: Row(
        children: [
          SellerIconBadge(icon: icon, tone: tone),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSm),
                const Gap.v(AppSpace.xxs),
                Text(subtitle, style: text.bodySm),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.textTertiary, size: 20),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SKELETON
// ═══════════════════════════════════════════════════════════
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return Column(
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: c.headerGradient,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.xxl),
            ),
          ),
        ),
        const Gap.v(AppSpace.md),
        Expanded(
          child: SellerShimmer(
            child: ListView(
              padding: AppInsets.pageWithNav,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _skelBox(c, 120),
                const Gap.v(AppSpace.md),
                _skelBox(c, 100),
                const Gap.v(AppSpace.md),
                _skelBox(c, 160),
                const Gap.v(AppSpace.md),
                _skelBox(c, 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _skelBox(SellerColors c, double h) => Container(
    height: h,
    decoration: BoxDecoration(
      color: c.surface,
      borderRadius: AppRadius.brLg,
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  LOGOUT DIALOG  (matches dashboard pattern)
// ═══════════════════════════════════════════════════════════
Future<bool?> _showLogoutDialog(BuildContext context) {
  final isDark = context.sellerIsDark;
  return showDialog<bool>(
    context: context,
    builder: (_) => Theme(
      data: isDark ? SellerTheme.dark : SellerTheme.light,
      child: Builder(
        builder: (context) {
          final c = context.sellerColors;
          final text = context.sellerText;
          return Dialog(
            backgroundColor: c.surface,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SellerIconBadge(
                    icon: Icons.logout_rounded,
                    tone: c.dangerTone,
                    size: 52,
                    iconSize: 26,
                    radius: AppRadius.lg,
                  ),
                  const Gap.v(AppSpace.md),
                  Text('Log out?', style: text.titleMd),
                  const Gap.v(AppSpace.xs),
                  Text(
                    'You will need to sign in again to access Seller Mode.',
                    textAlign: TextAlign.center,
                    style: text.bodySm,
                  ),
                  const Gap.v(AppSpace.lg),
                  Row(
                    children: [
                      Expanded(
                        child: SellerButton.secondary(
                          label: 'Cancel',
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const Gap.h(AppSpace.sm),
                      Expanded(
                        child: SellerButton(
                          label: 'Log out',
                          variant: SellerButtonVariant.danger,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  BOTTOM SHEETS — helpers
// ═══════════════════════════════════════════════════════════
Future<void> _showUserInfoSheet(
  BuildContext context,
  WidgetRef ref,
  SellerProfileBundle bundle,
) {
  final isDark = context.sellerIsDark;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: isDark ? SellerTheme.dark : SellerTheme.light,
      child: Builder(
        builder: (context) => _UserInfoSheet(bundle: bundle),
      ),
    ),
  );
}

Future<void> _showSellerInfoSheet(
  BuildContext context,
  WidgetRef ref,
  SellerProfileBundle bundle,
) {
  final isDark = context.sellerIsDark;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: isDark ? SellerTheme.dark : SellerTheme.light,
      child: Builder(
        builder: (context) => _SellerInfoSheet(bundle: bundle),
      ),
    ),
  );
}

Future<void> _showBusinessInfoSheet(
  BuildContext context,
  WidgetRef ref,
  SellerProfileBundle bundle,
) {
  final isDark = context.sellerIsDark;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: isDark ? SellerTheme.dark : SellerTheme.light,
      child: Builder(
        builder: (context) => _BusinessInfoSheet(bundle: bundle),
      ),
    ),
  );
}

Future<void> _showPasswordSheet(BuildContext context, WidgetRef ref) {
  final isDark = context.sellerIsDark;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: isDark ? SellerTheme.dark : SellerTheme.light,
      child: Builder(
        builder: (context) => const _PasswordSheet(),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  EDIT SHEETS
// ═══════════════════════════════════════════════════════════
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
      setSaving: (v) => setState(() => _saving = v),
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
            SellerButton(
              label: 'Save Account',
              icon: Icons.save_outlined,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
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
      setSaving: (v) => setState(() => _saving = v),
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
    final c = context.sellerColors;
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
              decoration: _sheetDecoration('Fee Charge Type', c),
              items: const [
                DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _feeType = value ?? _feeType),
            ),
            const Gap.v(AppSpace.md),
            SellerButton(
              label: 'Save Seller Info',
              icon: Icons.save_outlined,
              loading: _saving,
              onPressed: _saving ? null : _save,
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
      setSaving: (v) => setState(() => _saving = v),
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
              validator: _required,
            ),
            SellerButton(
              label: 'Save Business Info',
              icon: Icons.save_outlined,
              loading: _saving,
              onPressed: _saving ? null : _save,
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
      setSaving: (v) => setState(() => _saving = v),
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
            SellerButton(
              label: 'Change Password',
              icon: Icons.lock_reset_rounded,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SHEET SHELL
// ═══════════════════════════════════════════════════════════
class _SheetShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
          AppSpace.md,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.sheet,
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.borderStrong,
                      borderRadius: AppRadius.brPill,
                    ),
                  ),
                ),
                const Gap.v(AppSpace.md),
                Text(title, style: text.titleMd),
                const Gap.v(AppSpace.md),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SHEET TEXT FIELD
// ═══════════════════════════════════════════════════════════
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
    final c = context.sellerColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: context.sellerText.body,
        decoration: _sheetDecoration(label, c),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════
InputDecoration _sheetDecoration(String label, SellerColors c) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: c.textSecondary),
    filled: true,
    fillColor: c.surfaceAlt,
    border: OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: c.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: c.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: c.accent, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: c.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: c.danger, width: 1.4),
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

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
