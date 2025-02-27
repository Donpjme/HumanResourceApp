import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../models/employee.dart';
import '../services/attendance_service.dart';
import '../services/employee_service.dart';

class AttendanceReportsScreen extends StatefulWidget {
  const AttendanceReportsScreen({super.key});

  @override
  State<AttendanceReportsScreen> createState() =>
      _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends State<AttendanceReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedEmployeeId;
  bool _isLoading = false;
  List<Attendance> _filteredAttendances = [];
  Map<String, double> _hoursWorkedByDay = {};
  Map<AttendanceStatus, int> _statusCounts = {};

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final attendanceService = Provider.of<AttendanceService>(
        context,
        listen: false,
      );
      List<Attendance> attendances;

      if (_selectedEmployeeId != null) {
        // Get attendance for specific employee
        attendances = await attendanceService.getEmployeeAttendance(
          _selectedEmployeeId!,
        );
        // Filter by date range
        _filteredAttendances =
            attendances.where((a) {
              return a.clockInTime.isAfter(
                    _startDate.subtract(const Duration(days: 1)),
                  ) &&
                  a.clockInTime.isBefore(_endDate.add(const Duration(days: 1)));
            }).toList();
      } else {
        // Get attendance for all employees in date range
        _filteredAttendances = await attendanceService
            .getAttendanceForDateRange(_startDate, _endDate);
      }

      // Get status counts
      _statusCounts = await attendanceService.getAttendanceStatusCounts(
        _startDate,
        _endDate,
      );

