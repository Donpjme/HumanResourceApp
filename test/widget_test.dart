import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrm_app/models/employee.dart';
import 'package:hrm_app/models/role.dart';
import 'package:hrm_app/models/attendance.dart';
import 'package:hrm_app/models/leave.dart';
import 'package:hrm_app/services/employee_service.dart';
import 'package:hrm_app/services/role_service.dart';
import 'package:hrm_app/services/attendance_service.dart';
import 'package:hrm_app/services/leave_service.dart';
import 'package:hrm_app/services/payroll_service.dart';
import 'package:hrm_app/services/tax_service.dart';
import 'package:hrm_app/services/salary_component_service.dart';
import 'package:hrm_app/main.dart';

class MockEmployeeService extends EmployeeService {
  final List<Employee> _mockEmployees = [];

  @override
  List<Employee> get employees => _mockEmployees;

  @override
  Future<void> init() async {
    // Mock initialization
  }

  @override
  Future<void> loadEmployees() async {
    notifyListeners();
  }

  @override
  Future<void> addEmployee(Employee employee) async {
    _mockEmployees.add(employee);
    notifyListeners();
  }

  @override
  Future<void> deleteEmployee(String id) async {
    _mockEmployees.removeWhere((employee) => employee.id == id);
    notifyListeners();
  }

  @override
  Future<Employee?> getEmployee(String id) async {
    try {
      return _mockEmployees.firstWhere((employee) => employee.id == id);
    } catch (e) {
      return null;
    }
  }
}

class MockRoleService extends RoleService {
  final List<Role> _mockRoles = [];

  @override
  List<Role> get roles => _mockRoles;

  @override
  Future<void> init() async {
    // Mock initialization
  }

  @override
  Future<void> loadRoles() async {
    _mockRoles.addAll(getDefaultRoles());
    notifyListeners();
  }
}

class MockAttendanceService extends AttendanceService {
  final List<Attendance> _mockAttendances = [];

  // Using super parameter for employeeService
  MockAttendanceService(super.employeeService);

  @override
  List<Attendance> get attendances => _mockAttendances;

  @override
  Future<void> init() async {
    // Mock initialization
  }

  @override
  Future<void> loadAttendances() async {
    notifyListeners();
  }

  @override
  Future<Attendance?> clockIn(String employeeId, {String notes = ''}) async {
    final attendance = Attendance(
      employeeId: employeeId,
      clockInTime: DateTime.now(),
      notes: notes,
    );
    _mockAttendances.add(attendance);
    notifyListeners();
    return attendance;
  }

  @override
  Future<Attendance?> clockOut(String employeeId, {String notes = ''}) async {
    try {
      final index = _mockAttendances.indexWhere(
        (a) => a.employeeId == employeeId && a.isActive,
      );

      if (index == -1) {
        return null;
      }

      final updatedAttendance = Attendance(
        id: _mockAttendances[index].id,
        employeeId: employeeId,
        clockInTime: _mockAttendances[index].clockInTime,
        clockOutTime: DateTime.now(),
        notes: notes.isNotEmpty ? notes : _mockAttendances[index].notes,
        status: _mockAttendances[index].status,
        createdAt: _mockAttendances[index].createdAt,
      );

      _mockAttendances[index] = updatedAttendance;
      notifyListeners();
      return updatedAttendance;
    } catch (e) {
      return null;
    }
  }
}

class MockLeaveService extends LeaveService {
  final List<Leave> _mockLeaves = [];

  // Using super parameter for employeeService
  MockLeaveService(super.employeeService);

  @override
  List<Leave> get leaves => _mockLeaves;

  @override
  Future<void> init() async {
    // Mock initialization
  }

  @override
  Future<void> loadLeaves() async {
    notifyListeners();
  }

  @override
  Future<Leave> applyLeave({
    required String employeeId,
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final leave = Leave(
      employeeId: employeeId,
      employeeName: 'Test Employee',
      type: type,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    );

    _mockLeaves.add(leave);
    notifyListeners();
    return leave;
  }
}

// Add mocks for the new services
class MockTaxService extends TaxService {
  @override
  Future<void> init() async {
    // Mock initialization
  }
}

class MockSalaryComponentService extends SalaryComponentService {
  @override
  Future<void> init() async {
    // Mock initialization
  }
}

class MockPayrollService extends PayrollService {
  // Using super parameters for all injected services
  MockPayrollService(
    super.employeeService,
    super.attendanceService,
    super.salaryComponentService,
    super.taxService,
  );

