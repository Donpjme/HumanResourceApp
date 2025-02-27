import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import '../models/salary_component.dart';
import '../services/role_service.dart';

class DatabaseHelper {
  static final _log = Logger('DatabaseHelper');
  static const String _databaseName = "hrm_database.db";
  static const int _databaseVersion =
      4; // Incremented version number for payroll tables

  static const String tableRoles = 'roles';
  static const String tableEmployees = 'employees';
  static const String tableAttendance = 'attendance';
  static const String tableLeave = 'leave';
  static const String tablePayroll = 'payroll';
  static const String tableTaxRule = 'tax_rule';
  static const String tableSalaryComponent = 'salary_component';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    try {
      _log.info('Initializing database...');
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      _log.info('Database path: $path');

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) {
          _log.info('Database opened successfully');
        },
      );
    } catch (e, stackTrace) {
      _log.severe('Error initializing database', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      _log.info('Creating database tables...');

      await db.execute('''
        CREATE TABLE $tableRoles (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          department TEXT NOT NULL,
          permissions TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          lastModifiedAt TEXT,
          isActive INTEGER NOT NULL DEFAULT 1
        )
      ''');
      _log.info('Roles table created');

      await db.execute('''
        CREATE TABLE $tableEmployees (
          id TEXT PRIMARY KEY,
          employeeId TEXT NOT NULL,
          firstname TEXT NOT NULL,
          lastname TEXT NOT NULL,
          email TEXT NOT NULL,
          phone TEXT NOT NULL,
          position TEXT NOT NULL,
          roleId TEXT NOT NULL,
          joiningDate TEXT NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1,
          createdAt TEXT NOT NULL,
          lastModifiedAt TEXT,
          FOREIGN KEY (roleId) REFERENCES $tableRoles (id)
        )
      ''');
      _log.info('Employees table created');

      await db.execute('''
        CREATE TABLE $tableAttendance (
          id TEXT PRIMARY KEY,
          employeeId TEXT NOT NULL,
          clockInTime TEXT NOT NULL,
          clockOutTime TEXT,
          notes TEXT,
          status TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          lastModifiedAt TEXT,
          FOREIGN KEY (employeeId) REFERENCES $tableEmployees (id)
        )
      ''');
      _log.info('Attendance table created');

      await db.execute('''
        CREATE TABLE $tableLeave (
          id TEXT PRIMARY KEY,
          employeeId TEXT NOT NULL,
          employeeName TEXT NOT NULL,
          type TEXT NOT NULL,
          startDate TEXT NOT NULL,
          endDate TEXT NOT NULL,
          reason TEXT NOT NULL,
          status TEXT NOT NULL,
          approvedById TEXT,
          rejectionReason TEXT,
          createdAt TEXT NOT NULL,
          lastModifiedAt TEXT,
          FOREIGN KEY (employeeId) REFERENCES $tableEmployees (id)
        )
      ''');
      _log.info('Leave table created');

      // New tables for payroll management
      await db.execute('''
        CREATE TABLE $tableSalaryComponent (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          isTaxable INTEGER NOT NULL,
          defaultAmount REAL NOT NULL,
          isPercentage INTEGER NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1,
          createdAt TEXT NOT NULL,
          lastModifiedAt TEXT
        )
      ''');
      _log.info('Salary Component table created');

      await db.execute('''
        CREATE TABLE $tableTaxRule (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          minIncome REAL NOT NULL,
          maxIncome REAL NOT NULL,
          rate REAL NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1,
          createdAt TEXT NOT NULL,
          lastModifiedAt TEXT
        )
      ''');
      _log.info('Tax Rule table created');

      await db.execute('''
        CREATE TABLE $tablePayroll (
          id TEXT PRIMARY KEY,
          employeeId TEXT NOT NULL,
          payPeriodStart TEXT NOT NULL,
          payPeriodEnd TEXT NOT NULL,
          basicSalary REAL NOT NULL,
          allowances TEXT NOT NULL,
          deductions TEXT NOT NULL,
          taxAmount REAL NOT NULL,
          netSalary REAL NOT NULL,
          status TEXT NOT NULL,
          paymentDate TEXT,
          paymentReference TEXT,
          approvedById TEXT,
          notes TEXT,
          createdAt TEXT NOT NULL,
          lastModifiedAt TEXT,
          FOREIGN KEY (employeeId) REFERENCES $tableEmployees (id)
        )
      ''');
      _log.info('Payroll table created');

      _log.info('Database tables created successfully');
    } catch (e, stackTrace) {
      _log.severe('Error creating database tables', e, stackTrace);
      rethrow;
    }
  }

  // Add upgrade function to handle version changes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      _log.info('Upgrading database from version $oldVersion to $newVersion');

      if (oldVersion < 2) {
        // For upgrade from version 1 to 2 or higher
        // Get existing employees if any
        List<Map<String, dynamic>> existingEmployees = [];
        try {
          existingEmployees = await db.query(tableEmployees);
          _log.info(
            'Found ${existingEmployees.length} existing employees to migrate',
          );
        } catch (e) {
          _log.warning('Could not retrieve existing employees: $e');
        }

        // Drop existing tables
        await db.execute('DROP TABLE IF EXISTS $tableEmployees');
        await db.execute('DROP TABLE IF EXISTS $tableRoles');

        // Recreate tables
        await db.execute('''
          CREATE TABLE $tableRoles (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            department TEXT NOT NULL,
            permissions TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            lastModifiedAt TEXT,
            isActive INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE $tableEmployees (
            id TEXT PRIMARY KEY,
            employeeId TEXT NOT NULL,
            firstname TEXT NOT NULL,
            lastname TEXT NOT NULL,
            email TEXT NOT NULL,
            phone TEXT NOT NULL,
            position TEXT NOT NULL,
            roleId TEXT NOT NULL,
            joiningDate TEXT NOT NULL,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt TEXT NOT NULL,
            lastModifiedAt TEXT,
            FOREIGN KEY (roleId) REFERENCES $tableRoles (id)
          )
        ''');
      }

      if (oldVersion < 3) {
        // Add new tables for version 3
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableAttendance (
            id TEXT PRIMARY KEY,
            employeeId TEXT NOT NULL,
            clockInTime TEXT NOT NULL,
            clockOutTime TEXT,
            notes TEXT,
            status TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            lastModifiedAt TEXT,
            FOREIGN KEY (employeeId) REFERENCES $tableEmployees (id)
          )
        ''');
        _log.info('Attendance table created');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableLeave (
            id TEXT PRIMARY KEY,
            employeeId TEXT NOT NULL,
            employeeName TEXT NOT NULL,
            type TEXT NOT NULL,
            startDate TEXT NOT NULL,
            endDate TEXT NOT NULL,
            reason TEXT NOT NULL,
            status TEXT NOT NULL,
            approvedById TEXT,
            rejectionReason TEXT,
            createdAt TEXT NOT NULL,
            lastModifiedAt TEXT,
            FOREIGN KEY (employeeId) REFERENCES $tableEmployees (id)
          )
        ''');
        _log.info('Leave table created');
      }

      if (oldVersion < 4) {
        // Add new tables for version 4 (payroll management)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableSalaryComponent (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            isTaxable INTEGER NOT NULL,
            defaultAmount REAL NOT NULL,
            isPercentage INTEGER NOT NULL,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt TEXT NOT NULL,
            lastModifiedAt TEXT
          )
        ''');
        _log.info('Salary Component table created');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableTaxRule (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            minIncome REAL NOT NULL,
            maxIncome REAL NOT NULL,
            rate REAL NOT NULL,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt TEXT NOT NULL,
            lastModifiedAt TEXT
          )
        ''');
        _log.info('Tax Rule table created');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tablePayroll (
            id TEXT PRIMARY KEY,
            employeeId TEXT NOT NULL,
            payPeriodStart TEXT NOT NULL,
            payPeriodEnd TEXT NOT NULL,
            basicSalary REAL NOT NULL,
            allowances TEXT NOT NULL,
            deductions TEXT NOT NULL,
            taxAmount REAL NOT NULL,
            netSalary REAL NOT NULL,
            status TEXT NOT NULL,
            paymentDate TEXT,
            paymentReference TEXT,
            approvedById TEXT,
            notes TEXT,
            createdAt TEXT NOT NULL,
            lastModifiedAt TEXT,
            FOREIGN KEY (employeeId) REFERENCES $tableEmployees (id)
          )
        ''');
        _log.info('Payroll table created');
      }
    } catch (e, stackTrace) {
      _log.severe('Error upgrading database', e, stackTrace);
      rethrow;
    }
  }

  Future<void> initializeDefaultRoles() async {
    try {
      _log.info('Initializing default roles...');
      final db = await database;

      // Warning fixed: removed unnecessary null check
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableRoles'),
      );

      if (count == 0) {
        _log.info('No roles found. Creating default roles...');
        // ignore: unused_local_variable
        final now = DateTime.now().toIso8601String();

        // Get all default roles from RoleService
        final roleService = RoleService();
        final defaultRoles = roleService.getDefaultRoles();

        // Insert all default roles into database
        for (var role in defaultRoles) {
          final roleData = {
            'id': role.id,
            'name': role.name,
            'description': role.description,
            'department': role.department,
            'permissions': role.permissions.map((e) => e.toString()).join(','),
            'createdAt': role.createdAt.toIso8601String(),
            'lastModifiedAt': role.lastModifiedAt?.toIso8601String(),
            'isActive': role.isActive ? 1 : 0,
          };

          await db.insert(tableRoles, roleData);
          _log.info('Created role: ${role.name}');
        }

        _log.info(
          'Default roles created successfully: ${defaultRoles.length} roles added',
        );
      } else {
        _log.info('Roles already exist in database: $count roles found');
      }
    } catch (e, stackTrace) {
      _log.severe('Error initializing default roles: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> initializeDefaultPayrollData() async {
    try {
      _log.info('Initializing default payroll data...');
      final db = await database;

      // Check if salary components exist
      final componentCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableSalaryComponent'),
      );

      if (componentCount == 0) {
        _log.info('Creating default salary components...');

        // Default allowances
        await db.insert(tableSalaryComponent, {
          'id': const Uuid().v4(),
          'name': 'Housing Allowance',
          'type': ComponentType.allowance.toString(),
          'isTaxable': 1,
          'defaultAmount': 0.0,
          'isPercentage': 0,
          'isActive': 1,
          'createdAt': DateTime.now().toIso8601String(),
        });

        await db.insert(tableSalaryComponent, {
          'id': const Uuid().v4(),
          'name': 'Transport Allowance',
          'type': ComponentType.allowance.toString(),
          'isTaxable': 1,
          'defaultAmount': 0.0,
          'isPercentage': 0,
          'isActive': 1,
          'createdAt': DateTime.now().toIso8601String(),
        });

        await db.insert(tableSalaryComponent, {
          'id': const Uuid().v4(),
          'name': 'Medical Allowance',
          'type': ComponentType.allowance.toString(),
          'isTaxable': 0,
          'defaultAmount': 0.0,
          'isPercentage': 0,
          'isActive': 1,
          'createdAt': DateTime.now().toIso8601String(),
        });

        // Default deductions
        await db.insert(tableSalaryComponent, {
          'id': const Uuid().v4(),
          'name': 'Pension Contribution',
          'type': ComponentType.deduction.toString(),
          'isTaxable': 0,
          'defaultAmount': 5.0,
          'isPercentage': 1,
          'isActive': 1,
          'createdAt': DateTime.now().toIso8601String(),
        });

        await db.insert(tableSalaryComponent, {
          'id': const Uuid().v4(),
          'name': 'Health Insurance',
          'type': ComponentType.deduction.toString(),
          'isTaxable': 0,
          'defaultAmount': 2.0,
          'isPercentage': 1,
          'isActive': 1,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      // Check if tax rules exist
      final taxRuleCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableTaxRule'),
      );

      if (taxRuleCount == 0) {
        _log.info('Creating default tax rules...');

        // Example progressive tax brackets
        await db.insert(tableTaxRule, {
          'id': const Uuid().v4(),
          'name': 'Tax-free allowance',
          'minIncome': 0.0,
          'maxIncome': 12500.0,
          'rate': 0.0,
          'isActive': 1,
          'createdAt': DateTime.now().toIso8601String(),
        });

        await db.insert(tableTaxRule, {
          'id': const Uuid().v4(),
          'name': 'Basic rate',
          'minIncome': 12500.01,
          'maxIncome': 50000.0,
          'rate': 20.0,
          'isActive': 1,
          'createdAt': DateTime.now().toIso8601String(),
        });

        await db.insert(tableTaxRule, {
          'id': const Uuid().v4(),
          'name': 'Higher rate',
          'minIncome': 50000.01,
          'maxIncome': 150000.0,
          'rate': 40.0,
          'isActive': 1,
          'createdAt': DateTime.now().toIso8601String(),
        });

        await db.insert(tableTaxRule, {
          'id': const Uuid().v4(),
          'name': 'Additional rate',
          'minIncome': 150000.01,
          'maxIncome': 1000000000.0, // Virtually unlimited
          'rate': 45.0,
          'isActive': 1,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      _log.info('Default payroll data initialized successfully');
    } catch (e, stackTrace) {
      _log.severe('Error initializing default payroll data: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<bool> checkTables() async {
    try {
      final db = await database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN (?, ?, ?, ?, ?, ?, ?)",
        [
          tableRoles,
          tableEmployees,
          tableAttendance,
          tableLeave,
          tableSalaryComponent,
          tableTaxRule,
          tablePayroll,
        ],
      );
      _log.info('Found tables: ${tables.map((t) => t['name']).join(', ')}');
      return tables.length == 7;
    } catch (e, stackTrace) {
      _log.severe('Error checking tables', e, stackTrace);
      return false;
    }
  }
}
