import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

// Conditional import - imports download_helper_web on web, stub on mobile
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    as dl;

import '../models/invoice_record.dart';

Future<void> generateAndDownloadInvoicePDF(InvoiceRecord invoice) async {
  try {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                'GST BILLING INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: <pw.Widget>[
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Text(
                        'Invoice Number: ${invoice.number}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Invoice ID: ${invoice.id}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: <pw.Widget>[
                      pw.Text(
                        'Issue Date: ${_formatDate(invoice.date)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Due Date: ${_formatDate(invoice.dueDate)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'BILL TO:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(invoice.client, style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: <pw.TableRow>[
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: <pw.Widget>[
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Product',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Qty x Price',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  ...invoice.items.map((item) {
                    return pw.TableRow(
                      children: <pw.Widget>[
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            item.product,
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${item.qty} x ₹${item.price.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 12),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '₹${item.total.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 12),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: <pw.Widget>[
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Text(
                        'Subtotal: ₹${(invoice.totalAmount / (1 + invoice.gstPercent / 100)).toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        'GST (${invoice.gstPercent.toStringAsFixed(1)}%): ₹${(invoice.totalAmount - (invoice.totalAmount / (1 + invoice.gstPercent / 100))).toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Divider(),
                      pw.Text(
                        'Total: ₹${invoice.totalAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Status: ${invoice.status}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: invoice.status == 'Paid'
                      ? PdfColors.green
                      : invoice.status == 'Overdue'
                      ? PdfColors.red
                      : PdfColors.orange,
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName =
        'invoice_${invoice.number}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (kIsWeb) {
      dl.downloadPDFWeb(bytes, fileName);
    } else {
      // Mobile: Save to temporary directory and share
      await _downloadPDFMobile(bytes, fileName);
    }
  } catch (e) {
    rethrow;
  }
}

/// Mobile implementation: Save PDF to temporary directory and share
Future<void> _downloadPDFMobile(List<int> bytes, String fileName) async {
  try {
    // Get the temporary directory
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName';

    // Write PDF bytes to file
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // Share the file
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Invoice PDF',
      text: 'Invoice has been exported as PDF',
    );
  } catch (e) {
    rethrow;
  }
}

String _formatDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
