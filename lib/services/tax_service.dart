// tax_service.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import '../models/tax_rule.dart';
import '../services/database_helper.dart';

class TaxService with ChangeNotifier {
  static final _log = Logger('TaxService');
  List<TaxRule> _taxRules = [];
  final dbHelper = DatabaseHelper.instance;

  List<TaxRule> get taxRules => _taxRules;

  Future<void> init() async {
    try {
      await loadTaxRules();
    } catch (e, stackTrace) {
      _log.severe('Error initializing tax service', e, stackTrace);
      rethrow;
    }
  }

  Future<void> loadTaxRules() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableTaxRule,
        orderBy: 'minIncome ASC',
      );
      _taxRules = List.generate(maps.length, (i) {
        return TaxRule.fromJson(maps[i]);
      });
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Error loading tax rules', e, stackTrace);
      _taxRules = [];
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addTaxRule(TaxRule taxRule) async {
    try {
      final db = await dbHelper.database;
      await db.insert(
        DatabaseHelper.tableTaxRule,
        taxRule.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await loadTaxRules();
    } catch (e, stackTrace) {
      _log.severe('Error adding tax rule', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateTaxRule(String id, TaxRule updatedTaxRule) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        DatabaseHelper.tableTaxRule,
        updatedTaxRule.toJson(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadTaxRules();
    } catch (e, stackTrace) {
      _log.severe('Error updating tax rule', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteTaxRule(String id) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        DatabaseHelper.tableTaxRule,
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadTaxRules();
    } catch (e, stackTrace) {
      _log.severe('Error deleting tax rule', e, stackTrace);
      rethrow;
    }
  }

  Future<TaxRule?> getTaxRule(String id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableTaxRule,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return TaxRule.fromJson(maps.first);
      }
      return null;
    } catch (e, stackTrace) {
      _log.severe('Error getting tax rule', e, stackTrace);
      rethrow;
    }
  }

  Future<double> calculateTax(double income) async {
    try {
      await loadTaxRules();
      
      // Filter active tax rules
      final activeTaxRules = _taxRules.where((rule) => rule.isActive).toList();
      
      if (activeTaxRules.isEmpty) {
        return 0;
      }
      
      // Sort by minimum income
      activeTaxRules.sort((a, b) => a.minIncome.compareTo(b.minIncome));
      
      double taxAmount = 0;
      double remainingIncome = income;
      
      for (int i = 0; i < activeTaxRules.length; i++) {
        final rule = activeTaxRules[i];
        
        // If we've taxed all income, break
        if (remainingIncome <= 0) {
          break;
        }
        
        // Calculate taxable amount for this bracket
        double taxableInThisBracket;
        
        if (income <= rule.maxIncome) {
          // All remaining income is taxed at this rate
          taxableInThisBracket = remainingIncome;
          remainingIncome = 0;
        } else {
          // Only part of income is taxed at this rate
          final nextMin = (i < activeTaxRules.length - 1) 
              ? activeTaxRules[i + 1].minIncome 
              : double.infinity;
          
          taxableInThisBracket = nextMin - rule.minIncome;
          remainingIncome -= taxableInThisBracket;
        }
        
        // Calculate tax for this bracket
        final bracketTax = taxableInThisBracket * (rule.rate / 100);
        taxAmount += bracketTax;
      }
      
      return taxAmount;
    } catch (e, stackTrace) {
      _log.severe('Error calculating tax', e, stackTrace);
      // Return 0 tax in case of errors to prevent blocking payroll generation
      return 0;
    }
  }

  @override
  void dispose() {
    _taxRules.clear();
    super.dispose();
  }
}

