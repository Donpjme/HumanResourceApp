import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'services/database_helper.dart';
import 'services/role_service.dart';
import 'services/employee_service.dart';
import 'services/attendance_service.dart';
import 'services/leave_service.dart';
import 'services/payroll_service.dart';
import 'services/tax_service.dart';
import 'services/salary_component_service.dart';
import 'screens/home_screen.dart';
import 'screens/employee_directory.dart';
import 'screens/add_employee.dart';
import 'screens/edit_employee.dart';
import 'screens/attendance_screen.dart';
import 'screens/attendance_reports_screen.dart';
import 'screens/leave_screen.dart';
import 'screens/apply_leave_screen.dart';
import 'screens/payroll_screen.dart';
import 'screens/tax_management_screen.dart';
import 'screens/salary_component_screen.dart';
import 'models/employee.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialize services
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.checkTables();
  await dbHelper.initializeDefaultRoles();
  await dbHelper.initializeDefaultPayrollData();

  // Initialize services
  final roleService = RoleService();
  await roleService.init();

  final employeeService = EmployeeService();
  await employeeService.init();

  final attendanceService = AttendanceService(employeeService);
  await attendanceService.init();

  final leaveService = LeaveService(employeeService);
  await leaveService.init();

  final taxService = TaxService();
  await taxService.init();

  final salaryComponentService = SalaryComponentService();
  await salaryComponentService.init();

  final payrollService = PayrollService(
    employeeService,
    attendanceService,
    salaryComponentService,
    taxService,
  );
  await payrollService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => roleService),
        ChangeNotifierProvider(create: (context) => employeeService),
        ChangeNotifierProvider(create: (context) => attendanceService),
        ChangeNotifierProvider(create: (context) => leaveService),
        ChangeNotifierProvider(create: (context) => taxService),
        ChangeNotifierProvider(create: (context) => salaryComponentService),
        ChangeNotifierProxyProvider4<
          EmployeeService,
          AttendanceService,
          SalaryComponentService,
          TaxService,
          PayrollService
        >(
          create:
              (context) => PayrollService(
                Provider.of<EmployeeService>(context, listen: false),
                Provider.of<AttendanceService>(context, listen: false),
                Provider.of<SalaryComponentService>(context, listen: false),
                Provider.of<TaxService>(context, listen: false),
              ),
          update:
              (
                context,
                employeeService,
                attendanceService,
                salaryComponentService,
                taxService,
                previous,
              ) => PayrollService(
                employeeService,
                attendanceService,
                salaryComponentService,
                taxService,
              ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // Add optional parameters for each service
  final EmployeeService? employeeService;
  final RoleService? roleService;
  final AttendanceService? attendanceService;
  final LeaveService? leaveService;
  final PayrollService? payrollService;
  final TaxService? taxService;
  final SalaryComponentService? salaryComponentService;

  // Modify the constructor to accept these services
  const MyApp({
    super.key,
    this.employeeService,
    this.roleService,
    this.attendanceService,
    this.leaveService,
    this.payrollService,
    this.taxService,
    this.salaryComponentService,
  });

  @override
  Widget build(BuildContext context) {
    // If services are provided (during testing), use MultiProvider to override the existing providers
    if (employeeService != null ||
        roleService != null ||
        attendanceService != null ||
        leaveService != null ||
        payrollService != null ||
        taxService != null ||
        salaryComponentService != null) {
      return MultiProvider(
        providers: [
          if (roleService != null)
            ChangeNotifierProvider<RoleService>.value(value: roleService!),
          if (employeeService != null)
            ChangeNotifierProvider<EmployeeService>.value(
              value: employeeService!,
            ),
          if (attendanceService != null)
            ChangeNotifierProvider<AttendanceService>.value(
              value: attendanceService!,
            ),
          if (leaveService != null)
            ChangeNotifierProvider<LeaveService>.value(value: leaveService!),
          if (taxService != null)
            ChangeNotifierProvider<TaxService>.value(value: taxService!),
          if (salaryComponentService != null)
            ChangeNotifierProvider<SalaryComponentService>.value(
              value: salaryComponentService!,
            ),
          if (payrollService != null)
            ChangeNotifierProvider<PayrollService>.value(
              value: payrollService!,
            ),
        ],
        child: _buildMaterialApp(),
      );
    }

    // For normal app usage, no need to wrap in additional providers
    return _buildMaterialApp();
  }

  // Extract the MaterialApp into a separate method to avoid code duplication
  MaterialApp _buildMaterialApp() {
    return MaterialApp(
      title: 'HRM App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        '/employee-directory': (context) => const EmployeeDirectory(),
        '/add-employee': (context) => const AddEmployee(),
        '/attendance': (context) => const AttendanceScreen(),
        '/attendance-reports': (context) => const AttendanceReportsScreen(),
        '/leave': (context) => const LeaveScreen(),
        '/payroll': (context) => const PayrollScreen(),
        '/tax-management': (context) => const TaxManagementScreen(),
        '/salary-components': (context) => const SalaryComponentScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/edit-employee':
            // Cast the arguments to Employee type
            final employee = settings.arguments as Employee;
            return MaterialPageRoute(
              builder: (context) => EditEmployee(employee: employee),
            );
          case '/apply-leave':
            final employeeId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ApplyLeaveScreen(employeeId: employeeId),
            );
          default:
            return null;
        }
      },
    );
  }
}
