import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
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
    // Attempt to load the Unicode font for Rupee symbol support
    pw.Font ttf;
    try {
      final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
      ttf = pw.Font.ttf(fontData);
    } catch (e) {
      // Fallback to standard font if custom font not available
      ttf = pw.Font.helvetica();
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              // ===== HEADER =====
              pw.Center(
                child: pw.Text(
                  'GST BILLING INVOICE',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 15),

              // ===== COMPANY INFO & INVOICE DETAILS =====
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  // Left: Company/Invoice Info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Text(
                        'Invoice Details',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      _buildDetailRow(ttf, 'Invoice No', invoice.number),
                      _buildDetailRow(ttf, 'Invoice ID', invoice.id),
                      pw.SizedBox(height: 8),
                      _buildDetailRow(ttf, 'Issue Date', _formatDate(invoice.date)),
                      _buildDetailRow(ttf, 'Due Date', _formatDate(invoice.dueDate)),
                    ],
                  ),
                  // Right: Status Info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: <pw.Widget>[
                      pw.Text(
                        'Payment Status',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                          color: _getStatusColor(invoice.status),
                        ),
                        child: pw.Text(
                          invoice.status.toUpperCase(),
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // ===== BILLING DETAILS =====
              pw.Text(
                'BILL TO:',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Text(
                  invoice.client,
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // ===== ITEMS TABLE =====
              pw.Text(
                'INVOICE ITEMS',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(width: 1),
                columnWidths: <int, pw.TableColumnWidth>{
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(2),
                },
                children: <pw.TableRow>[
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: <pw.Widget>[
                      _buildTableHeader(ttf, 'ITEM DESCRIPTION'),
                      _buildTableHeader(ttf, 'QTY'),
                      _buildTableHeader(ttf, 'RATE'),
                      _buildTableHeader(ttf, 'AMOUNT'),
                    ],
                  ),
                  // Data Rows
                  ...invoice.items.map((item) {
                    return pw.TableRow(
                      children: <pw.Widget>[
                        _buildTableCell(ttf, item.product),
                        _buildTableCell(ttf, item.qty.toString(), align: pw.TextAlign.center),
                        _buildTableCell(
                          ttf,
                          'Rs.${item.price.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                        ),
                        _buildTableCell(
                          ttf,
                          'Rs.${item.total.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),

              // ===== SUMMARY TABLE =====
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: <pw.Widget>[
                  pw.SizedBox(
                    width: 300,
                    child: pw.Table(
                      border: pw.TableBorder.all(width: 1),
                      children: <pw.TableRow>[
                        _buildSummaryRow(
                          ttf,
                          'Subtotal',
                          'Rs.${invoice.subtotal.toStringAsFixed(2)}',
                        ),
                        _buildSummaryRow(
                          ttf,
                          'Discount',
                          'Rs.${invoice.discountAmount.toStringAsFixed(2)}',
                        ),
                        _buildSummaryRow(
                          ttf,
                          'Taxable Amount',
                          'Rs.${invoice.taxableAmount.toStringAsFixed(2)}',
                        ),
                        _buildSummaryRow(
                          ttf,
                          'GST (${invoice.gstPercent.toStringAsFixed(1)}%)',
                          'Rs.${invoice.gstAmount.toStringAsFixed(2)}',
                        ),
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey200,
                          ),
                          children: <pw.Widget>[
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'TOTAL AMOUNT',
                                style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Rs.${invoice.totalAmount.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 13,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // ===== PAYMENT INFO =====
              pw.Text(
                'PAYMENT INFORMATION',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: <pw.Widget>[
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      _buildDetailRow(
                        ttf,
                        'Paid Amount',
                        'Rs.${invoice.paidAmount.toStringAsFixed(2)}',
                        fontSize: 10,
                      ),
                      _buildDetailRow(
                        ttf,
                        'Balance Amount',
                        'Rs.${invoice.balanceAmount.toStringAsFixed(2)}',
                        fontSize: 10,
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
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

/// Helper function to build detail rows
pw.Widget _buildDetailRow(
  pw.Font font,
  String label,
  String value, {
  double fontSize = 10,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: fontSize,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

/// Helper function for table header
pw.Widget _buildTableHeader(pw.Font font, String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

/// Helper function for table cells
pw.Widget _buildTableCell(
  pw.Font font,
  String text, {
  pw.TextAlign align = pw.TextAlign.left,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: 10,
      ),
      textAlign: align,
    ),
  );
}

/// Helper function for summary rows
pw.TableRow _buildSummaryRow(pw.Font font, String label, String amount) {
  return pw.TableRow(
    children: <pw.Widget>[
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          amount,
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.right,
        ),
      ),
    ],
  );
}

/// Get status color based on payment status
PdfColor _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return PdfColors.green100;
    case 'overdue':
      return PdfColors.red100;
    case 'pending':
      return PdfColors.yellow100;
    default:
      return PdfColors.white;
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
