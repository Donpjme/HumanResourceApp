import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import '../models/employee.dart';
import '../services/database_helper.dart';

class EmployeeService with ChangeNotifier {
  static final _log = Logger('EmployeeService');
  List<Employee> _employees = [];
  final dbHelper = DatabaseHelper.instance;

  List<Employee> get employees => _employees;

  Future<void> loadEmployees() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableEmployees,
      );
      _employees = List.generate(maps.length, (i) {
        return Employee.fromJson(maps[i]);
      });
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Error loading employees', e, stackTrace);
      _employees = [];
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addEmployee(Employee employee) async {
    try {
      final db = await dbHelper.database;
      await db.insert(
        DatabaseHelper.tableEmployees,
        employee.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await loadEmployees();
    } catch (e, stackTrace) {
      _log.severe('Error adding employee', e, stackTrace);
      rethrow;
    }
  }

  Future<void> editEmployee(String id, Employee updatedEmployee) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        DatabaseHelper.tableEmployees,
        updatedEmployee.toJson(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadEmployees();
    } catch (e, stackTrace) {
      _log.severe('Error updating employee', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteEmployee(String id) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        DatabaseHelper.tableEmployees,
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadEmployees();
    } catch (e, stackTrace) {
      _log.severe('Error deleting employee', e, stackTrace);
      rethrow;
    }
  }

  Future<Employee?> getEmployee(String id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableEmployees,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Employee.fromJson(maps.first);
      }
      return null;
    } catch (e, stackTrace) {
      _log.severe('Error getting employee', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Employee>> searchEmployees(String query) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableEmployees,
        where: 'firstname LIKE ? OR lastname LIKE ? OR employeeId LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
      );

      return List.generate(maps.length, (i) {
        return Employee.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      _log.severe('Error searching employees', e, stackTrace);
      rethrow;
    }
  }

  Future<void> init() async {
    try {
      // Initialize logging
      if (kDebugMode) {
        Logger.root.level = Level.ALL;
        Logger.root.onRecord.listen((record) {
          debugPrint(
            '${record.level.name}: ${record.time}: ${record.message}\n'
            '${record.error ?? ''}\n'
            '${record.stackTrace ?? ''}',
          );
        });
      }

      await loadEmployees();
    } catch (e, stackTrace) {
      _log.severe('Error initializing employee service', e, stackTrace);
      rethrow;
    }
  }

  @override
  void dispose() {
    _employees.clear();
    super.dispose();
  }
}
