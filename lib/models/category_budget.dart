class CategoryBudget {
  final int? id;
  final int categoryId;
  final int month;
  final int year;
  final double amount;
  final bool deleted;

  CategoryBudget({
    this.id,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.amount,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'month': month,
      'year': year,
      'amount': amount,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory CategoryBudget.fromMap(Map<String, dynamic> map) {
    return CategoryBudget(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      categoryId: map['categoryId'] is int ? map['categoryId'] : (int.tryParse(map['categoryId']?.toString() ?? '') ?? 0),
      month: map['month'] is int ? map['month'] : (int.tryParse(map['month']?.toString() ?? '') ?? 0),
      year: map['year'] is int ? map['year'] : (int.tryParse(map['year']?.toString() ?? '') ?? 0),
      amount: (map['amount'] ?? 0.0).toDouble(),
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  CategoryBudget copyWith({
    int? id,
    int? categoryId,
    int? month,
    int? year,
    double? amount,
    bool? deleted,
  }) {
    return CategoryBudget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      year: year ?? this.year,
      amount: amount ?? this.amount,
      deleted: deleted ?? this.deleted,
    );
  }
}

