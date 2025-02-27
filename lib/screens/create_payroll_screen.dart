// create_payroll_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/payroll_service.dart';
import '../services/employee_service.dart';
import '../services/salary_component_service.dart';

class CreatePayrollScreen extends StatefulWidget {
  const CreatePayrollScreen({super.key});

  @override
  State<CreatePayrollScreen> createState() => _CreatePayrollScreenState();
}

class _CreatePayrollScreenState extends State<CreatePayrollScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  DateTime _payPeriodStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _payPeriodEnd = DateTime.now();
  final _basicSalaryController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  // Dynamic allowances and deductions
  final Map<String, TextEditingController> _allowanceControllers = {};
  final Map<String, TextEditingController> _deductionControllers = {};

  @override
  void initState() {
    super.initState();
    _loadSalaryComponents();
  }

  Future<void> _loadSalaryComponents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final salaryComponentService = Provider.of<SalaryComponentService>(
        context,
        listen: false,
      );
      await salaryComponentService.loadComponents();

      // Initialize controllers for allowances
      final allowances = await salaryComponentService.getAllowances();
      for (var allowance in allowances) {
        if (allowance.isActive) {
          double value = allowance.defaultAmount;
          _allowanceControllers[allowance.name] = TextEditingController(
            text: value.toString(),
          );
        }
      }

      // Initialize controllers for deductions
      final deductions = await salaryComponentService.getDeductions();
      for (var deduction in deductions) {
        if (deduction.isActive) {
          double value = deduction.defaultAmount;
          _deductionControllers[deduction.name] = TextEditingController(
            text: value.toString(),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectPayPeriodStart() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _payPeriodStart,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _payPeriodStart && mounted) {
      setState(() {
        _payPeriodStart = picked;
        // If end date is before new start date, update end date
        if (_payPeriodEnd.isBefore(_payPeriodStart)) {
          _payPeriodEnd = _payPeriodStart;
        }
      });
    }
  }

  Future<void> _selectPayPeriodEnd() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _payPeriodEnd,
      firstDate: _payPeriodStart,
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _payPeriodEnd && mounted) {
      setState(() {
        _payPeriodEnd = picked;
      });
    }
  }

  Future<void> _generatePayroll() async {
    if (!_formKey.currentState!.validate() || _selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final payrollService = Provider.of<PayrollService>(
        context,
        listen: false,
      );

      // Parse basic salary
      final basicSalary = double.parse(_basicSalaryController.text);

      // Parse allowances
      final Map<String, double> allowances = {};
      _allowanceControllers.forEach((name, controller) {
        final amount = double.tryParse(controller.text) ?? 0.0;
        if (amount > 0) {
          allowances[name] = amount;
        }
      });

      // Parse deductions
      final Map<String, double> deductions = {};
      _deductionControllers.forEach((name, controller) {
        final amount = double.tryParse(controller.text) ?? 0.0;
        if (amount > 0) {
          deductions[name] = amount;
        }
      });

      // Generate payroll
      await payrollService.generatePayroll(
        employeeId: _selectedEmployeeId!,
        payPeriodStart: _payPeriodStart,
        payPeriodEnd: _payPeriodEnd,
        basicSalary: basicSalary,
        customAllowances: allowances,
        customDeductions: deductions,
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payroll generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _basicSalaryController.dispose();
    _notesController.dispose();
    _allowanceControllers.forEach((_, controller) => controller.dispose());
    _deductionControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Payroll')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Employee Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildEmployeeDropdown(),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _basicSalaryController,
                                decoration: const InputDecoration(
                                  labelText: 'Basic Salary',
                                  prefixText: '\$ ',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter basic salary';
                                  }
                                  final salary = double.tryParse(value);
                                  if (salary == null || salary <= 0) {
                                    return 'Please enter a valid salary amount';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pay Period',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: _selectPayPeriodStart,
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'Start Date',
                                          border: OutlineInputBorder(),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat(
                                                'MMM d, yyyy',
                                              ).format(_payPeriodStart),
                                            ),
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: InkWell(
                                      onTap: _selectPayPeriodEnd,
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'End Date',
                                          border: OutlineInputBorder(),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat(
                                                'MMM d, yyyy',
                                              ).format(_payPeriodEnd),
                                            ),
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_allowanceControllers.isNotEmpty)
                        _buildComponentsCard(
                          'Allowances',
                          Colors.green,
                          _allowanceControllers,
                        ),
                      const SizedBox(height: 16),
                      if (_deductionControllers.isNotEmpty)
                        _buildComponentsCard(
                          'Deductions',
                          Colors.red,
                          _deductionControllers,
                        ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Add any notes about this payroll...',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _generatePayroll,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Generate Payroll',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildEmployeeDropdown() {
    return Consumer<EmployeeService>(
      builder: (context, employeeService, child) {
        final employees = employeeService.employees;

        return DropdownButtonFormField<String>(
          value: _selectedEmployeeId,
          decoration: const InputDecoration(
            labelText: 'Select Employee',
            border: OutlineInputBorder(),
          ),
          items:
              employees.map((employee) {
                return DropdownMenuItem<String>(
                  value: employee.id,
                  child: Text('${employee.firstname} ${employee.lastname}'),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedEmployeeId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select an employee';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildComponentsCard(
    String title,
    Color color,
    Map<String, TextEditingController> controllers,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...controllers.entries.map(
              (entry) => _buildComponentField(entry.key, entry.value, color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentField(
    String name,
    TextEditingController controller,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: name,
          prefixText: '\$ ',
          border: const OutlineInputBorder(),
          labelStyle: TextStyle(color: color),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return null; // Optional field
          }
          final amount = double.tryParse(value);
          if (amount == null || amount < 0) {
            return 'Please enter a valid amount';
          }
          return null;
        },
      ),
    );
  }
}
