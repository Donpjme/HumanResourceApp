import 'package:uuid/uuid.dart';

class Employee {
  final String id;
  final String employeeId;
  final String firstname;
  final String lastname;
  final String email;
  final String phone;
  final String position;
  final String roleId; // Changed from Role to String
  final DateTime joiningDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;

  Employee({
    String? id,
    required this.employeeId,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.position,
    required this.roleId, // Changed from role to roleId
    required this.joiningDate,
    this.isActive = true,
    DateTime? createdAt,
    this.lastModifiedAt,
  // ignore: unnecessary_this
  }) : this.id = id ?? const Uuid().v4(),
       // ignore: unnecessary_this
       this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'phone': phone,
      'position': position,
      'roleId': roleId, // Changed from role to roleId
      'joiningDate': joiningDate.toIso8601String(),
      'isActive': isActive ? 1 : 0, // Convert boolean to int for SQLite
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      employeeId: json['employeeId'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      email: json['email'],
      phone: json['phone'],
      position: json['position'],
      roleId: json['roleId'], // Changed from role to roleId
      joiningDate: DateTime.parse(json['joiningDate']),
      isActive: json['isActive'] == 1, // Convert int to boolean
      createdAt: DateTime.parse(json['createdAt']),
      lastModifiedAt:
          json['lastModifiedAt'] != null
              ? DateTime.parse(json['lastModifiedAt'])
              : null,
    );
  }
}
