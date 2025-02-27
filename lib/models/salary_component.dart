// salary_component.dart
import 'package:uuid/uuid.dart';

enum ComponentType { allowance, deduction }

class SalaryComponent {
  final String id;
  final String name;
  final ComponentType type;
  final bool isTaxable;
  final double defaultAmount;
  final bool isPercentage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;

  SalaryComponent({
    String? id,
    required this.name,
    required this.type,
    required this.isTaxable,
    this.defaultAmount = 0.0,
    this.isPercentage = false,
    this.isActive = true,
    DateTime? createdAt,
    this.lastModifiedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'isTaxable': isTaxable ? 1 : 0,
      'defaultAmount': defaultAmount,
      'isPercentage': isPercentage ? 1 : 0,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
    };
  }

  factory SalaryComponent.fromJson(Map<String, dynamic> json) {
    return SalaryComponent(
      id: json['id'],
      name: json['name'],
      type: _parseComponentType(json['type']),
      isTaxable: json['isTaxable'] == 1,
      defaultAmount: json['defaultAmount'],
      isPercentage: json['isPercentage'] == 1,
      isActive: json['isActive'] == 1,
      createdAt: DateTime.parse(json['createdAt']),
      lastModifiedAt:
          json['lastModifiedAt'] != null
              ? DateTime.parse(json['lastModifiedAt'])
              : null,
    );
  }

  static ComponentType _parseComponentType(String type) {
    return ComponentType.values.firstWhere(
      (e) => e.toString() == type,
      orElse: () => ComponentType.allowance,
    );
  }
}
