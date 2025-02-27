import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import 'database_helper.dart';
import 'employee_service.dart';

class AttendanceService with ChangeNotifier {
  static final _log = Logger('AttendanceService');
  List<Attendance> _attendances = [];
  final dbHelper = DatabaseHelper.instance;
  final EmployeeService _employeeService;

  AttendanceService(this._employeeService);

  List<Attendance> get attendances => _attendances;

  Future<void> init() async {
    try {
      await loadAttendances();
    } catch (e, stackTrace) {
      _log.severe('Error initializing attendance service', e, stackTrace);
      rethrow;
    }
  }

  Future<void> loadAttendances() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableAttendance,
      );
      _attendances = List.generate(maps.length, (i) {
        return Attendance.fromJson(maps[i]);
      });
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Error loading attendances', e, stackTrace);
      _attendances = [];
      notifyListeners();
      rethrow;
    }
  }

  Future<Attendance?> clockIn(String employeeId, {String notes = ''}) async {
    try {
      // Check if employee exists
      final employee = await _employeeService.getEmployee(employeeId);
      if (employee == null) {
        throw Exception('Employee not found');
      }

      // Check if employee is already clocked in for today
      final todaysAttendance = await getTodaysAttendance(employeeId);
      if (todaysAttendance != null && todaysAttendance.isActive) {
        throw Exception('Employee is already clocked in');
      }

      final now = DateTime.now();

      // Determine if late (after 9:00 AM)
      final workStartTime = DateTime(
        now.year,
        now.month,
        now.day,
        9,
        0,
        0,
      ); // 9:00 AM

      final status =
          now.isAfter(workStartTime)
              ? AttendanceStatus.late
              : AttendanceStatus.present;

      final attendance = Attendance(
        employeeId: employeeId,
        clockInTime: now,
        notes: notes,
        status: status,
      );

      final db = await dbHelper.database;
      await db.insert(
        DatabaseHelper.tableAttendance,
        attendance.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await loadAttendances();
      return attendance;
    } catch (e, stackTrace) {
      _log.severe('Error clocking in', e, stackTrace);
      rethrow;
    }
  }

  Future<Attendance?> clockOut(String employeeId, {String notes = ''}) async {
    try {
      // Find active attendance for employee
      final activeAttendance = _attendances.firstWhere(
        (a) => a.employeeId == employeeId && a.isActive,
        orElse:
            () => throw Exception('No active attendance found for employee'),
      );

      // Create updated attendance with clock out
      final updatedAttendance = Attendance(
        id: activeAttendance.id,
        employeeId: activeAttendance.employeeId,
        clockInTime: activeAttendance.clockInTime,
        clockOutTime: DateTime.now(),
        notes: notes.isNotEmpty ? notes : activeAttendance.notes,
        status: activeAttendance.status,
        createdAt: activeAttendance.createdAt,
        lastModifiedAt: DateTime.now(),
      );

      // Update in database
      final db = await dbHelper.database;
      await db.update(
        DatabaseHelper.tableAttendance,
        updatedAttendance.toJson(),
        where: 'id = ?',
        whereArgs: [activeAttendance.id],
      );

      await loadAttendances();
      return updatedAttendance;
    } catch (e, stackTrace) {
      _log.severe('Error clocking out', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateAttendance(String id, Attendance updatedAttendance) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        DatabaseHelper.tableAttendance,
        updatedAttendance.toJson(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadAttendances();
    } catch (e, stackTrace) {
      _log.severe('Error updating attendance', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteAttendance(String id) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        DatabaseHelper.tableAttendance,
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadAttendances();
    } catch (e, stackTrace) {
      _log.severe('Error deleting attendance', e, stackTrace);
      rethrow;
    }
  }

  Future<Attendance?> getAttendance(String id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableAttendance,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Attendance.fromJson(maps.first);
      }
      return null;
    } catch (e, stackTrace) {
      _log.severe('Error getting attendance', e, stackTrace);
      rethrow;
    }
  }

  Future<Attendance?> getTodaysAttendance(String employeeId) async {
    try {
      final today = DateTime.now();
      final dateString = DateFormat('yyyy-MM-dd').format(today);

      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT * FROM ${DatabaseHelper.tableAttendance}
        WHERE employeeId = ? 
        AND date(clockInTime) = ?
        ''',
        [employeeId, dateString],
      );

      if (maps.isNotEmpty) {
        return Attendance.fromJson(maps.first);
      }
      return null;
    } catch (e, stackTrace) {
      _log.severe('Error getting today\'s attendance', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> isEmployeeClockingIn(String employeeId) async {
    final attendance = await getTodaysAttendance(employeeId);
    return attendance == null || !attendance.isActive;
  }

  Future<List<Attendance>> getEmployeeAttendance(String employeeId) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableAttendance,
        where: 'employeeId = ?',
        whereArgs: [employeeId],
        orderBy: 'clockInTime DESC',
      );

      return List.generate(maps.length, (i) {
        return Attendance.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      _log.severe('Error getting employee attendance', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Attendance>> getAttendanceForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(
        endDate.add(const Duration(days: 1)),
      ); // Add a day to include endDate

      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT * FROM ${DatabaseHelper.tableAttendance}
        WHERE date(clockInTime) >= ? AND date(clockInTime) < ?
        ORDER BY clockInTime DESC
        ''',
        [startDateStr, endDateStr],
      );

      return List.generate(maps.length, (i) {
        return Attendance.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      _log.severe('Error getting attendance for date range', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<AttendanceStatus, int>> getAttendanceStatusCounts(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final attendances = await getAttendanceForDateRange(startDate, endDate);

      final Map<AttendanceStatus, int> counts = {
        for (var status in AttendanceStatus.values) status: 0,
      };

      for (var attendance in attendances) {
        counts[attendance.status] = (counts[attendance.status] ?? 0) + 1;
      }

      return counts;
    } catch (e, stackTrace) {
      _log.severe('Error getting attendance status counts', e, stackTrace);
      rethrow;
    }
  }

  @override
  void dispose() {
    _attendances.clear();
    super.dispose();
  }
}
