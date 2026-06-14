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
                            value: () {
                              final raw = bundle.sellerInfo.previousExperience.trim();
                              final n = int.tryParse(raw);
                              if (n == null) return raw;
                              return '$n ${n == 1 ? 'year' : 'years'}';
                            }(),
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
                      child: _CoverageAreas(
                        areas: bundle.sellerInfo.activeAreas,
                      ),
                    ),
                    const Gap.v(AppSpace.lg),

                    // ── Settings ──────────────────────────────────────────
                    const SellerSectionHeader(
                      overline: 'Appearance',
                      title: 'Settings',
                    ),
                    const Gap.v(AppSpace.sm),
                    SellerCard(
                      child: Row(
                        children: [
                          SellerIconBadge(
                            icon: c.isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            tone: c.infoTone,
                          ),
                          const Gap.h(AppSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dark Mode',
                                  style: context.sellerText.titleSm,
                                ),
                                const Gap.v(AppSpace.xxs),
                                Text(
                                  c.isDark ? 'Currently dark' : 'Currently light',
                                  style: context.sellerText.bodySm,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: c.isDark,
                            onChanged: (_) => ref
                                .read(sellerThemeModeProvider.notifier)
                                .toggle(),
                            activeThumbColor: c.accent,
                          ),
                        ],
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
      title: seller.businessName,
      subtitle: bundle.profile.email,
      actions: [
        GestureDetector(
          onTap: onPickImage,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SellerMonogram(
                name: bundle.profile.name,
                imageUrl: bundle.profile.profilePictureUrl,
                size: 36,
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 11,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
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
//  COVERAGE AREAS
// ═══════════════════════════════════════════════════════════
class _CoverageAreas extends StatefulWidget {
  final List<SellerLookupOption> areas;
  const _CoverageAreas({required this.areas});

  @override
  State<_CoverageAreas> createState() => _CoverageAreasState();
}

class _CoverageAreasState extends State<_CoverageAreas> {
  static const _previewCount = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final areas = widget.areas;

    if (areas.isEmpty) {
      return Text('No active areas assigned yet.', style: text.bodySm);
    }

    final showAll = _expanded || areas.length <= _previewCount;
    final visible = showAll ? areas : areas.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: visible
              .map((area) => SellerStatusPill(
                    label: area.title,
                    tone: c.accentTone,
                    showDot: false,
                  ))
              .toList(),
        ),
        if (!showAll) ...[
          const Gap.v(AppSpace.sm),
          GestureDetector(
            onTap: () => setState(() => _expanded = true),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See ${areas.length - _previewCount} more',
                  style: text.labelSm.copyWith(color: c.accent),
                ),
                const Gap.h(AppSpace.xxs),
                Icon(Icons.expand_more_rounded, size: 16, color: c.accent),
              ],
            ),
          ),
        ] else if (_expanded) ...[
          const Gap.v(AppSpace.sm),
          GestureDetector(
            onTap: () => setState(() => _expanded = false),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See less',
                  style: text.labelSm.copyWith(color: c.accent),
                ),
                const Gap.h(AppSpace.xxs),
                Icon(Icons.expand_less_rounded, size: 16, color: c.accent),
              ],
            ),
          ),
        ],
      ],
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
    useSafeArea: true,
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
    useSafeArea: true,
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
    useSafeArea: true,
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
    useSafeArea: true,
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
  late Set<int> _selectedAreaIds;
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
    _selectedAreaIds = widget.bundle.businessInfo.sellerAreaIds.toSet();
  }

  @override
  void dispose() {
    _businessName.dispose();
    _investment.dispose();
    _experience.dispose();
    _cityId.dispose();
    _address.dispose();
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
            areaIds: _selectedAreaIds.toList(),
          ),
      success: 'Business info updated.',
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cityCount = widget.bundle.businessInfo.cities.length;
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
            _AreaSelector(
              all: widget.bundle.businessInfo.areas,
              selectedIds: _selectedAreaIds,
              onToggle: _saving
                  ? null
                  : (id) => setState(() {
                        if (_selectedAreaIds.contains(id)) {
                          _selectedAreaIds.remove(id);
                        } else {
                          _selectedAreaIds.add(id);
                        }
                      }),
            ),
            const Gap.v(AppSpace.sm),
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
//  AREA SELECTOR
// ═══════════════════════════════════════════════════════════
class _AreaSelector extends StatefulWidget {
  final List<SellerLookupOption> all;
  final Set<int> selectedIds;
  final void Function(int id)? onToggle;

  const _AreaSelector({
    required this.all,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  State<_AreaSelector> createState() => _AreaSelectorState();
}

class _AreaSelectorState extends State<_AreaSelector> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    final selected = widget.all
        .where((a) => widget.selectedIds.contains(a.id))
        .toList();
    final available = widget.all
        .where((a) => !widget.selectedIds.contains(a.id))
        .where((a) =>
            _query.isEmpty ||
            a.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Coverage Areas',
              style: text.bodyLg.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brPill,
                ),
                child: Text(
                  '${selected.length} selected',
                  style: text.labelSm.copyWith(color: c.accent),
                ),
              ),
          ],
        ),
        if (selected.isNotEmpty) ...[
          const Gap.v(AppSpace.sm),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: selected
                .map((a) => _AreaChip(
                      label: a.title,
                      selected: true,
                      onTap: widget.onToggle == null
                          ? null
                          : () => widget.onToggle!(a.id),
                    ))
                .toList(),
          ),
          const Gap.v(AppSpace.sm),
          Divider(color: c.divider),
        ],
        const Gap.v(AppSpace.sm),
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          style: TextStyle(color: c.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search areas…',
            hintStyle: TextStyle(color: c.textTertiary, fontSize: 14),
            prefixIcon:
                Icon(Icons.search_rounded, color: c.textSecondary, size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: c.textSecondary, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: c.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppSpace.sm,
              horizontal: AppSpace.sm,
            ),
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
              borderSide: BorderSide(color: c.accent, width: 1.5),
            ),
          ),
        ),
        const Gap.v(AppSpace.sm),
        if (available.isEmpty)
          Text(
            _query.isEmpty
                ? 'All areas selected'
                : 'No areas match "$_query"',
            style: text.bodySm.copyWith(color: c.textTertiary),
          )
        else ...[
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: available
                .take(60)
                .map((a) => _AreaChip(
                      label: a.title,
                      selected: false,
                      onTap: widget.onToggle == null
                          ? null
                          : () => widget.onToggle!(a.id),
                    ))
                .toList(),
          ),
          if (available.length > 60) ...[
            const Gap.v(AppSpace.xs),
            Text(
              '+ ${available.length - 60} more — search to narrow down',
              style: text.caption.copyWith(color: c.textTertiary),
            ),
          ],
        ],
      ],
    );
  }
}

class _AreaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _AreaChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Material(
      color: selected ? c.accent.withValues(alpha: 0.10) : Colors.transparent,
      borderRadius: AppRadius.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xxs + 2,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? c.accent : c.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: AppRadius.brPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 12, color: c.accent),
                const Gap.h(AppSpace.xxs),
              ],
              Text(
                label,
                style: text.labelSm.copyWith(
                  color: selected ? c.accent : c.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (selected) ...[
                const Gap.h(AppSpace.xxs),
                Icon(Icons.close_rounded,
                    size: 12, color: c.accent.withValues(alpha: 0.7)),
              ],
            ],
          ),
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
                const Gap.v(AppSpace.sm),
                Row(
                  children: [
                    Expanded(child: Text(title, style: text.titleMd)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c.surfaceAlt,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
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


String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
