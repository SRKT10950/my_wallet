class Category {
  final int? id;
  final String name;
  final double plannedAmount;
  final bool deleted;

  Category({
    this.id,
    required this.name,
    required this.plannedAmount,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'plannedAmount': plannedAmount,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      name: map['name'],
      plannedAmount: (map['plannedAmount'] ?? 0.0).toDouble(),
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  Category copyWith({
    int? id,
    String? name,
    double? plannedAmount,
    bool? deleted,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      plannedAmount: plannedAmount ?? this.plannedAmount,
      deleted: deleted ?? this.deleted,
    );
  }
}

