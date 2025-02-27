import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'screens/employee_directory.dart';
import 'screens/add_employee.dart';
import 'screens/edit_employee.dart';
import 'screens/attendance_screen.dart';
import 'screens/leave_screen.dart';
import 'screens/attendance_reports_screen.dart';
import 'services/employee_service.dart';
import 'services/role_service.dart';
import 'services/attendance_service.dart';
import 'services/leave_service.dart';
import 'services/database_helper.dart';
import 'models/employee.dart';

final _log = Logger('Main');

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint(
        '${record.level.name}: ${record.time}: ${record.message}\n'
        '${record.error ?? ''}\n'
        '${record.stackTrace ?? ''}',
      );
    });

    _log.info('Initializing application...');

    // Initialize database and services
    final dbHelper = DatabaseHelper.instance;
    final employeeService = EmployeeService();
    final roleService = RoleService();

    // Initialize new services
    final attendanceService = AttendanceService(employeeService);
    final leaveService = LeaveService(employeeService);

    // Ensure database is ready and roles are initialized
    await dbHelper.database;
    await dbHelper.initializeDefaultRoles();

    // Initialize services
    _log.info('Initializing services...');
    await Future.wait([
      employeeService.init(),
      roleService.init(),
      attendanceService.init(),
      leaveService.init(),
    ]);

    // Verify roles
    final roles = roleService.roles;
    _log.info('Loaded ${roles.length} roles');
    if (roles.isEmpty) {
      _log.warning('No roles loaded - this might cause UI issues');
    }

    runApp(
      MyApp(
        employeeService: employeeService,
        roleService: roleService,
        attendanceService: attendanceService,
        leaveService: leaveService,
      ),
    );
  } catch (e, stackTrace) {
    _log.severe('Error initializing app: $e\n$stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error initializing app: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final EmployeeService employeeService;
  final RoleService roleService;
  final AttendanceService attendanceService;
  final LeaveService leaveService;

  const MyApp({
    super.key,
    required this.employeeService,
    required this.roleService,
    required this.attendanceService,
    required this.leaveService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: employeeService),
        ChangeNotifierProvider.value(value: roleService),
        ChangeNotifierProvider.value(value: attendanceService),
        ChangeNotifierProvider.value(value: leaveService),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Medical HRM',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        home: const HomePage(),
        routes: {
          '/add-employee': (context) => const AddEmployee(),
          '/edit-employee': (context) {
            final employee =
                ModalRoute.of(context)?.settings.arguments as Employee?;
            if (employee == null) {
              _log.warning('No employee provided for editing');
              return const EmployeeDirectory();
            }
            return EditEmployee(employee: employee);
          },
          '/attendance': (context) => const AttendanceScreen(),
          '/leave': (context) => const LeaveScreen(),
          '/reports': (context) => const AttendanceReportsScreen(),
        },
        onGenerateRoute: (settings) {
          _log.warning('Route not found: ${settings.name}');
          return MaterialPageRoute(builder: (context) => const HomePage());
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const EmployeeDirectory(),
    const AttendanceScreen(),
    const LeaveScreen(),
    const AttendanceReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Employees'),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Leaves'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
