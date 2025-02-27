// tax_rule.dart
import 'package:uuid/uuid.dart';

class TaxRule {
  final String id;
  final String name;
  final double minIncome;
  final double maxIncome;
  final double rate; // Percentage value (e.g., 10.0 for 10%)
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;

  TaxRule({
    String? id,
    required this.name,
    required this.minIncome,
    required this.maxIncome,
    required this.rate,
    this.isActive = true,
    DateTime? createdAt,
    this.lastModifiedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'minIncome': minIncome,
      'maxIncome': maxIncome,
      'rate': rate,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
    };
  }

  factory TaxRule.fromJson(Map<String, dynamic> json) {
    return TaxRule(
      id: json['id'],
      name: json['name'],
      minIncome: json['minIncome'],
      maxIncome: json['maxIncome'],
      rate: json['rate'],
      isActive: json['isActive'] == 1,
      createdAt: DateTime.parse(json['createdAt']),
      lastModifiedAt:
          json['lastModifiedAt'] != null
              ? DateTime.parse(json['lastModifiedAt'])
              : null,
    );
  }
}
