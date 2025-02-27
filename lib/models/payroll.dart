// payroll.dart
import 'package:uuid/uuid.dart';

enum PayrollStatus { draft, approved, paid, cancelled }

class Payroll {
  final String id;
  final String employeeId;
  final DateTime payPeriodStart;
  final DateTime payPeriodEnd;
  final double basicSalary;
  final Map<String, double> allowances;
  final Map<String, double> deductions;
  final double taxAmount;
  final double netSalary;
  final PayrollStatus status;
  final DateTime? paymentDate;
  final String? paymentReference;
  final String? approvedById;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;
  final String? notes;

  Payroll({
    String? id,
    required this.employeeId,
    required this.payPeriodStart,
    required this.payPeriodEnd,
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
    required this.taxAmount,
    required this.netSalary,
    this.status = PayrollStatus.draft,
    this.paymentDate,
    this.paymentReference,
    this.approvedById,
    DateTime? createdAt,
    this.lastModifiedAt,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get grossSalary {
    final allowanceTotal = allowances.values.fold(0.0, (sum, amount) => sum + amount);
    return basicSalary + allowanceTotal;
  }

  double get totalDeductions {
    final deductionTotal = deductions.values.fold(0.0, (sum, amount) => sum + amount);
    return deductionTotal + taxAmount;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'payPeriodStart': payPeriodStart.toIso8601String(),
      'payPeriodEnd': payPeriodEnd.toIso8601String(),
      'basicSalary': basicSalary,
      'allowances': allowancesToJson(),
      'deductions': deductionsToJson(),
      'taxAmount': taxAmount,
      'netSalary': netSalary,
      'status': status.toString(),
      'paymentDate': paymentDate?.toIso8601String(),
      'paymentReference': paymentReference,
      'approvedById': approvedById,
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  String allowancesToJson() {
    final entries = allowances.entries.map((e) => '${e.key}:${e.value}').join(',');
    return entries;
  }

  String deductionsToJson() {
    final entries = deductions.entries.map((e) => '${e.key}:${e.value}').join(',');
    return entries;
  }

  static Map<String, double> parseMapFromString(String str) {
    if (str.isEmpty) return {};
    
    final Map<String, double> result = {};
    final entries = str.split(',');
    for (var entry in entries) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        final key = parts[0];
        final value = double.tryParse(parts[1]) ?? 0.0;
        result[key] = value;
      }
    }
    return result;
  }

  factory Payroll.fromJson(Map<String, dynamic> json) {
    return Payroll(
      id: json['id'],
      employeeId: json['employeeId'],
      payPeriodStart: DateTime.parse(json['payPeriodStart']),
      payPeriodEnd: DateTime.parse(json['payPeriodEnd']),
      basicSalary: json['basicSalary'],
      allowances: parseMapFromString(json['allowances']),
      deductions: parseMapFromString(json['deductions']),
      taxAmount: json['taxAmount'],
      netSalary: json['netSalary'],
      status: _parsePayrollStatus(json['status']),
      paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate']) : null,
      paymentReference: json['paymentReference'],
      approvedById: json['approvedById'],
      createdAt: DateTime.parse(json['createdAt']),
      lastModifiedAt: json['lastModifiedAt'] != null ? DateTime.parse(json['lastModifiedAt']) : null,
      notes: json['notes'],
    );
  }

  static PayrollStatus _parsePayrollStatus(String status) {
    return PayrollStatus.values.firstWhere(
      (e) => e.toString() == status,
      orElse: () => PayrollStatus.draft,
    );
  }
}


