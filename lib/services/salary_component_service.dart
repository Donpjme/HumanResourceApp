// salary_component_service.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import '../models/salary_component.dart';
import '../services/database_helper.dart';

class SalaryComponentService with ChangeNotifier {
  static final _log = Logger('SalaryComponentService');
  List<SalaryComponent> _components = [];
  final dbHelper = DatabaseHelper.instance;

  List<SalaryComponent> get components => _components;

  Future<void> init() async {
    try {
      await loadComponents();
    } catch (e, stackTrace) {
      _log.severe('Error initializing salary component service', e, stackTrace);
      rethrow;
    }
  }

  Future<void> loadComponents() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableSalaryComponent,
      );
      _components = List.generate(maps.length, (i) {
        return SalaryComponent.fromJson(maps[i]);
      });
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Error loading salary components', e, stackTrace);
      _components = [];
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addComponent(SalaryComponent component) async {
    try {
      final db = await dbHelper.database;
      await db.insert(
        DatabaseHelper.tableSalaryComponent,
        component.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await loadComponents();
    } catch (e, stackTrace) {
      _log.severe('Error adding salary component', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateComponent(
    String id,
    SalaryComponent updatedComponent,
  ) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        DatabaseHelper.tableSalaryComponent,
        updatedComponent.toJson(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadComponents();
    } catch (e, stackTrace) {
      _log.severe('Error updating salary component', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteComponent(String id) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        DatabaseHelper.tableSalaryComponent,
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadComponents();
    } catch (e, stackTrace) {
      _log.severe('Error deleting salary component', e, stackTrace);
      rethrow;
    }
  }

  Future<SalaryComponent?> getComponent(String id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableSalaryComponent,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return SalaryComponent.fromJson(maps.first);
      }
      return null;
    } catch (e, stackTrace) {
      _log.severe('Error getting salary component', e, stackTrace);
      rethrow;
    }
  }

  Future<List<SalaryComponent>> getAllowances() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableSalaryComponent,
        where: 'type = ?',
        whereArgs: [ComponentType.allowance.toString()],
      );

      return List.generate(maps.length, (i) {
        return SalaryComponent.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      _log.severe('Error getting allowances', e, stackTrace);
      rethrow;
    }
  }

  Future<List<SalaryComponent>> getDeductions() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableSalaryComponent,
        where: 'type = ?',
        whereArgs: [ComponentType.deduction.toString()],
      );

      return List.generate(maps.length, (i) {
        return SalaryComponent.fromJson(maps[i]);
      });
    } catch (e, stackTrace) {
      _log.severe('Error getting deductions', e, stackTrace);
      rethrow;
    }
  }

  @override
  void dispose() {
    _components.clear();
    super.dispose();
  }
}
