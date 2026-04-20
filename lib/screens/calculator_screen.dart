import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

enum GstType { cgstSgst, igst, noGst }

enum CalculatorMode { normal, gstBilling }

class AdvancedCalculatorScreen extends StatefulWidget {
  const AdvancedCalculatorScreen({super.key, this.withScaffold = false});

  final bool withScaffold;

  @override
  State<AdvancedCalculatorScreen> createState() =>
      _AdvancedCalculatorScreenState();
}

class _AdvancedCalculatorScreenState extends State<AdvancedCalculatorScreen> {
  static const List<_CalculatorKey> _calculatorKeys = <_CalculatorKey>[
    _CalculatorKey('MC', _CalculatorKeyType.memory),
    _CalculatorKey('MR', _CalculatorKeyType.memory),
    _CalculatorKey('M+', _CalculatorKeyType.memory),
    _CalculatorKey('M-', _CalculatorKeyType.memory),
    _CalculatorKey('C', _CalculatorKeyType.utility),
    _CalculatorKey('(', _CalculatorKeyType.special),
    _CalculatorKey(')', _CalculatorKeyType.special),
    _CalculatorKey('⌫', _CalculatorKeyType.utility),
    _CalculatorKey('%', _CalculatorKeyType.operatorKey),
    _CalculatorKey('÷', _CalculatorKeyType.operatorKey),
    _CalculatorKey('7', _CalculatorKeyType.number),
    _CalculatorKey('8', _CalculatorKeyType.number),
    _CalculatorKey('9', _CalculatorKeyType.number),
    _CalculatorKey('×', _CalculatorKeyType.operatorKey),
    _CalculatorKey('√', _CalculatorKeyType.special),
    _CalculatorKey('4', _CalculatorKeyType.number),
    _CalculatorKey('5', _CalculatorKeyType.number),
    _CalculatorKey('6', _CalculatorKeyType.number),
    _CalculatorKey('−', _CalculatorKeyType.operatorKey),
    _CalculatorKey('x²', _CalculatorKeyType.special),
    _CalculatorKey('1', _CalculatorKeyType.number),
    _CalculatorKey('2', _CalculatorKeyType.number),
    _CalculatorKey('3', _CalculatorKeyType.number),
    _CalculatorKey('+', _CalculatorKeyType.operatorKey),
    _CalculatorKey('Mkup%', _CalculatorKeyType.special),
    _CalculatorKey('0', _CalculatorKeyType.number),
    _CalculatorKey('.', _CalculatorKeyType.number),
    _CalculatorKey('Disc%', _CalculatorKeyType.special),
    _CalculatorKey('=', _CalculatorKeyType.equals),
    _CalculatorKey('', _CalculatorKeyType.empty),
  ];

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _markupController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();

  List<String> _tokens = <String>['0'];
  String _result = '0';
  bool _justEvaluated = false;

  double _selectedGstRate = 12;
  GstType _selectedGstType = GstType.cgstSgst;

  double _subtotal = 0;
  double _discountAmount = 0;
  double _markupAmount = 0;
  double _gstAmount = 0;
  double _cgstAmount = 0;
  double _sgstAmount = 0;
  double _igstAmount = 0;
  double _finalTotal = 0;
  double _profitPercent = 0;
  double _marginPercent = 0;
  double _profitAmount = 0;
  double _memoryValue = 0;

