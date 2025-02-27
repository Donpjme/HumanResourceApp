import 'package:uuid/uuid.dart';

class Leave {
  final String id;
  final String employeeId;
  final String employeeName; // For display purposes
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final String? approvedById;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;

  Leave({
    String? id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = LeaveStatus.pending,
    this.approvedById,
    this.rejectionReason,
    DateTime? createdAt,
    this.lastModifiedAt,
  // ignore: unnecessary_this
  }) : this.id = id ?? const Uuid().v4(),
       // ignore: unnecessary_this
       this.createdAt = createdAt ?? DateTime.now();

  // Calculate the number of days of leave
  int get durationInDays {
    return endDate.difference(startDate).inDays +
        1; // Include both start and end days
  }

  // Check if the leave is current (ongoing)
  bool isCurrent(DateTime currentDate) {
    return status == LeaveStatus.approved &&
        currentDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        currentDate.isBefore(endDate.add(const Duration(days: 1)));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'type': type.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'status': status.toString(),
      'approvedById': approvedById,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
    };
  }

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['id'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      type: _parseLeaveType(json['type']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      reason: json['reason'],
      status: _parseLeaveStatus(json['status']),
      approvedById: json['approvedById'],
      rejectionReason: json['rejectionReason'],
      createdAt: DateTime.parse(json['createdAt']),
      lastModifiedAt:
          json['lastModifiedAt'] != null
              ? DateTime.parse(json['lastModifiedAt'])
              : null,
    );
  }

  static LeaveType _parseLeaveType(String type) {
    return LeaveType.values.firstWhere(
      (e) => e.toString() == type,
      orElse: () => LeaveType.casual,
    );
  }

  static LeaveStatus _parseLeaveStatus(String status) {
    return LeaveStatus.values.firstWhere(
      (e) => e.toString() == status,
      orElse: () => LeaveStatus.pending,
    );
  }
}

enum LeaveType {
  casual,
  sick,
  annual,
  maternity,
  paternity,
  unpaid,
  compensatory,
  bereavement,
  studyLeave,
  other,
}

enum LeaveStatus { pending, approved, rejected, cancelled }
