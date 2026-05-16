class IncomeConfig {
  final int? id;
  final int month;
  final int year;
  final double amount;
  final bool isDefault;

  IncomeConfig({
    this.id,
    required this.month,
    required this.year,
    required this.amount,
    required this.isDefault,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'amount': amount,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory IncomeConfig.fromMap(Map<String, dynamic> map) {
    return IncomeConfig(
      id: map['id'],
      month: map['month'],
      year: map['year'],
      amount: map['amount'],
      isDefault: map['isDefault'] == 1,
    );
  }
}
