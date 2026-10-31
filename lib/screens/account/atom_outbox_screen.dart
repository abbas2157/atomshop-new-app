import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/session_manager.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../state/atom_connectivity.dart';
import '../../state/atom_outbox.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_dialog.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';

/// "Waiting to send": offers, custom orders and profile changes made
/// offline. They go by themselves once the phone is online; here the
/// customer sees them, sends them now, or removes one.
class AtomOutboxScreen extends ConsumerStatefulWidget {
  const AtomOutboxScreen({super.key});

  @override
  ConsumerState<AtomOutboxScreen> createState() => _AtomOutboxScreenState();
}

class _AtomOutboxScreenState extends ConsumerState<AtomOutboxScreen> {
  bool _sending = false;
  String _me = '';

  @override
  void initState() {
    super.initState();
    SessionManager.getUserUuid().then((u) {
      if (mounted) setState(() => _me = u ?? '');
    });
  }

  Future<void> _sendNow() async {
    setState(() => _sending = true);
    await ref.read(outboxProvider.notifier).sync();
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _remove(OutboxItem item) async {
    final ok = await showAtomConfirm(
      context,
      title: 'Remove this?',
      message: '“${item.title}” is deleted from this phone and never sent.',
      confirmLabel: 'Remove',
      confirmIcon: Icons.delete_outline_rounded,
      danger: true,
    );
    if (ok) await ref.read(outboxProvider.notifier).remove(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(outboxProvider);
    final online = ref.watch(onlineProvider).value ?? true;

    return AtomPage(
      title: 'Waiting to send',
      bottom: items.isEmpty
          ? null
          : AtomButton(
              label: online ? 'Send now' : 'Waiting for a connection',
              icon: online ? Icons.send_rounded : Icons.wifi_off_rounded,
              expand: true,
              loading: _sending,
              onPressed: online && !_sending ? _sendNow : null,
            ),
      children: [
        if (items.isEmpty)
          const AtomEmptyState(
            icon: Icons.cloud_done_outlined,
            title: 'Everything is sent',
            message: 'Offers, custom orders and profile changes you make offline wait here until you are back online.',
          )
        else ...[
          const SizedBox(height: AtomSpace.xs),
          AtomNotice(
            icon: online ? Icons.info_outline_rounded : Icons.wifi_off_rounded,
            tone: online ? AtomNoticeTone.blue : AtomNoticeTone.amber,
            text: online
                ? 'These are sent by themselves. Tap Send now if you do not want to wait.'
                : 'Saved on this phone. They are sent by themselves as soon as you are back online.',
          ),
          const SizedBox(height: AtomSpace.sm),
          for (final item in items) ...[
            _ItemCard(
              item: item,
              otherAccount: item.owner.isNotEmpty && item.owner != _me,
              onRetry: online ? () => ref.read(outboxProvider.notifier).retry(item.id) : null,
              onRemove: () => _remove(item),
            ),
            const SizedBox(height: AtomSpace.sm),
          ],
        ],
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.otherAccount, required this.onRetry, required this.onRemove});

  final OutboxItem item;
  final bool otherAccount;
  final VoidCallback? onRetry;
  final VoidCallback onRemove;

  IconData get _icon => switch (item.kind) {
        OutboxKind.offer => Icons.chat_bubble_outline_rounded,
        OutboxKind.customOrder => Icons.calculate_outlined,
        OutboxKind.profile => Icons.person_outline_rounded,
        OutboxKind.location => Icons.place_outlined,
        OutboxKind.photo => Icons.photo_camera_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final t = item.createdAt;
    final time = '${AtomFormat.date(t)}, ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final p = item.payload;
    final detail = switch (item.kind) {
      OutboxKind.customOrder => '${AtomFormat.rupees(p['price'] as num?)} · ${p['months']} months',
      _ => '',
    };
    final (status, color) = item.refused
        ? (item.error, AtomColors.rose)
        : otherAccount
            ? ('Sign in to the account you used to send this.', AtomColors.amberInk)
            : ('Waiting to send', AtomColors.body);

    return AtomCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AtomColors.primarySoft, borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, size: 20, color: AtomColors.primary),
          ),
          const SizedBox(width: AtomSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AtomText.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (detail.isNotEmpty) Text(detail, style: AtomText.small),
                Text('Saved $time', style: AtomText.small),
                const SizedBox(height: 4),
                Text(status, style: AtomText.small.copyWith(color: color, fontWeight: FontWeight.w700)),
                if (item.refused && onRetry != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AtomButton(label: 'Try again', icon: Icons.refresh_rounded, variant: AtomButtonVariant.text, size: AtomButtonSize.small, onPressed: onRetry),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline_rounded, color: AtomColors.muted),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
