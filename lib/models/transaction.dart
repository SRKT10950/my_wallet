class DailyTransaction {
  final int? id;
  final String date;
  final int categoryId;
  final String itemService;
  final double cost;
  final double paidAmount;
  final bool cleared;

  DailyTransaction({
    this.id,
    required this.date,
    required this.categoryId,
    required this.itemService,
    required this.cost,
    required this.paidAmount,
    required this.cleared,
  });

  double get remaining => cost - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'categoryId': categoryId,
      'itemService': itemService,
      'cost': cost,
      'paidAmount': paidAmount,
      'cleared': cleared ? 1 : 0,
    };
  }

  factory DailyTransaction.fromMap(Map<String, dynamic> map) {
    return DailyTransaction(
      id: map['id'],
      date: map['date'],
      categoryId: map['categoryId'],
      itemService: map['itemService'],
      cost: map['cost'],
      paidAmount: map['paidAmount'],
      cleared: map['cleared'] == 1,
    );
  }
}