  @override
  Future<void> init() async {
    // Mock initialization
  }
}

void main() {
  late MockEmployeeService mockEmployeeService;
  late MockRoleService mockRoleService;
  late MockAttendanceService mockAttendanceService;
  late MockLeaveService mockLeaveService;
  late MockTaxService mockTaxService;
  late MockSalaryComponentService mockSalaryComponentService;
  late MockPayrollService mockPayrollService;

  setUp(() {
    mockEmployeeService = MockEmployeeService();
    mockRoleService = MockRoleService();

    // Create mock services using the employee service
    mockAttendanceService = MockAttendanceService(mockEmployeeService);
    mockLeaveService = MockLeaveService(mockEmployeeService);

    // Initialize new mock services
    mockTaxService = MockTaxService();
    mockSalaryComponentService = MockSalaryComponentService();
    mockPayrollService = MockPayrollService(
      mockEmployeeService,
      mockAttendanceService,
      mockSalaryComponentService,
      mockTaxService,
    );

    // Initialize roles for tests
    mockRoleService.loadRoles();
  });

  testWidgets('App initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        employeeService: mockEmployeeService,
        roleService: mockRoleService,
        attendanceService: mockAttendanceService,
        leaveService: mockLeaveService,
        payrollService: mockPayrollService,
        taxService: mockTaxService,
        salaryComponentService: mockSalaryComponentService,
      ),
    );

    // Note: The test expectation may need to be updated depending on your HomeScreen implementation
    // If your HomeScreen doesn't show "Employee Directory" text initially, adjust this expectation
    expect(find.text('HR Management System'), findsOneWidget);
  });

  testWidgets('Add employee button test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        employeeService: mockEmployeeService,
        roleService: mockRoleService,
        attendanceService: mockAttendanceService,
        leaveService: mockLeaveService,
        payrollService: mockPayrollService,
        taxService: mockTaxService,
        salaryComponentService: mockSalaryComponentService,
      ),
    );

    // Note: This test may need to be adjusted based on your HomeScreen implementation
    // If the add button isn't immediately visible, you may need to navigate to the employee directory first

    // Navigate to employee directory
    await tester.tap(
      find.text('Employees'),
    ); // Assuming this is a button on your HomeScreen
    await tester.pumpAndSettle();

    // Find and tap the add employee button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that we're on the add employee screen
    expect(find.text('Add Employee'), findsOneWidget);
  });

  testWidgets('Employee list displays correctly', (WidgetTester tester) async {
    // Add a test employee
    final defaultRole = mockRoleService.getDefaultRoles().first;
    final testEmployee = Employee(
      id: '1',
      employeeId: 'EMP001',
      firstname: 'John',
      lastname: 'Doe',
      email: 'john.doe@example.com',
      phone: '1234567890',
      position: 'Developer',
      roleId: defaultRole.id, // Use roleId instead of role
      joiningDate: DateTime.now(),
    );

    await mockEmployeeService.addEmployee(testEmployee);

    await tester.pumpWidget(
      MyApp(
        employeeService: mockEmployeeService,
        roleService: mockRoleService,
        attendanceService: mockAttendanceService,
        leaveService: mockLeaveService,
        payrollService: mockPayrollService,
        taxService: mockTaxService,
        salaryComponentService: mockSalaryComponentService,
      ),
    );

    // Note: This test may need to be adjusted based on your HomeScreen implementation
    // Navigate to employee directory first
    await tester.tap(
      find.text('Employees'),
    ); // Assuming this is a button on your HomeScreen
    await tester.pumpAndSettle();

    // Verify that the employee is displayed
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Developer'), findsOneWidget);
  });

  testWidgets('Search employee functionality', (WidgetTester tester) async {
    // Add test employees
    final defaultRole = mockRoleService.getDefaultRoles().first;
    final testEmployee1 = Employee(
      id: '1',
      employeeId: 'EMP001',
      firstname: 'John',
      lastname: 'Doe',
      email: 'john.doe@example.com',
      phone: '1234567890',
      position: 'Developer',
      roleId: defaultRole.id, // Use roleId instead of role
      joiningDate: DateTime.now(),
    );

    final testEmployee2 = Employee(
      id: '2',
      employeeId: 'EMP002',
      firstname: 'Jane',
      lastname: 'Smith',
      email: 'jane.smith@example.com',
      phone: '0987654321',
      position: 'Designer',
      roleId: defaultRole.id, // Use roleId instead of role
      joiningDate: DateTime.now(),
    );

    await mockEmployeeService.addEmployee(testEmployee1);
    await mockEmployeeService.addEmployee(testEmployee2);

    await tester.pumpWidget(
      MyApp(
        employeeService: mockEmployeeService,
        roleService: mockRoleService,
        attendanceService: mockAttendanceService,
        leaveService: mockLeaveService,
        payrollService: mockPayrollService,
        taxService: mockTaxService,
        salaryComponentService: mockSalaryComponentService,
      ),
    );

    // Note: This test may need to be adjusted based on your HomeScreen implementation
    // Navigate to employee directory first
    await tester.tap(
      find.text('Employees'),
    ); // Assuming this is a button on your HomeScreen
    await tester.pumpAndSettle();

    // Enter search query
    await tester.enterText(find.byType(TextField), 'John');
    await tester.pump();

    // Verify search results
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Jane Smith'), findsNothing);
  });

  // You can add more tests for the new attendance, leave, and payroll functionality here
}
