class Category {
  final int? id;
  final String name;
  final double plannedAmount;

  Category({
    this.id,
    required this.name,
    required this.plannedAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'plannedAmount': plannedAmount,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      plannedAmount: map['plannedAmount'],
    );
  }
}
