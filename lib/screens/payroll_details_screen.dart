// payroll_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/payroll.dart';
import '../models/employee.dart';
import '../services/payroll_service.dart';
import '../services/employee_service.dart';

class PayrollDetailsScreen extends StatefulWidget {
  final String payrollId;
  final String employeeName;

  const PayrollDetailsScreen({
    super.key,
    required this.payrollId,
    required this.employeeName,
  });

  @override
  State<PayrollDetailsScreen> createState() => _PayrollDetailsScreenState();
}

class _PayrollDetailsScreenState extends State<PayrollDetailsScreen> {
  bool _isLoading = true;
  Payroll? _payroll;
  Employee? _employee;
  final TextEditingController _paymentRefController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPayrollDetails();
  }

  Future<void> _loadPayrollDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final payrollService = Provider.of<PayrollService>(
        context,
        listen: false,
      );
      final employeeService = Provider.of<EmployeeService>(
        context,
        listen: false,
      );

      // Load payroll
      final payroll = await payrollService.getPayroll(widget.payrollId);
      if (payroll == null) {
        throw Exception('Payroll not found');
      }

      // Load employee
      final employee = await employeeService.getEmployee(payroll.employeeId);

      setState(() {
        _payroll = payroll;
        _employee = employee;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsPaid() async {
    if (_paymentRefController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a payment reference'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final payrollService = Provider.of<PayrollService>(
        context,
        listen: false,
      );

      await payrollService.updatePayrollStatus(
        payrollId: widget.payrollId,
        newStatus: PayrollStatus.paid,
        paymentDate: DateTime.now(),
        paymentReference: _paymentRefController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPayrollDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _printPayslip() async {
    if (_payroll == null || _employee == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PAYSLIP',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Status: ${_getStatusText(_payroll!.status)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Employee Details',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text('Name: ${widget.employeeName}'),
                        pw.Text('ID: ${_employee!.employeeId}'),
                        pw.Text('Position: ${_employee!.position}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Payment Details',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Period: ${DateFormat('MMM d').format(_payroll!.payPeriodStart)} - ${DateFormat('MMM d, yyyy').format(_payroll!.payPeriodEnd)}',
                        ),
                        if (_payroll!.paymentDate != null)
                          pw.Text(
                            'Date: ${DateFormat('MMM d, yyyy').format(_payroll!.paymentDate!)}',
                          ),
                        if (_payroll!.paymentReference != null)
                          pw.Text('Ref: ${_payroll!.paymentReference}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Earnings',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Description',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Basic Salary'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '\$${_payroll!.basicSalary.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    ...(_payroll!.allowances.entries.map(
                      (entry) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(entry.key),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '\$${entry.value.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    )),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Gross Salary',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '\$${_payroll!.grossSalary.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Deductions',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Description',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Tax'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '\$${_payroll!.taxAmount.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    ...(_payroll!.deductions.entries.map(
                      (entry) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(entry.key),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '\$${entry.value.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    )),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Total Deductions',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '\$${_payroll!.totalDeductions.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  color: PdfColors.grey200,
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'NET SALARY',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '\$${_payroll!.netSalary.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                if (_payroll!.notes != null && _payroll!.notes!.isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Notes:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(_payroll!.notes!),
                    ],
                  ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'This is a computer-generated document and does not require a signature.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  void dispose() {
    _paymentRefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payroll Details - ${widget.employeeName}'),
        actions: [
          if (_payroll != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printPayslip,
              tooltip: 'Print Payslip',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _payroll == null
              ? const Center(child: Text('Payroll not found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildPayPeriodCard(),
                    const SizedBox(height: 16),
                    _buildEarningsCard(),
                    const SizedBox(height: 16),
                    _buildDeductionsCard(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    if (_payroll!.notes != null && _payroll!.notes!.isNotEmpty)
                      _buildNotesCard(),
                    const SizedBox(height: 16),
                    if (_payroll!.status == PayrollStatus.approved)
                      _buildPaymentCard(),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getStatusColor(_payroll!.status),
              child: Icon(
                _getStatusIcon(_payroll!.status),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(_payroll!.status),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(_payroll!.status),
                    ),
                  ),
                  if (_payroll!.paymentDate != null)
                    Text(
                      'Paid on: ${DateFormat('MMMM d, yyyy').format(_payroll!.paymentDate!)}',
                    ),
                  if (_payroll!.paymentReference != null)
                    Text('Reference: ${_payroll!.paymentReference}'),
                ],
              ),
            ),
            if (_payroll!.status == PayrollStatus.draft ||
                _payroll!.status == PayrollStatus.approved)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // Edit payroll functionality would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit functionality coming soon'),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayPeriodCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pay Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Date',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        DateFormat(
                          'MMMM d, yyyy',
                        ).format(_payroll!.payPeriodStart),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End Date',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        DateFormat(
                          'MMMM d, yyyy',
                        ).format(_payroll!.payPeriodEnd),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earnings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDataRow('Basic Salary', _payroll!.basicSalary),
            const Divider(),
            ..._payroll!.allowances.entries.map(
              (entry) => _buildDataRow(entry.key, entry.value),
            ),
            const Divider(thickness: 2),
            _buildDataRow('Gross Salary', _payroll!.grossSalary, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deductions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDataRow('Tax', _payroll!.taxAmount, isDeduction: true),
            const Divider(),
            ..._payroll!.deductions.entries.map(
              (entry) =>
                  _buildDataRow(entry.key, entry.value, isDeduction: true),
            ),
            const Divider(thickness: 2),
            _buildDataRow(
              'Total Deductions',
              _payroll!.totalDeductions,
              isBold: true,
              isDeduction: true,
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildSummaryCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2, // Adjust flex values as needed
              child: Text(
                'NET SALARY',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 1, // Adjust flex values as needed
              child: Text(
                '\$${_payroll!.netSalary.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.end, // Align text to the right
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_payroll!.notes ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record Payment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _paymentRefController,
              decoration: const InputDecoration(
                labelText: 'Payment Reference',
                hintText: 'Enter bank transfer reference, check number, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _markAsPaid,
                  icon: const Icon(Icons.attach_money),
                  label: const Text('Mark as Paid'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isDeduction = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2, // Adjust flex values as needed
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14,
              ),
              overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
            ),
          ),
          Expanded(
            flex: 1, // Adjust flex values as needed
            child: Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14,
                color: isDeduction ? Colors.red : Colors.green,
              ),
              textAlign: TextAlign.end, // Align text to the right
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(PayrollStatus status) {
    switch (status) {
      case PayrollStatus.draft:
        return 'Draft';
      case PayrollStatus.approved:
        return 'Approved';
      case PayrollStatus.paid:
        return 'Paid';
      case PayrollStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(PayrollStatus status) {
    switch (status) {
      case PayrollStatus.draft:
        return Colors.orange;
      case PayrollStatus.approved:
        return Colors.blue;
      case PayrollStatus.paid:
        return Colors.green;
      case PayrollStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(PayrollStatus status) {
    switch (status) {
      case PayrollStatus.draft:
        return Icons.pending;
      case PayrollStatus.approved:
        return Icons.check_circle;
      case PayrollStatus.paid:
        return Icons.attach_money;
      case PayrollStatus.cancelled:
        return Icons.cancel;
    }
  }
}
