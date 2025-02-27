import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import '../models/leave.dart';
import '../services/database_helper.dart';
import '../services/employee_service.dart';

class LeaveService with ChangeNotifier {
  static final _log = Logger('LeaveService');
  List<Leave> _leaves = [];
  final dbHelper = DatabaseHelper.instance;
  final EmployeeService _employeeService;

  LeaveService(this._employeeService);

  List<Leave> get leaves => _leaves;

  Future<void> init() async {
    try {
      await loadLeaves();
    } catch (e, stackTrace) {
      _log.severe('Error initializing leave service', e, stackTrace);
      rethrow;
    }
  }

  Future<void> loadLeaves() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableLeave,
        orderBy: 'createdAt DESC',
      );
      _leaves = List.generate(maps.length, (i) {
        return Leave.fromJson(maps[i]);
      });
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Error loading leaves', e, stackTrace);
      _leaves = [];
      notifyListeners();
      rethrow;
    }
  }

  Future<Leave> applyLeave({
    required String employeeId,
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      // Validate dates
      if (endDate.isBefore(startDate)) {
        throw Exception('End date cannot be before start date');
      }

      // Check if employee exists
      final employee = await _employeeService.getEmployee(employeeId);
      if (employee == null) {
        throw Exception('Employee not found');
      }

      // Create employee name for display
      final employeeName = '${employee.firstname} ${employee.lastname}';

      // Check for overlapping leaves
      final existingLeaves = await getEmployeeLeaves(employeeId);
      final hasOverlap = existingLeaves.any((leave) {
        if (leave.status == LeaveStatus.rejected ||
            leave.status == LeaveStatus.cancelled) {
          return false; // Ignore rejected or cancelled leaves
        }

        // Check for date overlap
        return (startDate.isBefore(leave.endDate) ||
                startDate.isAtSameMomentAs(leave.endDate)) &&
            (endDate.isAfter(leave.startDate) ||
                endDate.isAtSameMomentAs(leave.startDate));
      });

      if (hasOverlap) {
        throw Exception('Leave request overlaps with an existing leave');
      }

      // Create leave object
      final leave = Leave(
        employeeId: employeeId,
        employeeName: employeeName,
        type: type,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        status: LeaveStatus.pending,
      );

      // Save to database
      final db = await dbHelper.database;
      await db.insert(
        DatabaseHelper.tableLeave,
        leave.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await loadLeaves();
      return leave;
    } catch (e, stackTrace) {
      _log.severe('Error applying for leave', e, stackTrace);
      rethrow;
    }
  }

  Future<Leave> updateLeaveStatus({
    required String leaveId,
    required LeaveStatus newStatus,
    String? approvedById,
    String? rejectionReason,
  }) async {
    try {
      // Find the leave
      final leave = await getLeave(leaveId);
      if (leave == null) {
        throw Exception('Leave not found');
      }

      // Create updated leave
      final updatedLeave = Leave(
        id: leave.id,
        employeeId: leave.employeeId,
        employeeName: leave.employeeName,
        type: leave.type,
        startDate: leave.startDate,
        endDate: leave.endDate,
        reason: leave.reason,
        status: newStatus,
        approvedById:
            newStatus == LeaveStatus.approved
                ? approvedById
                : leave.approvedById,
        rejectionReason:
            newStatus == LeaveStatus.rejected
                ? rejectionReason
                : leave.rejectionReason,
        createdAt: leave.createdAt,
        lastModifiedAt: DateTime.now(),
      );

      // Update in database
      final db = await dbHelper.database;
      await db.update(
        DatabaseHelper.tableLeave,
        updatedLeave.toJson(),
        where: 'id = ?',
        whereArgs: [leaveId],
      );

      await loadLeaves();
      return updatedLeave;
    } catch (e, stackTrace) {
      _log.severe('Error updating leave status', e, stackTrace);
      rethrow;
    }
  }

  Future<Leave?> getLeave(String id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableLeave,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Leave.fromJson(maps.first);
      }
      return null;
    } catch (e, stackTrace) {
      _log.severe('Error getting leave', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Leave>> getEmployeeLeaves(String employeeId) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableLeave,
        where: 'employeeId = ?',
        whereArgs: [employeeId],
        orderBy: 'startDate DESC',
      );

      return List.generate(maps.length, (i) {
        return Leave.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      _log.severe('Error getting employee leaves', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Leave>> getPendingLeaves() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableLeave,
        where: 'status = ?',
        whereArgs: [LeaveStatus.pending.toString()],
        orderBy: 'startDate ASC',
      );

      return List.generate(maps.length, (i) {
        return Leave.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      _log.severe('Error getting pending leaves', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Leave>> getLeavesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat(
        'yyyy-MM-dd',
      ).format(endDate.add(const Duration(days: 1)));

      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT * FROM ${DatabaseHelper.tableLeave}
        WHERE 
          (date(startDate) >= ? AND date(startDate) < ?) OR
          (date(endDate) >= ? AND date(endDate) < ?) OR
          (date(startDate) <= ? AND date(endDate) >= ?)
        ORDER BY startDate DESC
        ''',
        [
          startDateStr,
          endDateStr,
          startDateStr,
          endDateStr,
          startDateStr,
          startDateStr,
        ],
      );

      return List.generate(maps.length, (i) {
        return Leave.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      _log.severe('Error getting leaves for date range', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Leave>> getCurrentLeaves() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT * FROM ${DatabaseHelper.tableLeave}
        WHERE 
          status = ? AND
          date(startDate) <= ? AND
          date(endDate) >= ?
        ORDER BY startDate ASC
        ''',
        [LeaveStatus.approved.toString(), today, today],
      );

      return List.generate(maps.length, (i) {
        return Leave.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      _log.severe('Error getting current leaves', e, stackTrace);
      rethrow;
    }
  }

  Future<void> cancelLeave(String leaveId) async {
    await updateLeaveStatus(leaveId: leaveId, newStatus: LeaveStatus.cancelled);
  }

  @override
  void dispose() {
    _leaves.clear();
    super.dispose();
  }
}
