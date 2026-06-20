import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/notification_settings/model/seller_notification_settings_model.dart';
import 'package:atompro/features/seller/notification_settings/viewmodel/seller_notification_settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Per-type display config ───────────────────────────────────────────────────

IconData _iconFor(String type) => switch (type) {
  'new_lead'              => Icons.person_add_outlined,
  'new_custom_order'      => Icons.shopping_bag_outlined,
  'instalment_due_today'  => Icons.calendar_today_outlined,
  'instalment_overdue'    => Icons.warning_amber_rounded,
  'subscription_expiring' => Icons.timer_outlined,
  'payment_confirmed'     => Icons.check_circle_outline,
  'account_verified'      => Icons.verified_user_outlined,
  'weekly_sales_summary'  => Icons.bar_chart_rounded,
  _                       => Icons.notifications_outlined,
};

SellerTone _toneFor(String type, SellerColors c) => switch (type) {
  'new_lead'              => c.accentTone,
  'new_custom_order'      => c.accentTone,
  'instalment_due_today'  => c.warningTone,
  'instalment_overdue'    => c.dangerTone,
  'subscription_expiring' => c.warningTone,
  'payment_confirmed'     => c.successTone,
  'account_verified'      => c.successTone,
  'weekly_sales_summary'  => c.infoTone,
  _                       => c.accentTone,
};

// Per-group left-edge accent and overline label
({Color edge, String overline}) _groupMeta(String group, SellerColors c) =>
    switch (group) {
      'Order Notifications' => (edge: c.accent,   overline: 'Sales'),
      'Financial Alerts'    => (edge: c.warning,  overline: 'Finance'),
      'Account & Plans'     => (edge: c.success,  overline: 'Account'),
      'Reports'             => (edge: c.info,     overline: 'Analytics'),
      _                     => (edge: c.accent,   overline: 'General'),
    };

// ═══════════════════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class SellerNotificationSettingsScreen extends ConsumerWidget {
  const SellerNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sellerColors;
    final state = ref.watch(sellerNotificationSettingsProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _HeaderGlyph(icon: Icons.notifications_outlined),
            title: 'Notification Settings',
            subtitle: 'Manage your alert preferences',
            automaticallyImplyLeading: true,
            actions: [
              SellerHeaderIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onTap: () => ref
                    .read(sellerNotificationSettingsProvider.notifier)
                    .refresh(),
              ),
            ],
          ),
          Expanded(
            child: state.when(
              loading: () => const SellerListSkeleton(),
              error: (e, _) => SellerErrorState(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref
                    .read(sellerNotificationSettingsProvider.notifier)
                    .refresh(),
              ),
              data: (settings) => RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () => ref
                    .read(sellerNotificationSettingsProvider.notifier)
                    .refresh(),
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(AppSpace.md),
                  children: [
                    ...settings.groupedTypes.entries.map(
                      (entry) => _NotificationGroup(
                        group: entry.key,
                        types: entry.value,
                        onToggle: (type, enabled) =>
                            _handleToggle(context, ref, type, enabled),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggle(
    BuildContext context,
    WidgetRef ref,
    String type,
    bool enabled,
  ) async {
    try {
      await ref
          .read(sellerNotificationSettingsProvider.notifier)
          .toggle(type, enabled);
    } catch (e) {
      SnackbarService().showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  GROUP SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationGroup extends StatelessWidget {
  final String group;
  final List<SellerNotificationType> types;
  final void Function(String type, bool enabled) onToggle;

  const _NotificationGroup({
    required this.group,
    required this.types,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final meta = _groupMeta(group, c);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SellerSectionHeader(overline: meta.overline, title: group),
          const Gap.v(AppSpace.sm),
          SellerCard(
            padding: EdgeInsets.zero,
            accentEdge: meta.edge,
            child: Column(
              children: [
                for (var i = 0; i < types.length; i++) ...[
                  _NotificationTile(
                    label: types[i].label,
                    description: types[i].description,
                    type: types[i].type,
                    enabled: types[i].enabled,
                    onToggle: (v) => onToggle(types[i].type, v),
                  ),
                  if (i < types.length - 1)
                    Divider(
                      color: c.divider,
                      height: 1,
                      indent: 68,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TILE
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationTile extends StatelessWidget {
  final String type;
  final String label;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const _NotificationTile({
    required this.type,
    required this.label,
    required this.description,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final icon = _iconFor(type);
    final tone = enabled ? _toneFor(type, c) : c.neutralTone;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          SellerIconBadge(icon: icon, tone: tone, size: 44, iconSize: 20),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.titleSm.copyWith(
                    color: enabled ? c.textPrimary : c.textTertiary,
                  ),
                ),
                const Gap.v(2),
                Text(
                  description,
                  style: text.bodySm.copyWith(
                    color: enabled ? c.textSecondary : c.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Gap.h(AppSpace.xs),
          Switch.adaptive(
            value: enabled,
            onChanged: onToggle,
            activeTrackColor: _toneFor(type, c).fg,
            inactiveTrackColor: c.surfaceMuted,
            thumbColor: WidgetStateProperty.all(Colors.white),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  HEADER GLYPH
// ═══════════════════════════════════════════════════════════════════════════

class _HeaderGlyph extends StatelessWidget {
  final IconData icon;
  const _HeaderGlyph({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadius.brMd,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
