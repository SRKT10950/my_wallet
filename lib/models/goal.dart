class Goal {
  final int? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final String? targetDate; // ISO date string
  final int? accountId; // Optional linked wallet account
  final String color; // Hex color string
  final bool deleted;

  Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    this.targetDate,
    this.accountId,
    required this.color,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'targetDate': targetDate,
      'accountId': accountId,
      'color': color,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0.0).toDouble(),
      savedAmount: (map['savedAmount'] ?? 0.0).toDouble(),
      targetDate: map['targetDate'],
      accountId: map['accountId'] is int ? map['accountId'] : int.tryParse(map['accountId']?.toString() ?? ''),
      color: map['color'] ?? '#6366F1',
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  Goal copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    String? targetDate,
    int? accountId,
    String? color,
    bool? deleted,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      accountId: accountId ?? this.accountId,
      color: color ?? this.color,
      deleted: deleted ?? this.deleted,
    );
  }
}

