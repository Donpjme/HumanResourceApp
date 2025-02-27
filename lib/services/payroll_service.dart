// payroll_service.dart
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../models/payroll.dart';
import '../models/attendance.dart'; // Add this import for AttendanceStatus
import '../services/database_helper.dart';
import '../services/employee_service.dart';
import '../services/attendance_service.dart';
import '../services/salary_component_service.dart';
import '../services/tax_service.dart';

class PayrollService with ChangeNotifier {
  static final _log = Logger('PayrollService');
  List<Payroll> _payrolls = [];
  final dbHelper = DatabaseHelper.instance;
  final EmployeeService _employeeService;
  final AttendanceService _attendanceService;
  final SalaryComponentService _salaryComponentService;
  final TaxService _taxService;

  PayrollService(
    this._employeeService,
    this._attendanceService,
    this._salaryComponentService,
    this._taxService,
  );

  List<Payroll> get payrolls => _payrolls;

  Future<void> init() async {
    try {
      await loadPayrolls();
    } catch (e, stackTrace) {
      _log.severe('Error initializing payroll service', e, stackTrace);
      rethrow;
    }
  }

  Future<void> loadPayrolls() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tablePayroll,
        orderBy: 'payPeriodEnd DESC',
      );
      _payrolls = List.generate(maps.length, (i) {
        return Payroll.fromJson(maps[i]);
      });
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Error loading payrolls', e, stackTrace);
      _payrolls = [];
      notifyListeners();
      rethrow;
    }
  }

  Future<Payroll> generatePayroll({
    required String employeeId,
    required DateTime payPeriodStart,
    required DateTime payPeriodEnd,
    required double basicSalary,
    Map<String, double>? customAllowances,
    Map<String, double>? customDeductions,
    String? notes,
  }) async {
    try {
      // Check if employee exists
      final employee = await _employeeService.getEmployee(employeeId);
      if (employee == null) {
        throw Exception('Employee not found');
      }

      // Calculate allowances
      final allowanceComponents = await _salaryComponentService.getAllowances();
      final Map<String, double> allowances = {};

      // Add default allowances from components
      for (var component in allowanceComponents) {
        if (component.isActive) {
          double amount = component.defaultAmount;
          if (component.isPercentage) {
            amount = (basicSalary * amount) / 100;
          }
          allowances[component.name] = amount;
        }
      }

      // Override with custom allowances if provided
      if (customAllowances != null) {
        allowances.addAll(customAllowances);
      }

      // Calculate deductions
      final deductionComponents = await _salaryComponentService.getDeductions();
      final Map<String, double> deductions = {};

      // Add default deductions from components
      for (var component in deductionComponents) {
        if (component.isActive) {
          double amount = component.defaultAmount;
          if (component.isPercentage) {
            amount = (basicSalary * amount) / 100;
          }
          deductions[component.name] = amount;
        }
      }

      // Override with custom deductions if provided
      if (customDeductions != null) {
        deductions.addAll(customDeductions);
      }

      // Calculate gross salary
      final allowanceTotal = allowances.values.fold(
        0.0,
        (sum, amount) => sum + amount,
      );
      final grossSalary = basicSalary + allowanceTotal;

      // Calculate tax
      final taxAmount = await _taxService.calculateTax(grossSalary);

      // Calculate deduction total
      final deductionTotal = deductions.values.fold(
        0.0,
        (sum, amount) => sum + amount,
      );

      // Calculate net salary
      final netSalary = grossSalary - taxAmount - deductionTotal;

      // Create payroll object
      final payroll = Payroll(
        employeeId: employeeId,
        payPeriodStart: payPeriodStart,
        payPeriodEnd: payPeriodEnd,
        basicSalary: basicSalary,
        allowances: allowances,
        deductions: deductions,
        taxAmount: taxAmount,
        netSalary: netSalary,
        status: PayrollStatus.draft,
        notes: notes,
      );

      // Save to database
      final db = await dbHelper.database;
      await db.insert(
        DatabaseHelper.tablePayroll,
        payroll.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await loadPayrolls();
      return payroll;
    } catch (e, stackTrace) {
      _log.severe('Error generating payroll', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updatePayrollStatus({
    required String payrollId,
    required PayrollStatus newStatus,
    String? approvedById,
    DateTime? paymentDate,
    String? paymentReference,
  }) async {
    try {
      // Get the current payroll
      final payroll = await getPayroll(payrollId);
      if (payroll == null) {
        throw Exception('Payroll not found');
      }

      // Create updated payroll
      final updatedPayroll = Payroll(
        id: payroll.id,
        employeeId: payroll.employeeId,
        payPeriodStart: payroll.payPeriodStart,
        payPeriodEnd: payroll.payPeriodEnd,
        basicSalary: payroll.basicSalary,
        allowances: payroll.allowances,
        deductions: payroll.deductions,
        taxAmount: payroll.taxAmount,
        netSalary: payroll.netSalary,
        status: newStatus,
        paymentDate:
            newStatus == PayrollStatus.paid
                ? (paymentDate ?? DateTime.now())
                : payroll.paymentDate,
        paymentReference:
            newStatus == PayrollStatus.paid
                ? paymentReference
                : payroll.paymentReference,
        approvedById:
            newStatus == PayrollStatus.approved
                ? approvedById
                : payroll.approvedById,
        createdAt: payroll.createdAt,
        lastModifiedAt: DateTime.now(),
        notes: payroll.notes,
      );

      // Update in database
      final db = await dbHelper.database;
      await db.update(
        DatabaseHelper.tablePayroll,
        updatedPayroll.toJson(),
        where: 'id = ?',
        whereArgs: [payrollId],
      );

      await loadPayrolls();
    } catch (e, stackTrace) {
      _log.severe('Error updating payroll status', e, stackTrace);
      rethrow;
    }
  }

  Future<Payroll?> getPayroll(String id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tablePayroll,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Payroll.fromJson(maps.first);
      }
      return null;
    } catch (e, stackTrace) {
      _log.severe('Error getting payroll', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Payroll>> getEmployeePayrolls(String employeeId) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tablePayroll,
        where: 'employeeId = ?',
        whereArgs: [employeeId],
        orderBy: 'payPeriodEnd DESC',
      );

      return List.generate(maps.length, (i) {
        return Payroll.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      _log.severe('Error getting employee payrolls', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Payroll>> getPayrollsByStatus(PayrollStatus status) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tablePayroll,
        where: 'status = ?',
        whereArgs: [status.toString()],
        orderBy: 'payPeriodEnd DESC',
      );

      return List.generate(maps.length, (i) {
        return Payroll.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      _log.severe('Error getting payrolls by status', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Payroll>> getPayrollsByPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT * FROM ${DatabaseHelper.tablePayroll}
        WHERE 
          (date(payPeriodStart) >= ? AND date(payPeriodStart) <= ?) OR
          (date(payPeriodEnd) >= ? AND date(payPeriodEnd) <= ?)
        ORDER BY payPeriodEnd DESC
        ''',
        [startDateStr, endDateStr, startDateStr, endDateStr],
      );

      return List.generate(maps.length, (i) {
        return Payroll.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      _log.severe('Error getting payrolls by period', e, stackTrace);
      rethrow;
    }
  }

  Future<double> calculateAttendanceAdjustment(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // This is a placeholder for a more complex calculation
      // In a real system, you would calculate based on days present, late, absent, etc.
      final attendances = await _attendanceService.getAttendanceForDateRange(
        startDate,
        endDate,
      );
      final employeeAttendances =
          attendances.where((a) => a.employeeId == employeeId).toList();

      // Total working days in period
      final workingDays = _countWorkingDays(startDate, endDate);

      // Count days present
      final daysPresent =
          employeeAttendances
              .where(
                (a) =>
                    a.status == AttendanceStatus.present ||
                    a.status == AttendanceStatus.late ||
                    a.status == AttendanceStatus.workFromHome,
              )
              .length;

      // Count half days
      final halfDays =
          employeeAttendances
              .where((a) => a.status == AttendanceStatus.halfDay)
              .length;

      // Calculate attendance percentage (counting half days as 0.5)
      final attendancePercentage =
          (daysPresent + (halfDays * 0.5)) / workingDays;

      return attendancePercentage;
    } catch (e, stackTrace) {
      _log.severe('Error calculating attendance adjustment', e, stackTrace);
      rethrow;
    }
  }

  int _countWorkingDays(DateTime start, DateTime end) {
    int workingDays = 0;
    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      // Skip weekends (Saturday and Sunday)
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }

    return workingDays;
  }

  Future<void> deletePayroll(String id) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        DatabaseHelper.tablePayroll,
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadPayrolls();
    } catch (e, stackTrace) {
      _log.severe('Error deleting payroll', e, stackTrace);
      rethrow;
    }
  }

  @override
  void dispose() {
    _payrolls.clear();
    super.dispose();
  }
}
