import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';
import '../services/employee_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  String? _currentEmployeeId;
  Attendance? _todaysAttendance;
  bool _isClockIn = true;

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
      });
      await _checkAttendanceStatus();
    }
  }

  Future<void> _checkAttendanceStatus() async {
    if (_currentEmployeeId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final attendanceService = Provider.of<AttendanceService>(
        context,
        listen: false,
      );
      final attendance = await attendanceService.getTodaysAttendance(
        _currentEmployeeId!,
      );

      if (mounted) {
        setState(() {
          _todaysAttendance = attendance;
          _isClockIn = attendance == null || !attendance.isActive;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleClockInOut() async {
    if (_currentEmployeeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No employee selected')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final attendanceService = Provider.of<AttendanceService>(
        context,
        listen: false,
      );

      if (_isClockIn) {
        // Handle clock in
        await attendanceService.clockIn(
          _currentEmployeeId!,
          notes: _notesController.text,
        );
      } else {
        // Handle clock out
        await attendanceService.clockOut(
          _currentEmployeeId!,
          notes: _notesController.text,
        );
      }

      _notesController.clear();
      await _checkAttendanceStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isClockIn
                  ? 'Successfully clocked out'
                  : 'Successfully clocked in',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.access_time), text: 'Clock In/Out'),
            Tab(icon: Icon(Icons.history), text: 'My History'),
            Tab(icon: Icon(Icons.analytics), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Clock In/Out Tab
          _buildClockInOutTab(),

          // My History Tab
          _buildMyHistoryTab(),

          // Reports Tab
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildClockInOutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Current Status',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                        children: [
                          Icon(
                            _isClockIn ? Icons.login : Icons.logout,
                            size: 60,
                            color: _isClockIn ? Colors.red : Colors.green,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isClockIn ? 'Not Clocked In' : 'Clocked In',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _isClockIn ? Colors.red : Colors.green,
                            ),
                          ),
                          if (_todaysAttendance != null && !_isClockIn) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Since: ${DateFormat('hh:mm a').format(_todaysAttendance!.clockInTime)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (_todaysAttendance!.status ==
                                AttendanceStatus.late)
                              const Text(
                                'Status: Late',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ],
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isClockIn ? 'Clock In' : 'Clock Out',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Add any notes here...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleClockInOut,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor:
                          _isClockIn ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
                              _isClockIn ? 'CLOCK IN' : 'CLOCK OUT',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Time',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      return Text(
                        DateFormat(
                          'EEEE, MMMM d, yyyy\nhh:mm:ss a',
                        ).format(DateTime.now()),
                        style: const TextStyle(fontSize: 18),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyHistoryTab() {
    return Consumer<AttendanceService>(
      builder: (context, attendanceService, child) {
        if (_currentEmployeeId == null) {
          return const Center(child: Text('No employee selected'));
        }

        return FutureBuilder<List<Attendance>>(
          future: attendanceService.getEmployeeAttendance(_currentEmployeeId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final attendances = snapshot.data ?? [];

            if (attendances.isEmpty) {
              return const Center(child: Text('No attendance records found'));
            }

            // Group by date
            final Map<String, List<Attendance>> groupedAttendances = {};
            for (var attendance in attendances) {
              final date = DateFormat(
                'yyyy-MM-dd',
              ).format(attendance.clockInTime);
              groupedAttendances[date] = [
                ...(groupedAttendances[date] ?? []),
                attendance,
              ];
            }

            return ListView.builder(
              itemCount: groupedAttendances.length,
              itemBuilder: (context, index) {
                final date = groupedAttendances.keys.elementAt(index);
                final dateAttendances = groupedAttendances[date]!;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      DateFormat(
                        'EEEE, MMMM d, yyyy',
                      ).format(dateAttendances.first.clockInTime),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _getAttendanceSummary(dateAttendances),
                      style: TextStyle(
                        color: _getStatusColor(dateAttendances.first.status),
                      ),
                    ),
                    children:
                        dateAttendances
                            .map(
                              (attendance) => ListTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Clock In: ${DateFormat('hh:mm a').format(attendance.clockInTime)}',
                                          ),
                                          if (attendance.clockOutTime != null)
                                            Text(
                                              'Clock Out: ${DateFormat('hh:mm a').format(attendance.clockOutTime!)}',
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (attendance.durationInHours != null)
                                      Text(
                                        '${attendance.durationInHours!.toStringAsFixed(2)} hrs',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle:
                                    attendance.notes.isNotEmpty
                                        ? Text('Notes: ${attendance.notes}')
                                        : null,
                              ),
                            )
                            .toList(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _getAttendanceSummary(List<Attendance> attendances) {
    final attendance = attendances.first;
    String summary = '';

    switch (attendance.status) {
      case AttendanceStatus.present:
        summary = 'Present';
        break;
      case AttendanceStatus.late:
        summary = 'Late';
        break;
      case AttendanceStatus.absent:
        summary = 'Absent';
        break;
      case AttendanceStatus.halfDay:
        summary = 'Half Day';
        break;
      case AttendanceStatus.workFromHome:
        summary = 'Work From Home';
        break;
    }

    // Get total hours worked in a day
    double totalHours = 0;
    for (var attendance in attendances) {
      if (attendance.durationInHours != null) {
        totalHours += attendance.durationInHours!;
      }
    }

    if (totalHours > 0) {
      summary += ' • ${totalHours.toStringAsFixed(2)} hours';
    }

    return summary;
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.halfDay:
        return Colors.amber;
      case AttendanceStatus.workFromHome:
        return Colors.blue;
    }
  }

  Widget _buildReportsTab() {
    // For reports, we'll just show a placeholder for now
    // This would be implemented with actual charts and filters
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics, size: 100, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'Attendance Reports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Detailed reporting coming soon!',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // This could navigate to a detailed reports screen
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reports functionality coming soon'),
                  ),
                );
              }
            },
            child: const Text('View Full Reports'),
          ),
        ],
      ),
    );
  }
}