  CalculatorMode _calculatorMode = CalculatorMode.normal;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_recalculateBilling);
    _quantityController.addListener(_recalculateBilling);
    _discountController.addListener(_recalculateBilling);
    _markupController.addListener(_recalculateBilling);
    _costPriceController.addListener(_recalculateProfit);
    _sellingPriceController.addListener(_recalculateProfit);
    _recalculateBilling();
    _recalculateProfit();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    _discountController.dispose();
    _markupController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  bool _isNumberToken(String token) => double.tryParse(token) != null;

  bool _isOperatorToken(String token) =>
      const <String>{'+', '-', '*', '/', '%', 'MU', 'DISC'}.contains(token);

  String get _displayExpression {
    if (_tokens.isEmpty) {
      return '0';
    }
    return _tokens.map(_displayToken).join(' ');
  }

  String _displayToken(String token) {
    switch (token) {
      case '*':
        return '×';
      case '/':
        return '÷';
      case '-':
        return '−';
      case 'MU':
        return 'Mkup%';
      case 'DISC':
        return 'Disc%';
      default:
        return token;
    }
  }

  void _onCalculatorKeyTap(String label) {
    if (label.isEmpty) {
      return;
    }

    if (_isDigit(label)) {
      _appendDigit(label);
      return;
    }

    switch (label) {
      case '.':
        _appendDecimal();
        break;
      case '+':
      case '−':
      case '×':
      case '÷':
      case '%':
      case 'Mkup%':
      case 'Disc%':
        _appendOperator(_toInternalOperator(label));
        break;
      case '(':
        _appendLeftParenthesis();
        break;
      case ')':
        _appendRightParenthesis();
        break;
      case 'C':
        _clearCalculator();
        break;
      case '⌫':
        _backspace();
        break;
      case '=':
        _evaluateExpression();
        break;
      case 'x²':
        _applySquare();
        break;
      case '√':
        _applySquareRoot();
        break;
      case 'MC':
      case 'MR':
      case 'M+':
      case 'M-':
        _handleMemoryAction(label);
        break;
      default:
        break;
    }
  }

  bool _isDigit(String value) => RegExp(r'^\d$').hasMatch(value);

  String _toInternalOperator(String value) {
    switch (value) {
      case '−':
        return '-';
      case '×':
        return '*';
      case '÷':
        return '/';
      case 'Mkup%':
        return 'MU';
      case 'Disc%':
        return 'DISC';
      default:
        return value;
    }
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_justEvaluated) {
        _tokens = <String>[digit];
        _result = '0';
        _justEvaluated = false;
        return;
      }

      if (_tokens.length == 1 && _tokens.first == '0') {
        _tokens[0] = digit;
        return;
      }

      if (_tokens.isNotEmpty && _isNumberToken(_tokens.last)) {
        final String current = _tokens.last;
        if (current == '0') {
          _tokens[_tokens.length - 1] = digit;
        } else {
          _tokens[_tokens.length - 1] = '$current$digit';
        }
        return;
      }

      if (_tokens.isNotEmpty && _tokens.last == ')') {
        _tokens.add('*');
      }
      _tokens.add(digit);
    });
  }

  void _appendDecimal() {
    setState(() {
      if (_justEvaluated) {
        _tokens = <String>['0.'];
        _result = '0';
        _justEvaluated = false;
        return;
      }

      if (_tokens.isEmpty) {
        _tokens = <String>['0.'];
        return;
      }

      final String lastToken = _tokens.last;
      if (_isNumberToken(lastToken)) {
        if (!lastToken.contains('.')) {
          _tokens[_tokens.length - 1] = '$lastToken.';
        }
        return;
      }

      if (lastToken == ')') {
        _tokens.add('*');
      }
      _tokens.add('0.');
    });
  }

  void _appendOperator(String operatorToken) {
    setState(() {
      if (_justEvaluated) {
        _tokens = <String>[_result];
        _justEvaluated = false;
      }

      if (_tokens.isEmpty) {
        if (operatorToken == '-') {
          _tokens.add('-');
        }
        return;
      }

      final String lastToken = _tokens.last;

      if (_isOperatorToken(lastToken)) {
        if (operatorToken == '-' && lastToken != '-') {
          _tokens.add(operatorToken);
        } else {
          _tokens[_tokens.length - 1] = operatorToken;
        }
        return;
      }

      if (lastToken == '(') {
        if (operatorToken == '-') {
          _tokens.add(operatorToken);
        }
        return;
      }

      _tokens.add(operatorToken);
    });
  }

  void _appendLeftParenthesis() {
    setState(() {
      if (_justEvaluated) {
        _tokens = <String>['('];
        _result = '0';
        _justEvaluated = false;
        return;
      }

      if (_tokens.length == 1 && _tokens.first == '0') {
        _tokens[0] = '(';
        return;
      }

      if (_tokens.isNotEmpty &&
          (_isNumberToken(_tokens.last) || _tokens.last == ')')) {
        _tokens.add('*');
      }
      _tokens.add('(');
    });
  }

  void _appendRightParenthesis() {
    final int openBrackets = _tokens
        .where((String token) => token == '(')
        .length;
    final int closeBrackets = _tokens
        .where((String token) => token == ')')
        .length;
    if (openBrackets <= closeBrackets || _tokens.isEmpty) {
      return;
    }

    final String lastToken = _tokens.last;
    if (!_isNumberToken(lastToken) && lastToken != ')') {
      return;
    }

    setState(() {
      _tokens.add(')');
      _justEvaluated = false;
    });
  }

  void _clearCalculator() {
    setState(() {
      _tokens = <String>['0'];
      _result = '0';
      _justEvaluated = false;
    });
  }

  void _backspace() {
    setState(() {
      _justEvaluated = false;
      if (_tokens.isEmpty) {
        _tokens = <String>['0'];
        return;
      }

      final String lastToken = _tokens.last;
      if (_isNumberToken(lastToken) && lastToken.length > 1) {
        _tokens[_tokens.length - 1] = lastToken.substring(
          0,
          lastToken.length - 1,
        );
      } else {
        _tokens.removeLast();
      }

      if (_tokens.isEmpty) {
        _tokens = <String>['0'];
      }
    });
  }

  void _evaluateExpression() {
    try {
      final double value = _evaluateTokens(_tokens);
      final String formattedValue = _formatForDisplay(value);
      setState(() {
        _result = formattedValue;
        _tokens = <String>[formattedValue];
        _justEvaluated = true;
      });
    } on FormatException catch (error) {
      _showCalculatorError(error.message);
    } catch (_) {
      _showCalculatorError('Invalid expression');
    }
  }

  void _applySquare() {
    try {
      final double value = _evaluateTokens(_tokens);
      final String formattedValue = _formatForDisplay(value * value);
      setState(() {
        _result = formattedValue;
        _tokens = <String>[formattedValue];
        _justEvaluated = true;
      });
    } on FormatException catch (error) {
      _showCalculatorError(error.message);
    } catch (_) {
      _showCalculatorError('Unable to square current value');
    }
  }

  void _applySquareRoot() {
    try {
      final double value = _evaluateTokens(_tokens);
      if (value < 0) {
        throw const FormatException('Square root needs a non-negative value');
      }
      final String formattedValue = _formatForDisplay(math.sqrt(value));
      setState(() {
        _result = formattedValue;
        _tokens = <String>[formattedValue];
        _justEvaluated = true;
      });
    } on FormatException catch (error) {
      _showCalculatorError(error.message);
    } catch (_) {
      _showCalculatorError('Unable to find square root');
    }
  }

  double _evaluateTokens(List<String> sourceTokens) {
    if (sourceTokens.isEmpty) {
      return 0;
    }
    final _TokenParser parser = _TokenParser(sourceTokens);
    final double value = parser.parse();
    if (value.isInfinite || value.isNaN) {
      throw const FormatException('Result is not a finite number');
    }
    return value;
  }

  String _formatForDisplay(double value) {
    final String fixed = value.toStringAsFixed(6);
    final String compact = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    return compact.isEmpty ? '0' : compact;
  }

  void _showCalculatorError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  double _currentMemoryOperand() {
    try {
      return _evaluateTokens(_tokens);
    } catch (_) {
      return double.tryParse(_result) ?? 0;
    }
  }

  void _handleMemoryAction(String action) {
    String message = '';
    setState(() {
      switch (action) {
        case 'MC':
          _memoryValue = 0;
          message = 'Memory cleared';
          break;
        case 'MR':
          final String recalled = _formatForDisplay(_memoryValue);
          _tokens = <String>[recalled];
          _result = recalled;
          _justEvaluated = true;
          message = 'Memory recalled';
          break;
        case 'M+':
          _memoryValue += _currentMemoryOperand();
          message = 'Added to memory';
          break;
        case 'M-':
          _memoryValue -= _currentMemoryOperand();
          message = 'Subtracted from memory';
          break;
        default:
          break;
      }
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  double _readController(TextEditingController controller) {
    final String value = controller.text.trim();
    if (value.isEmpty) {
      return 0;
    }
    return double.tryParse(value) ?? 0;
  }

  void _recalculateBilling() {
    final double pricePerPiece = _readController(_priceController);
    final double quantity = _readController(_quantityController);
    final double discountPercent = _readController(
      _discountController,
    ).clamp(0, 100);
    final double markupPercent = _readController(
      _markupController,
    ).clamp(0, 1000);

    final double subtotal = pricePerPiece * quantity;
    final double discountAmount = subtotal * (discountPercent / 100);
    final double afterDiscount = subtotal - discountAmount;
    final double markupAmount = afterDiscount * (markupPercent / 100);
    final double taxableAmount = afterDiscount + markupAmount;
    final double gstBaseAmount = taxableAmount;
    final double gstAmount = _selectedGstType == GstType.noGst
        ? 0
        : gstBaseAmount * (_selectedGstRate / 100);

    double cgstAmount = 0;
    double sgstAmount = 0;
    double igstAmount = 0;
    if (_selectedGstType == GstType.cgstSgst) {
      cgstAmount = gstAmount / 2;
      sgstAmount = gstAmount / 2;
    } else if (_selectedGstType == GstType.igst) {
      igstAmount = gstAmount;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _subtotal = subtotal;
      _discountAmount = discountAmount;
      _markupAmount = markupAmount;
      _gstAmount = gstAmount;
      _cgstAmount = cgstAmount;
      _sgstAmount = sgstAmount;
      _igstAmount = igstAmount;
      _finalTotal = taxableAmount + gstAmount;
    });
  }

  void _recalculateProfit() {
    final double costPrice = _readController(_costPriceController);
    final double sellingPrice = _readController(_sellingPriceController);
    final double profitAmount = sellingPrice - costPrice;
    final double profitPercent = costPrice == 0
        ? 0
        : (profitAmount / costPrice) * 100;
    final double marginPercent = sellingPrice == 0
        ? 0
        : (profitAmount / sellingPrice) * 100;

    if (!mounted) {
      return;
    }
    setState(() {
      _profitAmount = profitAmount;
      _profitPercent = profitPercent;
      _marginPercent = marginPercent;
    });
  }

  String _money(double value) {
    final String sign = value < 0 ? '- ' : '';
    return '$sign₹${value.abs().toStringAsFixed(2)}';
  }

  Future<void> _saveAsInvoiceItem() async {
    try {
      print("PDF generation started...");
      
      final double pricePerPiece = _readController(_priceController);
      final double quantity = _readController(_quantityController);
      final double discountPercent = _readController(
        _discountController,
      ).clamp(0, 100);
      final double markupPercent = _readController(
        _markupController,
      ).clamp(0, 1000);

      if (pricePerPiece <= 0 || quantity <= 0) {
        _showCalculatorError('Enter valid price and quantity before saving.');
        return;
      }

      // Calculate amounts
      final double subtotal = quantity * pricePerPiece;
      final double discountAmount = subtotal * (discountPercent / 100);
      final double taxableAmount = subtotal - discountAmount;
      final double gstAmount = taxableAmount * (_selectedGstRate / 100);
      final double totalAmount = taxableAmount + gstAmount;

      // Generate PDF
      await _generateInvoicePDF(
        pricePerPiece: pricePerPiece,
        quantity: quantity,
        subtotal: subtotal,
        discountAmount: discountAmount,
        taxableAmount: taxableAmount,
        gstAmount: gstAmount,
        totalAmount: totalAmount,
        discountPercent: discountPercent,
        gstRate: _selectedGstRate,
        gstType: _selectedGstType.name,
      );

      print("PDF generation completed successfully!");
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice PDF generated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      print("PDF generation error: $error");
      _showCalculatorError('Failed to generate PDF: $error');
    }
  }

  Future<void> _generateInvoicePDF({
    required double pricePerPiece,
    required double quantity,
    required double subtotal,
    required double discountAmount,
    required double taxableAmount,
    required double gstAmount,
    required double totalAmount,
    required double discountPercent,
    required double gstRate,
    required String gstType,
  }) async {
    try {
      print("Loading font...");
      
      // Load font with fallback
      pw.Font ttf;
      try {
        final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
        ttf = pw.Font.ttf(fontData);
        print("Custom font loaded successfully");
      } catch (e) {
        print("Custom font not found, using default: $e");
        ttf = pw.Font.helvetica();
      }

      print("Creating PDF document...");
      
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                // Header
                pw.Center(
                  child: pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // Invoice Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: <pw.Widget>[
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: <pw.Widget>[
                        pw.Text(
                          'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                          style: pw.TextStyle(font: ttf, fontSize: 12),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Invoice ID: INV-${DateTime.now().millisecondsSinceEpoch}',
                          style: pw.TextStyle(font: ttf, fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: <pw.Widget>[
                        pw.Text(
                          'GST Type: $gstType',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Items Table
                pw.Text(
                  'ITEMS',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(width: 1),
                  children: <pw.TableRow>[
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: <pw.Widget>[
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Description',
                            style: pw.TextStyle(
                              font: ttf,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Qty',
                            style: pw.TextStyle(
                              font: ttf,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Unit Price',
                            style: pw.TextStyle(
                              font: ttf,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(
                              font: ttf,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    // Data row
                    pw.TableRow(
                      children: <pw.Widget>[
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Product/Service',
                            style: pw.TextStyle(font: ttf, fontSize: 11),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            quantity.toStringAsFixed(2),
                            style: pw.TextStyle(font: ttf, fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Rs.${pricePerPiece.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: ttf, fontSize: 11),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Rs.${subtotal.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: ttf, fontSize: 11),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: <pw.Widget>[
                    pw.SizedBox(
                      width: 350,
                      child: pw.Column(
                        children: <pw.Widget>[
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: <pw.Widget>[
                              pw.Text(
                                'Subtotal:',
                                style: pw.TextStyle(font: ttf, fontSize: 11),
                              ),
                              pw.Text(
                                'Rs.${subtotal.toStringAsFixed(2)}',
                                style: pw.TextStyle(font: ttf, fontSize: 11),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: <pw.Widget>[
                              pw.Text(
                                'Discount (${discountPercent.toStringAsFixed(1)}%):',
                                style: pw.TextStyle(font: ttf, fontSize: 11),
                              ),
                              pw.Text(
                                '-Rs.${discountAmount.toStringAsFixed(2)}',
                                style: pw.TextStyle(font: ttf, fontSize: 11),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: <pw.Widget>[
                              pw.Text(
                                'Taxable Amount:',
                                style: pw.TextStyle(font: ttf, fontSize: 11),
                              ),
                              pw.Text(
                                'Rs.${taxableAmount.toStringAsFixed(2)}',
                                style: pw.TextStyle(font: ttf, fontSize: 11),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: <pw.Widget>[
                              pw.Text(
                                'GST (${gstRate.toStringAsFixed(1)}%):',
                                style: pw.TextStyle(font: ttf, fontSize: 11),
                              ),
                              pw.Text(
                                'Rs.${gstAmount.toStringAsFixed(2)}',
                                style: pw.TextStyle(font: ttf, fontSize: 11),
                              ),
                            ],
                          ),
                          pw.Divider(thickness: 1),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: <pw.Widget>[
                              pw.Text(
                                'TOTAL:',
                                style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 13,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                'Rs.${totalAmount.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 13,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Footer
                pw.Center(
                  child: pw.Text(
                    'Thank you',
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

      print("PDF document created, saving...");
      
      final bytes = await pdf.save();
      final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';

      print("PDF bytes generated (${bytes.length} bytes), opening/sharing...");

      // On web, use printing to open PDF
      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: fileName,
        );
      } else {
        // On mobile, save to temp directory and share
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        print("PDF saved to: ${file.path}");
        
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Invoice PDF',
          text: 'Invoice has been generated',
        );
      }

      print("PDF operation completed!");
    } catch (e) {
      print("PDF generation error details: $e");
      rethrow;
    }
  }

  Future<void> _saveAsInvoiceItemOld() async {
    try {
      final FirestoreService firestoreService = context.read<FirestoreService>();
      final AnalyticsService analyticsService = context.read<AnalyticsService>();

      final double pricePerPiece = _readController(_priceController);
      final double quantity = _readController(_quantityController);
      final double discountPercent = _readController(
        _discountController,
      ).clamp(0, 100);
      final double markupPercent = _readController(
        _markupController,
      ).clamp(0, 1000);

      if (pricePerPiece <= 0 || quantity <= 0) {
        _showCalculatorError('Enter valid price and quantity before saving.');
        return;
      }

      await firestoreService.addInvoiceFromCalculator(
        pricePerPiece: pricePerPiece,
        quantity: quantity,
        gstRate: _selectedGstRate,
        gstType: _selectedGstType.name,
        discountPercent: discountPercent,
        markupPercent: markupPercent,
      );
      await analyticsService.logEvent('calculator_save_invoice');

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved as invoice draft in Firestore.')),
      );
    } catch (error) {
      _showCalculatorError('Could not save invoice draft: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildModeSwitch(),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            child: _calculatorMode == CalculatorMode.normal
                ? _buildCalculatorCard()
                : _buildSmartBillingPanel(),
          ),
          const SizedBox(height: 16),
          _buildLiveResultPreview(),
          const SizedBox(height: 16),
          _buildProfitMarginPanel(),
        ],
      ),
    );

    if (!widget.withScaffold) {
      return content;
    }

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text(
          'Advanced GST Calculator',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: content,
    );
  }

  Widget _buildCalculatorCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.calculate_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Calculator',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? const <Color>[Color(0xFF1E293B), Color(0xFF0F172A)]
                      : const <Color>[Color(0xFF2F6FED), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    _displayExpression,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.75),
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                    child: Text(
                      _result,
                      key: ValueKey<String>(_result),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildResponsiveCalculatorGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveCalculatorGrid() {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive cross axis count based on screen width
    int crossAxisCount = 5;
    if (screenWidth < 350) {
      crossAxisCount = 4;
    } else if (screenWidth < 400) {
      crossAxisCount = 5;
    } else {
      crossAxisCount = 5;
    }
    
    // Responsive spacing
    final double spacing = screenWidth < 400 ? 8 : 10;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _calculatorKeys.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _CalculatorKey key = _calculatorKeys[index];
        if (key.type == _CalculatorKeyType.empty) {
          return const SizedBox.shrink();
        }
        final _KeyStyle style = _styleForKey(key.type, context);
        return _KeyButton(
          label: key.label,
          backgroundColor: style.background,
          foregroundColor: style.foreground,
          onTap: () => _onCalculatorKeyTap(key.label),
        );
      },
    );
  }

  Widget _buildModeSwitch() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: ChoiceChip(
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Normal Calculator',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _calculatorMode == CalculatorMode.normal
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                selected: _calculatorMode == CalculatorMode.normal,
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                onSelected: (_) {
                  setState(() {
                    _calculatorMode = CalculatorMode.normal;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'GST Billing Mode',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _calculatorMode == CalculatorMode.gstBilling
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                selected: _calculatorMode == CalculatorMode.gstBilling,
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                onSelected: (_) {
                  setState(() {
                    _calculatorMode = CalculatorMode.gstBilling;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveResultPreview() {
    final bool gstMode = _calculatorMode == CalculatorMode.gstBilling;
    final String title = gstMode
        ? 'Live Billing Preview'
        : 'Live Calculator Result';
    final String value = gstMode ? _money(_finalTotal) : _result;
    final String subtitle = gstMode
        ? 'GST ${_selectedGstRate.toStringAsFixed(0)}%  •  ${_selectedGstType.name}'
        : 'Expression: $_displayExpression';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        gradient: LinearGradient(
          colors: <Color>[
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                gstMode ? Icons.receipt_long_outlined : Icons.calculate,
                color: Theme.of(context).colorScheme.onSecondary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondary,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSecondary
                  .withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitMarginPanel() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.trending_up_outlined,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Profit Margin',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildInputField(
                    controller: _costPriceController,
                    label: 'Cost Price',
                    hintText: '0',
                    icon: Icons.shopping_bag_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInputField(
                    controller: _sellingPriceController,
                    label: 'Selling Price',
                    hintText: '0',
                    icon: Icons.sell_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAmountRow(
              'Profit Amount',
              _profitAmount,
              valueColor: _profitAmount >= 0
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.error,
            ),
            _buildAmountRow(
              'Profit %',
              _profitPercent,
              valueColor: Theme.of(context).colorScheme.tertiary,
              suffix: '%',
            ),
            _buildAmountRow(
              'Margin %',
              _marginPercent,
              valueColor: Theme.of(context).colorScheme.primary,
              suffix: '%',
            ),
          ],
        ),
      ),
    );
  }

  _KeyStyle _styleForKey(_CalculatorKeyType type, BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDark = colorScheme.brightness == Brightness.dark;

    switch (type) {
      case _CalculatorKeyType.number:
        // Number buttons: surface color with high contrast text
        return _KeyStyle(colorScheme.surface, colorScheme.onSurface);
      case _CalculatorKeyType.operatorKey:
        // Operator buttons: FULL STRENGTH in dark mode, lighter in light mode
        return _KeyStyle(
          isDark
              ? colorScheme.secondary // FULL STRENGTH in dark mode
              : colorScheme.secondary.withValues(alpha: 0.3),
          isDark ? Colors.white : colorScheme.secondary, // Dark text in light mode
        );
      case _CalculatorKeyType.utility:
        // Utility (C) button: error color with white text
        return _KeyStyle(
          isDark
              ? colorScheme.error // FULL STRENGTH in dark mode
              : colorScheme.error.withValues(alpha: 0.3),
          isDark ? Colors.white : colorScheme.error, // Dark text in light mode
        );
      case _CalculatorKeyType.memory:
        // Memory buttons: FULL STRENGTH in dark mode, lighter in light mode
        return _KeyStyle(
          isDark
              ? colorScheme.secondary // FULL STRENGTH in dark mode
              : colorScheme.secondary.withValues(alpha: 0.5),
          isDark ? Colors.white : colorScheme.secondary, // Dark text in light mode
        );
      case _CalculatorKeyType.special:
        // Special keys: FULL STRENGTH in dark mode, lighter in light mode
        return _KeyStyle(
          isDark
              ? colorScheme.tertiary // FULL STRENGTH in dark mode
              : colorScheme.tertiary.withValues(alpha: 0.3),
          isDark ? Colors.white : colorScheme.tertiary, // Dark text in light mode
        );
      case _CalculatorKeyType.equals:
        // Equals button: primary background with white text (max contrast)
        return _KeyStyle(colorScheme.primary, Colors.white);
      case _CalculatorKeyType.empty:
        return const _KeyStyle(Colors.transparent, Colors.transparent);
    }
  }

  Widget _buildSmartBillingPanel() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.receipt_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Smart GST Billing',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Client-ready billing with GST split & totals',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildInputField(
                    controller: _priceController,
                    label: 'Product Price (per piece)',
                    hintText: '0.00',
                    icon: Icons.sell_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInputField(
                    controller: _quantityController,
                    label: 'Quantity',
                    hintText: '1',
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildInputField(
                    controller: _discountController,
                    label: 'Discount % (optional)',
                    hintText: '0',
                    icon: Icons.local_offer_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInputField(
                    controller: _markupController,
                    label: 'Markup % (optional)',
                    hintText: '0',
                    icon: Icons.trending_up_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 18),
            Text(
              'GST Rate',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _buildRateChip(0),
                _buildRateChip(5),
                _buildRateChip(12),
                _buildRateChip(18),
                _buildRateChip(28),
              ],
            ),
            const SizedBox(height: 20),
            Divider(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 18),
            Text(
              'GST Type',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildTypeBadge(
                    label: 'CGST + SGST',
                    type: GstType.cgstSgst,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTypeBadge(
                    label: 'IGST',
                    type: GstType.igst,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTypeBadge(
                    label: 'No GST',
                    type: GstType.noGst,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saveAsInvoiceItem,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text(
                      'Save Invoice',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                // FIX 3: was Colors.white — hardcoded white breaks dark mode
                // and causes invisible white-on-white text in output rows.
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: greyDivider),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Auto Calculation Output',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAmountRow('Subtotal', _subtotal),
                  _buildAmountRow(
                    'Discount amount',
                    -_discountAmount,
                    valueColor: Theme.of(context).colorScheme.error,
                  ),
                  _buildAmountRow(
                    'Markup amount',
                    _markupAmount,
                    valueColor: Theme.of(context).colorScheme.tertiary,
                  ),
                  _buildAmountRow(
                    'GST amount',
                    _gstAmount,
                    valueColor: Theme.of(context).colorScheme.secondary,
                  ),
                  if (_selectedGstType == GstType.cgstSgst) ...<Widget>[
                    _buildAmountRow(
                      'CGST amount',
                      _cgstAmount,
                      valueColor: Theme.of(context).colorScheme.secondary,
                    ),
                    _buildAmountRow(
                      'SGST amount',
                      _sgstAmount,
                      valueColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                  if (_selectedGstType == GstType.igst)
                    _buildAmountRow(
                      'IGST amount',
                      _igstAmount,
                      valueColor: Theme.of(context).colorScheme.tertiary,
                    ),
                  const Divider(height: 22, thickness: 1),
                  _buildAmountRow(
                    'Final Total Payable Amount',
                    _finalTotal,
                    emphasize: true,
                    valueColor: primaryBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildRateChip(double rate) {
    final bool selected = _selectedGstRate == rate;
    return ChoiceChip(
      selected: selected,
      label: Text(
        '${rate.toInt()}%',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected
              ? primaryBlue
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selectedColor: primaryBlue.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? primaryBlue : greyDivider),
      ),
      // FIX 1: wrapped assignment in setState so Flutter marks
      // the widget dirty and schedules a rebuild with the new rate.
      onSelected: (_) {
        setState(() {
          _selectedGstRate = rate;
        });
        _recalculateBilling();
      },
    );
  }

  Widget _buildTypeBadge({
    required String label,
    required GstType type,
    required Color color,
  }) {
    final bool selected = _selectedGstType == type;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      // FIX 2: wrapped assignment in setState so the badge visually
      // updates and _recalculateBilling reads the correct new type.
      onTap: () {
        setState(() {
          _selectedGstType = type;
        });
        _recalculateBilling();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // FIX 3 (partial): replaced Colors.white with colorScheme.surface
          // so unselected badges also render correctly in dark mode.
          color: selected
              ? color.withValues(alpha: 0.16)
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: selected ? color : greyDivider,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? color : Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double value, {
    Color? valueColor,
    bool emphasize = false,
    String? suffix,
  }) {
    final String displayValue = suffix == null
        ? _money(value)
        : '${value.toStringAsFixed(2)}$suffix';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: emphasize ? 16 : 14,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              displayValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontSize: emphasize ? 20 : 15,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenParser {
  _TokenParser(List<String> tokens) : _tokens = List<String>.from(tokens);

  final List<String> _tokens;
  int _index = 0;

  bool get _isAtEnd => _index >= _tokens.length;

  String get _previous => _tokens[_index - 1];

  double parse() {
    final double value = _parseExpression();
    if (!_isAtEnd) {
      throw const FormatException('Unexpected token sequence');
    }
    return value;
  }

  double _parseExpression() {
    double value = _parseTerm();

    while (_matchAny(const <String>['+', '-', 'MU', 'DISC'])) {
      final String operator = _previous;
      final double right = _parseTerm();
      switch (operator) {
        case '+':
          value += right;
          break;
        case '-':
          value -= right;
          break;
        case 'MU':
          value += value * (right / 100);
          break;
        case 'DISC':
          value -= value * (right / 100);
          break;
      }
    }

    return value;
  }

  double _parseTerm() {
    double value = _parseFactor();

    while (_matchAny(const <String>['*', '/', '%'])) {
      final String operator = _previous;
      final double right = _parseFactor();
      switch (operator) {
        case '*':
          value *= right;
          break;
        case '/':
          if (right == 0) {
            throw const FormatException('Cannot divide by zero');
          }
          value /= right;
          break;
        case '%':
          if (right == 0) {
            throw const FormatException('Cannot modulo by zero');
          }
          value %= right;
          break;
      }
    }

    return value;
  }

  double _parseFactor() {
    if (_match('-')) {
      return -_parseFactor();
    }
    if (_match('+')) {
      return _parseFactor();
    }

    if (_match('(')) {
      final double value = _parseExpression();
      _consume(')');
      return value;
    }

    if (_isAtEnd) {
      throw const FormatException('Expression cannot end here');
    }

    final String token = _advance();
    final double? parsed = double.tryParse(token);
    if (parsed == null) {
      throw const FormatException('Invalid number');
    }
    return parsed;
  }

  String _advance() => _tokens[_index++];

  bool _matchAny(List<String> expectedTokens) {
    if (_isAtEnd) {
      return false;
    }
    if (!expectedTokens.contains(_tokens[_index])) {
      return false;
    }
    _index++;
    return true;
  }

  bool _match(String expected) {
    if (_isAtEnd || _tokens[_index] != expected) {
      return false;
    }
    _index++;
    return true;
  }

  void _consume(String expected) {
    if (!_match(expected)) {
      throw const FormatException('Unbalanced brackets');
    }
  }
}

class _CalculatorKey {
  const _CalculatorKey(this.label, this.type);

  final String label;
  final _CalculatorKeyType type;
}

enum _CalculatorKeyType {
  number,
  operatorKey,
  utility,
  memory,
  special,
  equals,
  empty,
}

class _KeyStyle {
  const _KeyStyle(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive font size based on screen width
    final double fontSize = screenWidth < 400 ? 12 : 14;

    return AnimatedScale(
      scale: _pressed ? 0.95 : 1,
      duration: const Duration(milliseconds: 110),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.backgroundColor.computeLuminance() > 0.5
                  ? colorScheme.outline.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.foregroundColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
