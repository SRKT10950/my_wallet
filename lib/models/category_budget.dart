class CategoryBudget {
  final int? id;
  final int categoryId;
  final int month;
  final int year;
  final double amount;

  CategoryBudget({
    this.id,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'month': month,
      'year': year,
      'amount': amount,
    };
  }

  factory CategoryBudget.fromMap(Map<String, dynamic> map) {
    return CategoryBudget(
      id: map['id'],
      categoryId: map['categoryId'],
      month: map['month'],
      year: map['year'],
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }
}
