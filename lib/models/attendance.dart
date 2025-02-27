import 'package:uuid/uuid.dart';

class Attendance {
  final String id;
  final String employeeId;
  final DateTime clockInTime;
  final DateTime? clockOutTime;
  final String notes;
  final AttendanceStatus status;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;

  Attendance({
    String? id,
    required this.employeeId,
    required this.clockInTime,
    this.clockOutTime,
    this.notes = '',
    this.status = AttendanceStatus.present,
    DateTime? createdAt,
    this.lastModifiedAt,
  // ignore: unnecessary_this
  }) : this.id = id ?? const Uuid().v4(),
       // ignore: unnecessary_this
       this.createdAt = createdAt ?? DateTime.now();

  // Calculate duration in hours (returns null if not clocked out)
  double? get durationInHours {
    if (clockOutTime == null) return null;
    return clockOutTime!.difference(clockInTime).inMinutes / 60;
  }

  // Check if employee is currently clocked in
  bool get isActive => clockOutTime == null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'clockInTime': clockInTime.toIso8601String(),
      'clockOutTime': clockOutTime?.toIso8601String(),
      'notes': notes,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      employeeId: json['employeeId'],
      clockInTime: DateTime.parse(json['clockInTime']),
      clockOutTime:
          json['clockOutTime'] != null
              ? DateTime.parse(json['clockOutTime'])
              : null,
      notes: json['notes'] ?? '',
      status: _parseAttendanceStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      lastModifiedAt:
          json['lastModifiedAt'] != null
              ? DateTime.parse(json['lastModifiedAt'])
              : null,
    );
  }

  static AttendanceStatus _parseAttendanceStatus(String status) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.toString() == status,
      orElse: () => AttendanceStatus.present,
    );
  }
}

enum AttendanceStatus { present, late, absent, halfDay, workFromHome }
