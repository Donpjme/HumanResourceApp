import 'package:uuid/uuid.dart';
import 'permissions.dart';

class Role {
  final String id;
  final String name;
  final String description;
  final List<Permission> permissions;
  final String department;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;
  final bool isActive;

  Role({
    String? id,
    required this.name,
    required this.description,
    required this.permissions,
    this.department = '',
    DateTime? createdAt,
    this.lastModifiedAt,
    this.isActive = true,
    // ignore: unnecessary_this
  }) : this.id = id ?? const Uuid().v4(),
       // ignore: unnecessary_this
       this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'permissions': permissions.map((p) => p.toString()).join(','),
    'department': department,
    'createdAt': createdAt.toIso8601String(),
    'lastModifiedAt': lastModifiedAt?.toIso8601String(),
    'isActive': isActive ? 1 : 0,
  };

  factory Role.fromJson(Map<String, dynamic> json) {
    // Handle both cases: string (from DB) or List (from code)
    List<String> permissionStrings;
    if (json['permissions'] is String) {
      permissionStrings = (json['permissions'] as String).split(',');
    } else if (json['permissions'] is List) {
      permissionStrings =
          (json['permissions'] as List).map((p) => p.toString()).toList();
    } else {
      // Fallback in case of unexpected format
      permissionStrings = [];
    }

    return Role(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      permissions:
          permissionStrings
              .map(
                (p) => Permission.values.firstWhere(
                  (e) => e.toString() == p,
                  orElse: () => Permission.viewEmployees,
                ),
              )
              .toList(),
      department: json['department'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      lastModifiedAt:
          json['lastModifiedAt'] != null
              ? DateTime.parse(json['lastModifiedAt'])
              : null,
      isActive: json['isActive'] == 1,
    );
  }
}
