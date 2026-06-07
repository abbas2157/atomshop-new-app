// ============================================================
//  seller_instalment_invoice_screen.dart  —  Payment Invoice
//
//  Client-rendered invoice shown right after a successful
//  payment. Mirrors the on-screen receipt into a generated
//  PDF (via `pdf`) that can be downloaded or printed/shared
//  (via `printing`).
// ============================================================

import 'dart:io';

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/instalments/model/seller_instalments_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SellerInstalmentInvoiceScreen extends StatefulWidget {
  final int instalmentId;
  final SellerInstalmentInvoiceData invoiceData;
  final DateTime paymentDate;
  final String referenceNo;
  final String notes;

  const SellerInstalmentInvoiceScreen({
    super.key,
    required this.instalmentId,
    required this.invoiceData,
    required this.paymentDate,
    required this.referenceNo,
    required this.notes,
  });

  @override
  State<SellerInstalmentInvoiceScreen> createState() =>
      _SellerInstalmentInvoiceScreenState();
}

class _SellerInstalmentInvoiceScreenState
    extends State<SellerInstalmentInvoiceScreen> {
  bool _working = false;

  SellerInstalmentInvoiceData get _data => widget.invoiceData;

  Future<Uint8List> _buildPdf() async {
    final inst = _data.instalment;
    final order = inst.customOrder;
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _data.seller.businessName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(_data.seller.name),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.Text(_data.invoiceNumber),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 12),
              _pdfSection('Customer', [
                _pdfRow('Name', inst.user.name),
                _pdfRow('Phone', inst.user.phone),
              ]),
              pw.SizedBox(height: 14),
              _pdfSection('Order', [
                _pdfRow('Order No.', formatOrderNo(order.id)),
                _pdfRow('Product', order.product.title),
                _pdfRow('Total Deal Value', order.formattedTotalDealPrice),
                _pdfRow('Tenure', '${order.tenure} months'),
              ]),
              pw.SizedBox(height: 14),
              _pdfSection('Payment', [
                _pdfRow('Instalment Month', inst.month),
                _pdfRow('Amount Paid', inst.formattedInstallmentPaidPrice),
                _pdfRow('Payment Method', inst.paymentMethod),
                _pdfRow('Payment Date', _formatDate(widget.paymentDate)),
                if (widget.referenceNo.isNotEmpty)
                  _pdfRow('Reference No.', widget.referenceNo),
              ]),
              if (widget.notes.isNotEmpty) ...[
                pw.SizedBox(height: 14),
                _pdfSection('Notes', [pw.Text(widget.notes)]),
              ],
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _pdfTotalRow('Total Paid To Date', _data.formattedTotalPaid),
                    _pdfTotalRow('Remaining Balance', _data.formattedRemaining),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'This is a system-generated invoice from ${_data.seller.businessName}.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfSection(String title, List<pw.Widget> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 6),
        ...rows,
      ],
    );
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfTotalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$label:  ',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final bytes = await _buildPdf();
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}${Platform.pathSeparator}invoice_${_data.invoiceNumber}.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      await SellerFileService.openLocalFile(path);
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _printPdf() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final bytes = await _buildPdf();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final inst = _data.instalment;
    final order = inst.customOrder;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.canvas,
        body: Column(
          children: [
            SellerGradientHeader(
              leading: SellerIconBadge(
                icon: Icons.receipt_long_rounded,
                tone: SellerTone(
                  fg: Colors.white,
                  bg: Colors.white.withValues(alpha: 0.18),
                  border: Colors.white.withValues(alpha: 0.2),
                ),
                size: 44,
                iconSize: 22,
                radius: AppRadius.md,
              ),
              title: 'Payment Invoice',
              subtitle: _data.invoiceNumber,
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: AppInsets.pageWithNav,
                children: [
                  SellerCard(
                    accentEdge: c.successTone.fg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_data.seller.businessName, style: text.titleSm),
                                  Text(_data.seller.name, style: text.bodySm),
                                ],
                              ),
                            ),
                            SellerStatusPill(label: inst.status, tone: c.successTone),
                          ],
                        ),
                        const Gap.v(AppSpace.sm),
                        Text(
                          _data.invoiceNumber,
                          style: text.titleLg.copyWith(color: c.accent),
                        ),
                        Text('Generated ${inst.formattedDate}', style: text.caption),
                      ],
                    ),
                  ),
                  const Gap.v(AppSpace.sm),
                  SellerSectionHeader(title: 'Customer'),
                  const Gap.v(AppSpace.xs),
                  SellerCard(
                    child: Column(
                      children: [
                        SellerDataRow(label: 'Name', value: inst.user.name),
                        SellerDataRow(label: 'Phone', value: inst.user.phone),
                      ],
                    ),
                  ),
                  const Gap.v(AppSpace.sm),
                  SellerSectionHeader(title: 'Order'),
                  const Gap.v(AppSpace.xs),
                  SellerCard(
                    child: Column(
                      children: [
                        SellerDataRow(label: 'Order No.', value: formatOrderNo(order.id)),
                        SellerDataRow(label: 'Product', value: order.product.title),
                        SellerDataRow(
                          label: 'Total Deal Value',
                          value: order.formattedTotalDealPrice,
                          emphasize: true,
                        ),
                        SellerDataRow(label: 'Tenure', value: '${order.tenure} months'),
                      ],
                    ),
                  ),
                  const Gap.v(AppSpace.sm),
                  SellerSectionHeader(title: 'Payment Details'),
                  const Gap.v(AppSpace.xs),
                  SellerCard(
                    child: Column(
                      children: [
                        SellerDataRow(label: 'Instalment Month', value: inst.month),
                        SellerDataRow(
                          label: 'Amount Paid',
                          value: inst.formattedInstallmentPaidPrice,
                          emphasize: true,
                        ),
                        SellerDataRow(label: 'Payment Method', value: inst.paymentMethod),
                        SellerDataRow(
                          label: 'Payment Date',
                          value: _formatDate(widget.paymentDate),
                        ),
                        if (widget.referenceNo.isNotEmpty)
                          SellerDataRow(label: 'Reference No.', value: widget.referenceNo),
                      ],
                    ),
                  ),
                  if (widget.notes.isNotEmpty) ...[
                    const Gap.v(AppSpace.sm),
                    SellerSectionHeader(title: 'Notes'),
                    const Gap.v(AppSpace.xs),
                    SellerCard(
                      child: Text(widget.notes, style: text.bodySm),
                    ),
                  ],
                  const Gap.v(AppSpace.sm),
                  SellerSectionHeader(title: 'Running Totals'),
                  const Gap.v(AppSpace.xs),
                  SellerCard(
                    child: Column(
                      children: [
                        SellerDataRow(
                          label: 'Total Paid To Date',
                          value: _data.formattedTotalPaid,
                          emphasize: true,
                        ),
                        SellerDataRow(
                          label: 'Remaining Balance',
                          value: _data.formattedRemaining,
                          emphasize: true,
                        ),
                      ],
                    ),
                  ),
                  const Gap.v(AppSpace.lg),
                  Row(
                    children: [
                      Expanded(
                        child: SellerButton.secondary(
                          label: 'Print',
                          icon: Icons.print_outlined,
                          loading: _working,
                          onPressed: _working ? null : _printPdf,
                        ),
                      ),
                      const Gap.h(AppSpace.sm),
                      Expanded(
                        child: SellerButton(
                          label: 'Download PDF',
                          icon: Icons.download_rounded,
                          loading: _working,
                          onPressed: _working ? null : _downloadPdf,
                        ),
                      ),
                    ],
                  ),
                  const Gap.v(AppSpace.sm),
                  SellerButton.ghost(
                    label: 'Close',
                    icon: Icons.close_rounded,
                    expand: true,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _cleanError(Object error) {
  final msg = error.toString().replaceFirst('Exception: ', '').trim();
  return msg.isEmpty ? 'Something went wrong. Please try again.' : msg;
}
