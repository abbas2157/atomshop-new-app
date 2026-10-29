import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/atom_app_version.dart';
import '../../data/atom_auth.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../widgets/atom_network_image.dart';
import '../../widgets/atom_surfaces.dart';

/// One row of an account menu: icon tile, label, optional gold count badge
/// or grey value ("Allowed", "23.4 MB"), chevron.
class AccountMenuRow {
  const AccountMenuRow(this.icon, this.label, this.onTap, {this.count = 0, this.value = ''});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int count;
  final String value;
}

/// A titled white card of [AccountMenuRow]s with dividers.
class AccountMenuGroup extends StatelessWidget {
  const AccountMenuGroup({super.key, required this.title, required this.rows});

  final String title;
  final List<AccountMenuRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AtomSpace.lg, bottom: AtomSpace.xs),
          child: Text(title, style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800)),
        ),
        AtomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 64, color: AtomColors.line),
                _MenuRowTile(row: rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuRowTile extends StatelessWidget {
  const _MenuRowTile({required this.row});

  final AccountMenuRow row;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: [row.label, if (row.count > 0) '${row.count} new', if (row.value.isNotEmpty) row.value].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: row.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(11)),
                  child: Icon(row.icon, size: 18, color: AtomColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(row.label, style: AtomText.label.copyWith(fontSize: 15))),
                if (row.count > 0) ...[
                  Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AtomColors.amber, borderRadius: BorderRadius.circular(AtomRadius.pill)),
                    child: Text('${row.count}', style: AtomText.small.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: AtomColors.ink)),
                  ),
                  const SizedBox(width: 6),
                ],
                if (row.value.isNotEmpty) ...[
                  Flexible(
                    child: Text(row.value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: AtomText.small),
                  ),
                  const SizedBox(width: 4),
                ],
                const Icon(Icons.chevron_right_rounded, color: AtomColors.placeholder),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Help and info" rows, shared by the guest and signed-in account tabs.
List<AccountMenuRow> helpRows(BuildContext context) => [
      AccountMenuRow(Icons.settings_outlined, 'Settings', () => AtomNav.settings(context)),
      AccountMenuRow(Icons.phone_outlined, 'Contact us', () => AtomNav.contact(context)),
      AccountMenuRow(Icons.help_outline_rounded, 'FAQs', () => AtomNav.faqs(context)),
      AccountMenuRow(Icons.info_outline_rounded, 'About us', () => AtomNav.about(context)),
      AccountMenuRow(Icons.star_outline_rounded, 'Why Atomshop', () => AtomNav.why(context)),
      AccountMenuRow(Icons.apps_rounded, 'Atom ecosystem', () => AtomNav.apps(context)),
      AccountMenuRow(Icons.shield_outlined, 'Privacy, returns and terms', () => AtomNav.legal(context)),
    ];

/// Round avatar: the profile photo, or initials on light blue.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, required this.user, this.size = 52});

  final AtomUser? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final u = user;
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: AtomColors.primarySoft,
          child: u != null && u.pictureUrl.isNotEmpty
              ? AtomNetworkImage(u.pictureUrl, semanticLabel: 'Profile photo', placeholderIcon: Icons.person_rounded)
              : Center(
                  child: Text(
                    u?.initials ?? '',
                    style: AtomText.heading.copyWith(fontSize: size * 0.34, color: AtomColors.primary),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Tab header: big title with an optional pill next to it.
class AccountTabHeader extends StatelessWidget {
  const AccountTabHeader({super.key, required this.title, this.pill});

  final String title;
  final String? pill;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AtomSpace.md, bottom: AtomSpace.xs),
      child: Row(
        children: [
          Semantics(header: true, child: Text(title, style: AtomText.title)),
          if (pill != null) ...[
            const SizedBox(width: AtomSpace.sm),
            AtomBadge(pill!, icon: Icons.person_outline_rounded),
          ],
        ],
      ),
    );
  }
}

/// "Atomshop · version 2.0.0" under the account menu.
class AccountVersionFooter extends ConsumerWidget {
  const AccountVersionFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value;
    if (version == null || version.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AtomSpace.sm),
      child: Text('Atomshop · version $version', textAlign: TextAlign.center, style: AtomText.small),
    );
  }
}