      // Calculate hours worked by day
      _calculateHoursWorkedByDay();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report data: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateHoursWorkedByDay() {
    Map<String, double> hoursWorkedByDay = {};

    for (var attendance in _filteredAttendances) {
      if (attendance.durationInHours == null) continue;

      final dateString = DateFormat(
        'yyyy-MM-dd',
      ).format(attendance.clockInTime);
      hoursWorkedByDay[dateString] =
          (hoursWorkedByDay[dateString] ?? 0) + attendance.durationInHours!;
    }

    setState(() {
      _hoursWorkedByDay = hoursWorkedByDay;
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _startDate && mounted) {
      setState(() {
        _startDate = picked;
        // If start date is after end date, update end date
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
      });

      _loadReportData();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _endDate && mounted) {
      setState(() {
        _endDate = picked;
      });

      _loadReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Reports')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFiltersCard(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildStatusBreakdownCard(),
                    const SizedBox(height: 16),
                    _buildDailyHoursCard(),
                    const SizedBox(height: 16),
                    _buildAttendanceListCard(),
                  ],
                ),
              ),
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Start Date',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMM d, yyyy').format(_startDate)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'End Date',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMM d, yyyy').format(_endDate)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<EmployeeService>(
              builder: (context, employeeService, child) {
                final employees = employeeService.employees;

                return DropdownButtonFormField<String?>(
                  value: _selectedEmployeeId,
                  decoration: const InputDecoration(
                    labelText: 'Select Employee',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Employees'),
                    ),
                    ...employees.map((employee) {
                      return DropdownMenuItem<String?>(
                        value: employee.id,
                        child: Text(
                          '${employee.firstname} ${employee.lastname}',
                        ),
                      );
                    // ignore: unnecessary_to_list_in_spreads
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedEmployeeId = value;
                    });
                    _loadReportData();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    // Calculate summary data
    int totalDays = _endDate.difference(_startDate).inDays + 1;
    int totalEntries = _filteredAttendances.length;

    double totalHours = 0;
    for (var attendance in _filteredAttendances) {
      if (attendance.durationInHours != null) {
        totalHours += attendance.durationInHours!;
      }
    }

    double averageHoursPerDay = totalHours / (totalDays > 0 ? totalDays : 1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Date Range',
                  '$totalDays days',
                  Icons.date_range,
                ),
                _buildSummaryItem(
                  'Records',
                  '$totalEntries entries',
                  Icons.assignment,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Hours',
                  '${totalHours.toStringAsFixed(2)} hrs',
                  Icons.hourglass_bottom,
                ),
                _buildSummaryItem(
                  'Avg. Daily Hours',
                  '${averageHoursPerDay.toStringAsFixed(2)} hrs',
                  Icons.av_timer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatusBreakdownCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: _buildStatusBar(_statusCounts))]),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children:
                  AttendanceStatus.values.map((status) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_getStatusText(status)}: ${_statusCounts[status] ?? 0}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyHoursCard() {
    if (_hoursWorkedByDay.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No hours data available for the selected period',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Sort entries by date
    final sortedEntries =
        _hoursWorkedByDay.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hours Worked by Day',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.only(top: 16, right: 16),
              child: Row(
                children: [
                  // Y-axis labels
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '10h',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '8h',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '6h',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '4h',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '2h',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '0h',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Chart area
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxValue = _hoursWorkedByDay.values.fold(
                          0.0,
                          (max, value) => value > max ? value : max,
                        );
                        final effectiveMax = maxValue > 10 ? maxValue : 10.0;

                        return Column(
                          children: [
                            // Chart bars
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children:
                                    sortedEntries.map((entry) {
                                      final percent =
                                          entry.value / effectiveMax;
                                      final displayDate = DateFormat(
                                        'MM/dd',
                                      ).format(DateTime.parse(entry.key));

                                      return Tooltip(
                                        message:
                                            '$displayDate: ${entry.value.toStringAsFixed(1)} hours',
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              width:
                                                  constraints.maxWidth /
                                                  (sortedEntries.length * 2),
                                              height:
                                                  constraints.maxHeight *
                                                  percent,
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      topLeft: Radius.circular(
                                                        4,
                                                      ),
                                                      topRight: Radius.circular(
                                                        4,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                            // X-axis labels
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children:
                                  sortedEntries.map((entry) {
                                    return SizedBox(
                                      width:
                                          constraints.maxWidth /
                                          (sortedEntries.length * 2),
                                      child: Text(
                                        DateFormat(
                                          'MM/dd',
                                        ).format(DateTime.parse(entry.key)),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(Map<AttendanceStatus, int> statusCounts) {
    // Calculate total for percentage
    int total = statusCounts.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      height: 24,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children:
            AttendanceStatus.values.map((status) {
              int count = statusCounts[status] ?? 0;
              double percentage = count / total;

              return Expanded(
                flex: (percentage * 100).round(),
                child: Container(
                  color: _getStatusColor(status),
                  height: 24,
                  child:
                      percentage > 0.1
                          ? Center(
                            child: Text(
                              '${(percentage * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          : null,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildAttendanceListCard() {
    if (_filteredAttendances.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No attendance records found',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Group attendances by employee for better viewing
    Map<String, List<Attendance>> groupedByEmployee = {};

    for (var attendance in _filteredAttendances) {
      if (!groupedByEmployee.containsKey(attendance.employeeId)) {
        groupedByEmployee[attendance.employeeId] = [];
      }
      groupedByEmployee[attendance.employeeId]!.add(attendance);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance Records',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Export functionality coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Consumer<EmployeeService>(
              builder: (context, employeeService, child) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groupedByEmployee.length,
                  itemBuilder: (context, index) {
                    String employeeId = groupedByEmployee.keys.elementAt(index);
                    List<Attendance> employeeAttendance =
                        groupedByEmployee[employeeId]!;

                    // Get employee details
                    Employee? employee;
                    try {
                      employee = employeeService.employees.firstWhere(
                        (e) => e.id == employeeId,
                      );
                    } catch (e) {
                      // Employee might not be in the current state list
                    }

                    String employeeName =
                        employee != null
                            ? '${employee.firstname} ${employee.lastname}'
                            : 'Unknown Employee';

                    return ExpansionTile(
                      title: Text(
                        employeeName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${employeeAttendance.length} records'),
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: employeeAttendance.length,
                          itemBuilder: (context, idx) {
                            final attendance = employeeAttendance[idx];

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(
                                  attendance.status,
                                ),
                                child: Icon(
                                  attendance.clockOutTime != null
                                      ? Icons.check
                                      : Icons.access_time,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                DateFormat(
                                  'EEE, MMM d, yyyy',
                                ).format(attendance.clockInTime),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'In: ${DateFormat('hh:mm a').format(attendance.clockInTime)}'
                                    '${attendance.clockOutTime != null ? ' | Out: ${DateFormat('hh:mm a').format(attendance.clockOutTime!)}' : ' | Not clocked out'}',
                                  ),
                                  if (attendance.durationInHours != null)
                                    Text(
                                      'Duration: ${attendance.durationInHours!.toStringAsFixed(2)} hours',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (attendance.notes.isNotEmpty)
                                    Text('Notes: ${attendance.notes}'),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(_getStatusText(attendance.status)),
                                backgroundColor: _getStatusColor(
                                  attendance.status,
                                ),
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.workFromHome:
        return 'WFH';
    }
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
}
