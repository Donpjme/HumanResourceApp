import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import '../models/role.dart';
import '../models/permissions.dart';
import 'database_helper.dart';

class RoleService with ChangeNotifier {
  static final _log = Logger('RoleService');
  List<Role> _roles = [];
  final dbHelper = DatabaseHelper.instance;

  List<Role> get roles => _roles;

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

      await loadRoles();
    } catch (e, stackTrace) {
      _log.severe('Error initializing role service', e, stackTrace);
      rethrow;
    }
  }

  Future<void> loadRoles() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableRoles,
      );
      _roles = List.generate(maps.length, (i) {
        return Role.fromJson(maps[i]);
      });
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Error loading roles', e, stackTrace);
      _roles = [];
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addRole(Role role) async {
    try {
      final db = await dbHelper.database;
      await db.insert(
        DatabaseHelper.tableRoles,
        role.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await loadRoles();
    } catch (e, stackTrace) {
      _log.severe('Error adding role', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateRole(String id, Role updatedRole) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        DatabaseHelper.tableRoles,
        updatedRole.toJson(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadRoles();
    } catch (e, stackTrace) {
      _log.severe('Error updating role', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        DatabaseHelper.tableRoles,
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadRoles();
    } catch (e, stackTrace) {
      _log.severe('Error deleting role', e, stackTrace);
      rethrow;
    }
  }

  Future<Role?> getRole(String id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableRoles,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Role.fromJson(maps.first);
      }
      return null;
    } catch (e, stackTrace) {
      _log.severe('Error getting role', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Role>> searchRoles(String query) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableRoles,
        where: 'name LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
      );

      return List.generate(maps.length, (i) {
        return Role.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      _log.severe('Error searching roles', e, stackTrace);
      rethrow;
    }
  }

  bool hasPermission(Role role, Permission permission) {
    return role.permissions.contains(permission);
  }

  List<Role> getDefaultRoles() {
    return [
      Role(
        name: 'Administrator',
        description: 'Full system access',
        permissions: Permission.values.toList(),
        createdAt: DateTime.now(),
      ),
      Role(
        name: 'Medical Director',
        description: 'Overall management of medical operations',
        department: 'Management',
        permissions: Permission.values.toList(),
      ),
      Role(
        name: 'Laboratory Manager',
        description: 'Management of laboratory operations and staff',
        department: 'Laboratory',
        permissions: [
          Permission.viewPatientRecords,
          Permission.viewTestResults,
          Permission.editTestResults,
          Permission.approveTestResults,
          Permission.viewInventory,
          Permission.manageInventory,
          Permission.qualityControl,
          Permission.equipmentMaintenance,
          Permission.viewEmployees,
          Permission.createEmployee,
          Permission.editEmployee,
          Permission.viewAttendance,
          Permission.manageAttendance,
          Permission.viewReports,
          Permission.exportData,
        ],
      ),
      Role(
        name: 'Pathologist',
        description: 'Diagnostic interpretation and reporting',
        department: 'Laboratory',
        permissions: [
          Permission.viewPatientRecords,
          Permission.createPatientRecords,
          Permission.editPatientRecords,
          Permission.orderTests,
          Permission.viewTestResults,
          Permission.editTestResults,
          Permission.approveTestResults,
          Permission.prescribeMedication,
          Permission.qualityControl,
          Permission.viewReports,
          Permission.exportData,
        ],
      ),
      Role(
        name: 'Medical Laboratory Scientist',
        description: 'Laboratory testing and analysis',
        department: 'Laboratory',
        permissions: [
          Permission.viewPatientRecords,
          Permission.performTests,
          Permission.viewTestResults,
          Permission.editTestResults,
          Permission.sampleManagement,
          Permission.viewInventory,
          Permission.qualityControl,
          Permission.viewReports,
        ],
      ),
      Role(
        name: 'Phlebotomist',
        description: 'Blood collection and sample management',
        department: 'Laboratory',
        permissions: [
          Permission.viewPatientRecords,
          Permission.createPatientRecords,
          Permission.sampleManagement,
          Permission.viewTestResults,
          Permission.viewInventory,
        ],
      ),
      Role(
        name: 'Quality Control Officer',
        description: 'Quality assurance and compliance',
        department: 'Quality Management',
        permissions: [
          Permission.viewPatientRecords,
          Permission.viewTestResults,
          Permission.qualityControl,
          Permission.viewInventory,
          Permission.equipmentMaintenance,
          Permission.viewReports,
          Permission.exportData,
          Permission.accessAuditLogs,
        ],
      ),
      Role(
        name: 'HR Manager',
        description: 'Human resources management',
        department: 'Human Resources',
        permissions: [
          Permission.viewEmployees,
          Permission.createEmployee,
          Permission.editEmployee,
          Permission.deleteEmployee,
          Permission.viewAttendance,
          Permission.manageAttendance,
          Permission.viewPayroll,
          Permission.managePayroll,
          Permission.viewReports,
          Permission.exportData,
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _roles.clear();
    super.dispose();
  }
}
