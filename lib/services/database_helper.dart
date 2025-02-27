import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import '../services/role_service.dart';

class DatabaseHelper {
  static final _log = Logger('DatabaseHelper');
  static const String _databaseName = "hrm_database.db";
  static const int _databaseVersion =
      3; // Incremented version number for new tables

  static const String tableRoles = 'roles';
  static const String tableEmployees = 'employees';
  static const String tableAttendance = 'attendance';
  static const String tableLeave = 'leave';

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

  Future<bool> checkTables() async {
    try {
      final db = await database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN (?, ?, ?, ?)",
        [tableRoles, tableEmployees, tableAttendance, tableLeave],
      );
      _log.info('Found tables: ${tables.map((t) => t['name']).join(', ')}');
      return tables.length == 4;
    } catch (e, stackTrace) {
      _log.severe('Error checking tables', e, stackTrace);
      return false;
    }
  }
}
