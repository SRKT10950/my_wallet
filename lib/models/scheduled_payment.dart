class ScheduledPayment {
  final int? id;
  final String name;
  final double amount;
  final String type; // 'Expense', 'Income'
  final int categoryId;
  final int accountId;
  final String frequency; // 'Daily', 'Weekly', 'Monthly', 'Yearly'
  final String nextDueDate; // ISO date string
  final bool active;
  final bool deleted;

  ScheduledPayment({
    this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.frequency,
    required this.nextDueDate,
    required this.active,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'accountId': accountId,
      'frequency': frequency,
      'nextDueDate': nextDueDate,
      'active': active ? 1 : 0,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory ScheduledPayment.fromMap(Map<String, dynamic> map) {
    return ScheduledPayment(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'Expense',
      categoryId: map['categoryId'] is int ? map['categoryId'] : (int.tryParse(map['categoryId']?.toString() ?? '') ?? 0),
      accountId: map['accountId'] is int ? map['accountId'] : (int.tryParse(map['accountId']?.toString() ?? '') ?? 0),
      frequency: map['frequency'] ?? 'Monthly',
      nextDueDate: map['nextDueDate'] ?? DateTime.now().toIso8601String(),
      active: map['active'] == 1 || map['active'] == true,
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  ScheduledPayment copyWith({
    int? id,
    String? name,
    double? amount,
    String? type,
    int? categoryId,
    int? accountId,
    String? frequency,
    String? nextDueDate,
    bool? active,
    bool? deleted,
  }) {
    return ScheduledPayment(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      active: active ?? this.active,
      deleted: deleted ?? this.deleted,
    );
  }
}

