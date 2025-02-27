import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/leave.dart';
import '../services/leave_service.dart';
import '../services/employee_service.dart';
import 'apply_leave_screen.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentEmployeeId;
  bool _isAdmin = false; // This would be determined by user role

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // For demo purposes, we'll assume the first employee is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentEmployee();
    });
  }

  Future<void> _loadCurrentEmployee() async {
    final employeeService = Provider.of<EmployeeService>(
      context,
      listen: false,
    );
    if (employeeService.employees.isNotEmpty) {
      setState(() {
        _currentEmployeeId = employeeService.employees.first.id;
        // For demo purposes, assume admin
        _isAdmin = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(icon: Icon(Icons.event_note), text: 'My Leaves'),
            if (_isAdmin)
              const Tab(icon: Icon(Icons.approval), text: 'Approvals'),
            const Tab(icon: Icon(Icons.group), text: 'Team Calendar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // My Leaves Tab
          _buildMyLeavesTab(),

          // Approvals Tab (only for admin/managers)
          if (_isAdmin) _buildApprovalsTab(),

          // Team Calendar Tab
          _buildTeamCalendarTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      ApplyLeaveScreen(employeeId: _currentEmployeeId!),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMyLeavesTab() {
    if (_currentEmployeeId == null) {
      return const Center(child: Text('No employee selected'));
    }

    return Consumer<LeaveService>(
      builder: (context, leaveService, child) {
        return FutureBuilder<List<Leave>>(
          future: leaveService.getEmployeeLeaves(_currentEmployeeId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final leaves = snapshot.data ?? [];

            if (leaves.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No leave applications found',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Apply for leave using the + button',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: leaves.length,
              itemBuilder: (context, index) {
                final leave = leaves[index];
                return _buildLeaveCard(context, leave, leaveService);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLeaveCard(
    BuildContext context,
    Leave leave,
    LeaveService leaveService,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(_getLeaveTypeText(leave.type)),
                  backgroundColor: _getLeaveTypeColor(leave.type),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                Chip(
                  label: Text(_getLeaveStatusText(leave.status)),
                  backgroundColor: _getLeaveStatusColor(leave.status),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${DateFormat('MMM d, yyyy').format(leave.startDate)} - ${DateFormat('MMM d, yyyy').format(leave.endDate)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${leave.durationInDays} ${leave.durationInDays > 1 ? 'Days' : 'Day'}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reason:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(leave.reason),
            const SizedBox(height: 16),
            if (leave.status == LeaveStatus.pending)
              Builder(
                builder: (innerContext) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          // Cancel leave application
                          try {
                            await leaveService.cancelLeave(leave.id);
                            if (innerContext.mounted) {
                              ScaffoldMessenger.of(innerContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Leave application cancelled'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (innerContext.mounted) {
                              ScaffoldMessenger.of(innerContext).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Cancel Application'),
                      ),
                    ],
                  );
                },
              ),
            if (leave.status == LeaveStatus.rejected &&
                leave.rejectionReason != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reason for Rejection:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(leave.rejectionReason!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalsTab() {
    return Consumer<LeaveService>(
      builder: (context, leaveService, child) {
        return FutureBuilder<List<Leave>>(
          future: leaveService.getPendingLeaves(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final pendingLeaves = snapshot.data ?? [];

            if (pendingLeaves.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No pending leave applications',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: pendingLeaves.length,
              itemBuilder: (context, index) {
                final leave = pendingLeaves[index];
                return _buildApprovalCard(context, leave, leaveService);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildApprovalCard(
    BuildContext parentContext,
    Leave leave,
    LeaveService leaveService,
  ) {
    final TextEditingController reasonController = TextEditingController();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              leave.employeeName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(_getLeaveTypeText(leave.type)),
                  backgroundColor: _getLeaveTypeColor(leave.type),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  '${leave.durationInDays} ${leave.durationInDays > 1 ? 'Days' : 'Day'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'From: ${DateFormat('MMM d, yyyy').format(leave.startDate)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'To: ${DateFormat('MMM d, yyyy').format(leave.endDate)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reason:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(leave.reason),
            const SizedBox(height: 16),
            const Text(
              'Applied on:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              DateFormat('MMM d, yyyy hh:mm a').format(leave.createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (innerContext) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: innerContext,
                          builder:
                              (dialogContext) => AlertDialog(
                                title: const Text('Reject Leave'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Please provide a reason for rejection:',
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: reasonController,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter rejection reason',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 3,
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      if (reasonController.text.isEmpty) {
                                        ScaffoldMessenger.of(
                                          dialogContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please provide a reason for rejection',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      try {
                                        await leaveService.updateLeaveStatus(
                                          leaveId: leave.id,
                                          newStatus: LeaveStatus.rejected,
                                          rejectionReason:
                                              reasonController.text,
                                          approvedById: _currentEmployeeId,
                                        );

                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext);
                                        }

                                        if (innerContext.mounted) {
                                          ScaffoldMessenger.of(
                                            innerContext,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Leave rejected'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext);
                                        }

                                        if (innerContext.mounted) {
                                          ScaffoldMessenger.of(
                                            innerContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error: ${e.toString()}',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Reject',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await leaveService.updateLeaveStatus(
                            leaveId: leave.id,
                            newStatus: LeaveStatus.approved,
                            approvedById: _currentEmployeeId,
                          );

                          if (innerContext.mounted) {
                            ScaffoldMessenger.of(innerContext).showSnackBar(
                              const SnackBar(
                                content: Text('Leave approved'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (innerContext.mounted) {
                            ScaffoldMessenger.of(innerContext).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCalendarTab() {
    // This would be a calendar view showing all approved leaves
    // For now, we'll display a simple list
    return Consumer<LeaveService>(
      builder: (context, leaveService, child) {
        return FutureBuilder<List<Leave>>(
          future: leaveService.getCurrentLeaves(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final currentLeaves = snapshot.data ?? [];

            if (currentLeaves.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 80, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'No team members currently on leave',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: currentLeaves.length,
              itemBuilder: (context, index) {
                final leave = currentLeaves[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getLeaveTypeColor(leave.type),
                    child: Text(
                      leave.employeeName
                          .split(' ')
                          .map((name) => name[0])
                          .join(''),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(leave.employeeName),
                  subtitle: Text(
                    '${_getLeaveTypeText(leave.type)} • ${DateFormat('MMM d').format(leave.startDate)} - ${DateFormat('MMM d').format(leave.endDate)} (${leave.durationInDays} days)',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _getLeaveTypeText(LeaveType type) {
    switch (type) {
      case LeaveType.casual:
        return 'Casual';
      case LeaveType.sick:
        return 'Sick';
      case LeaveType.annual:
        return 'Annual';
      case LeaveType.maternity:
        return 'Maternity';
      case LeaveType.paternity:
        return 'Paternity';
      case LeaveType.unpaid:
        return 'Unpaid';
      case LeaveType.compensatory:
        return 'Compensatory';
      case LeaveType.bereavement:
        return 'Bereavement';
      case LeaveType.studyLeave:
        return 'Study';
      case LeaveType.other:
        return 'Other';
    }
  }

  Color _getLeaveTypeColor(LeaveType type) {
    switch (type) {
      case LeaveType.casual:
        return Colors.blue;
      case LeaveType.sick:
        return Colors.red;
      case LeaveType.annual:
        return Colors.green;
      case LeaveType.maternity:
        return Colors.purple;
      case LeaveType.paternity:
        return Colors.indigo;
      case LeaveType.unpaid:
        return Colors.grey;
      case LeaveType.compensatory:
        return Colors.orange;
      case LeaveType.bereavement:
        return Colors.brown;
      case LeaveType.studyLeave:
        return Colors.teal;
      case LeaveType.other:
        return Colors.blueGrey;
    }
  }

  String _getLeaveStatusText(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getLeaveStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return Colors.amber;
      case LeaveStatus.approved:
        return Colors.green;
      case LeaveStatus.rejected:
        return Colors.red;
      case LeaveStatus.cancelled:
        return Colors.grey;
    }
  }
}
