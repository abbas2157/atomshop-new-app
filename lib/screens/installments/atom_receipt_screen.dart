import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/atom_account.dart';
import '../../data/atom_http.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../state/atom_account_providers.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_logo.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';

/// One payment's receipt (canvas: "Receipt"), with the server's PDF to
/// download or share.
class AtomReceiptScreen extends ConsumerStatefulWidget {
  const AtomReceiptScreen({super.key, required this.paymentId});

  final int paymentId;

  @override
  ConsumerState<AtomReceiptScreen> createState() => _AtomReceiptScreenState();
}

class _AtomReceiptScreenState extends ConsumerState<AtomReceiptScreen> {
  bool _downloading = false;
  bool _sharing = false;
  String? _savedPath;

  /// "pdf", "jpg"… from the receipt file's address.
  static String _extension(String url) {
    final last = Uri.tryParse(url)?.pathSegments.lastOrNull ?? '';
    final dot = last.lastIndexOf('.');
    final ext = dot < 0 ? '' : last.substring(dot + 1).toLowerCase();
    return const ['pdf', 'jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'pdf';
  }

  static String _mime(String url) => switch (_extension(url)) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  /// Saves the receipt file once and reuses it for "Share".
  Future<String> _pdf(Receipt r) async {
    final saved = _savedPath;
    if (saved != null && File(saved).existsSync()) return saved;
    final bytes = await ref.read(atomAccountApiProvider).receiptPdf(widget.paymentId);
    final dir = await getApplicationDocumentsDirectory();
    final name = (r.receiptNo.isEmpty ? '${widget.paymentId}' : r.receiptNo).replaceAll(RegExp(r'[^A-Za-z0-9-]'), '-');
    final file = File('${dir.path}${Platform.pathSeparator}receipt-$name.${_extension(r.pdfUrl)}');
    await file.writeAsBytes(bytes, flush: true);
    return _savedPath = file.path;
  }

  Future<void> _download(Receipt r) async {
    setState(() => _downloading = true);
    try {
      final path = await _pdf(r);
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt saved. No app on this phone can open PDFs; use Share instead.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(atomMessage(e))));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _share(Receipt r) async {
    setState(() => _sharing = true);
    try {
      final path = await _pdf(r);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(path, mimeType: _mime(r.pdfUrl))],
        text: 'Atomshop receipt ${r.receiptNo}: ${AtomFormat.rupees(r.payment.amount)} for ${r.payment.label}',
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(atomMessage(e))));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(receiptProvider(widget.paymentId));
    final config = ref.watch(appConfigProvider).value;
    final r = value.value;

    return AtomPage(
      title: 'Receipt',
      bottom: r == null || r.pdfUrl.isEmpty
          ? null
          : Row(
              children: [
                Expanded(
                  child: AtomButton(
                    label: _extension(r.pdfUrl) == 'pdf' ? 'Download PDF' : 'Open receipt',
                    icon: Icons.download_rounded,
                    expand: true,
                    loading: _downloading,
                    onPressed: _downloading || _sharing ? null : () => _download(r),
                  ),
                ),
                const SizedBox(width: AtomSpace.sm),
                Expanded(
                  child: AtomButton(
                    label: 'Share',
                    icon: Icons.ios_share_rounded,
                    variant: AtomButtonVariant.secondary,
                    expand: true,
                    loading: _sharing,
                    onPressed: _downloading || _sharing ? null : () => _share(r),
                  ),
                ),
              ],
            ),
      children: [
        AtomAsync<Receipt>(
          value: value,
          onRetry: () => ref.invalidate(receiptProvider(widget.paymentId)),
          loading: const AtomSkeleton(height: 420, radius: AtomRadius.hero),
          data: (r) {
            final p = r.payment;
            final footer = [
              'Atomshop.pk',
              if (config != null && config.officeAddress.isNotEmpty) config.officeAddress,
              if (config != null && config.phone.isNotEmpty) config.phone,
            ].join(' · ');
            return AtomCard(
              radius: AtomRadius.hero,
              padding: const EdgeInsets.all(AtomSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const AtomLogo(height: 32),
                      const Spacer(),
                      const AtomBadge('Paid', tone: AtomTone.green, icon: Icons.check_rounded),
                    ],
                  ),
                  const SizedBox(height: AtomSpace.lg),
                  Text('Amount paid', style: AtomText.small),
                  Text(AtomFormat.rupees(p.amount), style: AtomText.title.copyWith(fontSize: 30)),
                  Text([p.label, if (p.paidAt != null) AtomFormat.date(p.paidAt)].where((s) => s.isNotEmpty).join(' · '), style: AtomText.body),
                  const Divider(height: AtomSpace.xl, color: AtomColors.line),
                  if (r.receiptNo.isNotEmpty) AtomInfoRow('Receipt no.', r.receiptNo),
                  if (r.customer.isNotEmpty) AtomInfoRow('Customer', r.customer),
                  if (p.orderId.isNotEmpty) AtomInfoRow('Order', '#${p.orderId}'),
                  AtomInfoRow('Product', [p.product, if (r.storage.isNotEmpty) r.storage].join(' ')),
                  if (r.dueDate != null) AtomInfoRow('Due date', AtomFormat.date(r.dueDate)),
                  if (p.paidAt != null) AtomInfoRow('Paid on', AtomFormat.date(p.paidAt)),
                  if (p.method.isNotEmpty) AtomInfoRow('Payment method', p.method),
                  if (r.receivedBy.isNotEmpty) AtomInfoRow('Received by', r.receivedBy),
                  const Divider(height: AtomSpace.xl, color: AtomColors.line),
                  Text(footer, textAlign: TextAlign.center, style: AtomText.small),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
