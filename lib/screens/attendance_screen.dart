import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../models/attendance.dart';
import '../services/attendance_service.dart';
import '../services/employee_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _notesController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _refreshing = false;
  String? _currentEmployeeId;
  Attendance? _todaysAttendance;
  bool _isClockIn =
      true; // true = show clock in button, false = show clock out button
  bool _mounted = true;

  // For the real-time clock
  late Timer _clockTimer;
  String _currentTimeString = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize the current time
    _updateCurrentTime();

    // Set up the timer to update every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCurrentTime();
    });

    // Load employee and attendance status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentEmployee();
    });
  }

  void _updateCurrentTime() {
    if (_mounted) {
      setState(() {
        _currentTimeString = DateFormat(
          'EEEE, MMMM d, yyyy\nhh:mm:ss a',
        ).format(DateTime.now());
      });
    }
  }

  Future<void> _loadCurrentEmployee() async {
    if (!_mounted) return;

    // Cache services before async gap
    final employeeService = Provider.of<EmployeeService>(
      context,
      listen: false,
    );

    try {
      if (employeeService.employees.isEmpty) {
        developer.log('No employees found in EmployeeService');
        return;
      }

      // Get the first employee for demo purposes
      final employeeId = employeeService.employees.first.id;

      if (!_mounted) return;

      setState(() {
        _currentEmployeeId = employeeId;
        developer.log('Current employee ID set to: $_currentEmployeeId');
      });

      // Now check attendance
      await _refreshAttendanceStatus(showLoading: true);
    } catch (e) {
      developer.log('Error loading employee: ${e.toString()}');
      if (_mounted) {
        _showSnackBar('Error loading employee: ${e.toString()}');
      }
    }
  }

  // Helper method to show snackbar and avoid async BuildContext usage
  void _showSnackBar(
    String message, {
    Color? backgroundColor,
    Duration? duration,
  }) {
    if (!_mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _refreshAttendanceStatus({bool showLoading = false}) async {
    if (_currentEmployeeId == null || !_mounted || _refreshing) return;

    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    setState(() {
      _refreshing = true;
    });

    // Cache service before async gap
    final attendanceService = Provider.of<AttendanceService>(
      context,
      listen: false,
    );

    try {
      // Force a 500ms delay to allow database operations to complete
      await Future.delayed(const Duration(milliseconds: 500));

      final attendance = await attendanceService.getTodaysAttendance(
        _currentEmployeeId!,
      );

      developer.log(
        'Retrieved attendance: ${attendance?.toString() ?? "null"}',
      );
      if (attendance != null) {
        developer.log('Attendance isActive: ${attendance.isActive}');
        developer.log('Attendance clockInTime: ${attendance.clockInTime}');
        developer.log('Attendance clockOutTime: ${attendance.clockOutTime}');
      }

      if (!_mounted) return;

      setState(() {
        _todaysAttendance = attendance;

        // Logic for determining clock in/out state:
        // - If no attendance record exists for today -> show clock in
        // - If attendance exists but isActive is false -> show clock in (previous session ended)
        // - If attendance exists and isActive is true -> show clock out (currently clocked in)
        _isClockIn = attendance == null || !attendance.isActive;

        developer.log('Updated _isClockIn to: $_isClockIn');

        _isLoading = false;
        _refreshing = false;
      });
    } catch (e) {
      developer.log('Error checking attendance: ${e.toString()}');
      if (!_mounted) return;

      setState(() {
        _isLoading = false;
        _refreshing = false;
      });

      _showSnackBar('Error checking attendance: ${e.toString()}');
    }
  }

  Future<void> _handleClockInOut() async {
    if (_currentEmployeeId == null) {
      _showSnackBar('No employee selected');
      return;
    }

    if (_refreshing) {
      _showSnackBar('Please wait, refreshing attendance status...');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Store the current action for message display
    final isClockingIn = _isClockIn;
    developer.log(
      'Performing action: ${isClockingIn ? "Clock In" : "Clock Out"}',
    );

    // Cache service before async gap
    final attendanceService = Provider.of<AttendanceService>(
      context,
      listen: false,
    );

    try {
      if (isClockingIn) {
        // Clock In
        final result = await attendanceService.clockIn(
          _currentEmployeeId!,
          notes: _notesController.text,
        );
        developer.log('Clock in result: $result');
      } else {
        // Clock Out
        final result = await attendanceService.clockOut(
          _currentEmployeeId!,
          notes: _notesController.text,
        );
        developer.log('Clock out result: $result');
      }

      // Clear notes
      _notesController.clear();

      // Ensure database has time to update
      await Future.delayed(const Duration(milliseconds: 800));

      // Refresh status
      await _refreshAttendanceStatus();

      if (!_mounted) return;

      _showSnackBar(
        isClockingIn ? 'Successfully clocked in' : 'Successfully clocked out',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      developer.log('Error during clock in/out: ${e.toString()}');
      if (!_mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _manualRefresh() async {
    if (_isLoading || _refreshing) return;

    await _refreshAttendanceStatus(showLoading: true);

    if (!_mounted) return;

    _showSnackBar(
      'Attendance status refreshed',
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _mounted = false;
    _clockTimer.cancel();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshing ? null : _manualRefresh,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Clock In/Out Tab
          _buildClockInOutTab(),

          // My History Tab
          _buildHistoryTab(),

          // Reports Tab
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildClockInOutTab() {
    return RefreshIndicator(
      onRefresh: _manualRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildActionCard(),
            const SizedBox(height: 20),
            _buildTimeCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Status',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_refreshing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
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
                      if (_todaysAttendance!.status == AttendanceStatus.late)
                        const Text(
                          'Status: Late',
                          style: TextStyle(fontSize: 16, color: Colors.orange),
                        ),
                    ],
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _refreshing ? null : _manualRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Status'),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isClockIn ? 'Clock In' : 'Clock Out',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              onPressed: (_isLoading || _refreshing) ? null : _handleClockInOut,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: _isClockIn ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
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
    );
  }

  Widget _buildTimeCard() {
    return Card(
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
            Text(_currentTimeString, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_currentEmployeeId == null) {
      return const Center(child: Text('No employee selected'));
    }

    return RefreshIndicator(
      onRefresh: _manualRefresh,
      child: Consumer<AttendanceService>(
        builder: (context, attendanceService, child) {
          return FutureBuilder<List<Attendance>>(
            future: attendanceService.getEmployeeAttendance(
              _currentEmployeeId!,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                developer.log(
                  'Error loading attendance history: ${snapshot.error}',
                );
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final attendances = snapshot.data ?? [];
              developer.log('Loaded ${attendances.length} attendance records');

              if (attendances.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No attendance records found',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                );
              }

              // Group by date
              final Map<String, List<Attendance>> groupedAttendances = {};
              for (var attendance in attendances) {
                final date = DateFormat(
                  'yyyy-MM-dd',
                ).format(attendance.clockInTime);
                if (!groupedAttendances.containsKey(date)) {
                  groupedAttendances[date] = [];
                }
                groupedAttendances[date]!.add(attendance);
              }

              // Sort dates newest first
              final sortedDates =
                  groupedAttendances.keys.toList()
                    ..sort((a, b) => b.compareTo(a));

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final dateAttendances = groupedAttendances[date]!;

                  return _buildAttendanceCard(date, dateAttendances, index);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAttendanceCard(
    String date,
    List<Attendance> attendances,
    int cardIndex,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: cardIndex == 0, // Expand the most recent day
        title: Text(
          DateFormat(
            'EEEE, MMMM d, yyyy',
          ).format(DateFormat('yyyy-MM-dd').parse(date)),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _getAttendanceSummary(attendances),
          style: TextStyle(color: _getStatusColor(attendances.first.status)),
        ),
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attendances.length,
            itemBuilder: (context, index) {
              final attendance = attendances[index];
              return _buildAttendanceEntry(attendance);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceEntry(Attendance attendance) {
    final bool isComplete = attendance.clockOutTime != null;
    final double? hours = attendance.durationInHours;

    // Get the ID for display (first 8 characters)
    final String displayId =
        attendance.id.length > 8
            ? attendance.id.substring(0, 8)
            : attendance.id;

    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session $displayId',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.login, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'In: ${DateFormat('hh:mm a').format(attendance.clockInTime)}',
              ),
            ],
          ),
          if (isComplete)
            Row(
              children: [
                const Icon(Icons.logout, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Out: ${DateFormat('hh:mm a').format(attendance.clockOutTime!)}',
                ),
              ],
            ),
          Row(
            children: [
              Icon(
                attendance.isActive ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: attendance.isActive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                'Status: ${attendance.isActive ? 'Active' : 'Completed'}',
                style: TextStyle(
                  color: attendance.isActive ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (hours != null)
            Text(
              'Duration: ${hours.toStringAsFixed(2)} hours',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (attendance.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Notes: ${attendance.notes}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
      trailing: Text(
        attendance.status.name.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(attendance.status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getAttendanceSummary(List<Attendance> attendances) {
    int totalSessions = attendances.length;

    // Calculate total hours worked
    double totalHours = 0;
    for (var attendance in attendances) {
      if (attendance.durationInHours != null) {
        totalHours += attendance.durationInHours!;
      }
    }

    // Check if any session is active
    bool hasActiveSession = attendances.any((a) => a.isActive);

    String summary =
        '$totalSessions ${totalSessions == 1 ? 'session' : 'sessions'}';

    if (totalHours > 0) {
      summary += ' • ${totalHours.toStringAsFixed(2)} hours';
    }

    if (hasActiveSession) {
      summary += ' • Currently Active';
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
              if (_mounted) {
                _showSnackBar('Reports functionality coming soon');
              }
            },
            child: const Text('View Full Reports'),
          ),
        ],
      ),
    );
  }
}
