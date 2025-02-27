import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/payroll.dart';
import '../models/employee.dart';
import '../services/payroll_service.dart';
import '../services/employee_service.dart';
import 'create_payroll_screen.dart';
import 'payroll_details_screen.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final bool _isAdmin = true; // This would be determined by user role
  bool _isLoading = false;
  DateTime _selectedMonth = DateTime.now();
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPayrolls();
  }

  @override
  void dispose() {
    _mounted = false;
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadPayrolls() async {
    if (!_mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Store the service in a local variable before the async gap
      final payrollService = Provider.of<PayrollService>(
        context,
        listen: false,
      );
      await payrollService.loadPayrolls();
    } catch (e) {
      if (_mounted) {
        // Create a local variable to hold the context
        // ignore: use_build_context_synchronously
        final scaffoldContext = ScaffoldMessenger.of(context);
        scaffoldContext.showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectMonth() async {
    // Store the context in a local variable before the async gap
    final currentContext = context;
    final DateTime? picked = await showDatePicker(
      context: currentContext,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null && _mounted) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'All Payrolls'),
            Tab(icon: Icon(Icons.approval), text: 'Approvals'),
            Tab(icon: Icon(Icons.history), text: 'Payment History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _selectMonth,
            tooltip: 'Filter by month',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildAllPayrollsTab(),
                  _buildApprovalsTab(),
                  _buildPaymentHistoryTab(),
                ],
              ),
      floatingActionButton:
          _isAdmin
              ? FloatingActionButton(
                onPressed: () {
                  final currentContext =
                      context; // Store context before async gap
                  Navigator.push(
                    currentContext,
                    MaterialPageRoute(
                      builder: (context) => const CreatePayrollScreen(),
                    ),
                  ).then((_) {
                    if (_mounted) {
                      _loadPayrolls();
                    }
                  });
                },
                tooltip: 'Generate Payroll',
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildAllPayrollsTab() {
    // First day of the selected month
    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    // Last day of the selected month
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    return Consumer<PayrollService>(
      builder: (context, payrollService, child) {
        return FutureBuilder<List<Payroll>>(
          future: payrollService.getPayrollsByPeriod(startDate, endDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final payrolls = snapshot.data ?? [];

            if (payrolls.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.money_off, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No payrolls found for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    if (_isAdmin)
                      ElevatedButton.icon(
                        onPressed: () {
                          final currentContext =
                              context; // Store context before async gap
                          Navigator.push(
                            currentContext,
                            MaterialPageRoute(
                              builder: (context) => const CreatePayrollScreen(),
                            ),
                          ).then((_) {
                            if (_mounted) {
                              _loadPayrolls();
                            }
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Generate Payroll'),
                      ),
                  ],
                ),
              );
            }

            return Consumer<EmployeeService>(
              builder: (context, employeeService, child) {
                return ListView.builder(
                  itemCount: payrolls.length,
                  itemBuilder: (context, index) {
                    final payroll = payrolls[index];

                    // Get employee name for display
                    String employeeName = 'Unknown Employee';
                    final employee = employeeService.employees.firstWhere(
                      (e) => e.id == payroll.employeeId,
                      orElse:
                          () => Employee(
                            employeeId: '',
                            firstname: 'Unknown',
                            lastname: 'Employee',
                            email: '',
                            phone: '',
                            position: '',
                            roleId: '',
                            joiningDate: DateTime.now(),
                          ),
                    );
                    employeeName = '${employee.firstname} ${employee.lastname}';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(payroll.status),
                          child: Icon(
                            _getStatusIcon(payroll.status),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          employeeName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Period: ${DateFormat('MMM d').format(payroll.payPeriodStart)} - ${DateFormat('MMM d, yyyy').format(payroll.payPeriodEnd)}',
                            ),
                            Text(
                              'Status: ${_getStatusText(payroll.status)}',
                              style: TextStyle(
                                color: _getStatusColor(payroll.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '\$${payroll.netSalary.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          final currentContext =
                              context; // Store context before async gap
                          Navigator.push(
                            currentContext,
                            MaterialPageRoute(
                              builder:
                                  (context) => PayrollDetailsScreen(
                                    payrollId: payroll.id,
                                    employeeName: employeeName,
                                  ),
                            ),
                          ).then((_) {
                            if (_mounted) {
                              _loadPayrolls();
                            }
                          });
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildApprovalsTab() {
    return Consumer<PayrollService>(
      builder: (context, payrollService, child) {
        return FutureBuilder<List<Payroll>>(
          future: payrollService.getPayrollsByStatus(PayrollStatus.draft),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final pendingPayrolls = snapshot.data ?? [];

            if (pendingPayrolls.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No payrolls pending approval',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            return Consumer<EmployeeService>(
              builder: (context, employeeService, child) {
                return ListView.builder(
                  itemCount: pendingPayrolls.length,
                  itemBuilder: (context, index) {
                    final payroll = pendingPayrolls[index];

                    // Get employee name for display
                    String employeeName = 'Unknown Employee';
                    final employee = employeeService.employees.firstWhere(
                      (e) => e.id == payroll.employeeId,
                      orElse:
                          () => Employee(
                            employeeId: '',
                            firstname: 'Unknown',
                            lastname: 'Employee',
                            email: '',
                            phone: '',
                            position: '',
                            roleId: '',
                            joiningDate: DateTime.now(),
                          ),
                    );
                    employeeName = '${employee.firstname} ${employee.lastname}';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Icon(Icons.pending, color: Colors.white),
                            ),
                            title: Text(
                              employeeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Period: ${DateFormat('MMM d').format(payroll.payPeriodStart)} - ${DateFormat('MMM d, yyyy').format(payroll.payPeriodEnd)}',
                                ),
                                Text(
                                  'Net Salary: \$${payroll.netSalary.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () {
                                final currentContext =
                                    context; // Store context before async gap
                                Navigator.push(
                                  currentContext,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PayrollDetailsScreen(
                                          payrollId: payroll.id,
                                          employeeName: employeeName,
                                        ),
                                  ),
                                ).then((_) {
                                  if (_mounted) {
                                    _loadPayrolls();
                                  }
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    // Store the service and scaffold before the async gap
                                    final service = payrollService;
                                    final scaffoldContext =
                                        ScaffoldMessenger.of(context);

                                    try {
                                      await service.updatePayrollStatus(
                                        payrollId: payroll.id,
                                        newStatus: PayrollStatus.cancelled,
                                      );

                                      if (_mounted) {
                                        scaffoldContext.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Payroll cancelled successfully',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        // Reload payrolls only if still mounted
                                        _loadPayrolls();
                                      }
                                    } catch (e) {
                                      if (_mounted) {
                                        scaffoldContext.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error: ${e.toString()}',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    // Store the service and scaffold before the async gap
                                    final service = payrollService;
                                    final scaffoldContext =
                                        ScaffoldMessenger.of(context);

                                    try {
                                      await service.updatePayrollStatus(
                                        payrollId: payroll.id,
                                        newStatus: PayrollStatus.approved,
                                        approvedById:
                                            'current-user-id', // Replace with actual user ID
                                      );

                                      if (_mounted) {
                                        scaffoldContext.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Payroll approved successfully',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        // Reload payrolls only if still mounted
                                        _loadPayrolls();
                                      }
                                    } catch (e) {
                                      if (_mounted) {
                                        scaffoldContext.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error: ${e.toString()}',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Approve'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentHistoryTab() {
    return Consumer<PayrollService>(
      builder: (context, payrollService, child) {
        return FutureBuilder<List<Payroll>>(
          future: payrollService.getPayrollsByStatus(PayrollStatus.paid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final paidPayrolls = snapshot.data ?? [];

            if (paidPayrolls.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 80, color: Colors.blue[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No payment history found',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            return Consumer<EmployeeService>(
              builder: (context, employeeService, child) {
                return ListView.builder(
                  itemCount: paidPayrolls.length,
                  itemBuilder: (context, index) {
                    final payroll = paidPayrolls[index];

                    // Get employee name for display
                    String employeeName = 'Unknown Employee';
                    final employee = employeeService.employees.firstWhere(
                      (e) => e.id == payroll.employeeId,
                      orElse:
                          () => Employee(
                            employeeId: '',
                            firstname: 'Unknown',
                            lastname: 'Employee',
                            email: '',
                            phone: '',
                            position: '',
                            roleId: '',
                            joiningDate: DateTime.now(),
                          ),
                    );
                    employeeName = '${employee.firstname} ${employee.lastname}';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.attach_money, color: Colors.white),
                        ),
                        title: Text(
                          employeeName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Period: ${DateFormat('MMM d').format(payroll.payPeriodStart)} - ${DateFormat('MMM d, yyyy').format(payroll.payPeriodEnd)}',
                            ),
                            if (payroll.paymentDate != null)
                              Text(
                                'Paid on: ${DateFormat('MMM d, yyyy').format(payroll.paymentDate!)}',
                              ),
                            if (payroll.paymentReference != null)
                              Text(
                                'Ref: ${payroll.paymentReference}',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          '\$${payroll.netSalary.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () {
                          final currentContext =
                              context; // Store context before async gap
                          Navigator.push(
                            currentContext,
                            MaterialPageRoute(
                              builder:
                                  (context) => PayrollDetailsScreen(
                                    payrollId: payroll.id,
                                    employeeName: employeeName,
                                  ),
                            ),
                          ).then((_) {
                            if (_mounted) {
                              _loadPayrolls();
                            }
                          });
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  String _getStatusText(PayrollStatus status) {
    switch (status) {
      case PayrollStatus.draft:
        return 'Draft';
      case PayrollStatus.approved:
        return 'Approved';
      case PayrollStatus.paid:
        return 'Paid';
      case PayrollStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(PayrollStatus status) {
    switch (status) {
      case PayrollStatus.draft:
        return Colors.orange;
      case PayrollStatus.approved:
        return Colors.blue;
      case PayrollStatus.paid:
        return Colors.green;
      case PayrollStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(PayrollStatus status) {
    switch (status) {
      case PayrollStatus.draft:
        return Icons.pending;
      case PayrollStatus.approved:
        return Icons.check_circle;
      case PayrollStatus.paid:
        return Icons.attach_money;
      case PayrollStatus.cancelled:
        return Icons.cancel;
    }
  }
}
