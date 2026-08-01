class IncomeConfig {
  final int? id;
  final int month;
  final int year;
  final double amount;
  final bool isDefault;
  final bool deleted;

  IncomeConfig({
    this.id,
    required this.month,
    required this.year,
    required this.amount,
    required this.isDefault,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'amount': amount,
      'isDefault': isDefault ? 1 : 0,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory IncomeConfig.fromMap(Map<String, dynamic> map) {
    return IncomeConfig(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      month: map['month'] is int ? map['month'] : (int.tryParse(map['month']?.toString() ?? '') ?? 0),
      year: map['year'] is int ? map['year'] : (int.tryParse(map['year']?.toString() ?? '') ?? 0),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isDefault: map['isDefault'] == 1 || map['isDefault'] == true,
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  IncomeConfig copyWith({
    int? id,
    int? month,
    int? year,
    double? amount,
    bool? isDefault,
    bool? deleted,
  }) {
    return IncomeConfig(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      amount: amount ?? this.amount,
      isDefault: isDefault ?? this.isDefault,
      deleted: deleted ?? this.deleted,
    );
  }
}

