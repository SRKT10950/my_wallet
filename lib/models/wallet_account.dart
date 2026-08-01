class WalletAccount {
  final int? id;
  final String name;
  final String type; // 'Cash', 'Bank Account', 'Credit Card', 'Savings', 'Other'
  final double initialBalance;
  final String currencySymbol; // '₹', '$', '€', '£', etc.
  final String color; // Hex color string, e.g., '#6366F1'
  final bool deleted;

  WalletAccount({
    this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.currencySymbol,
    required this.color,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'initialBalance': initialBalance,
      'currencySymbol': currencySymbol,
      'color': color,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory WalletAccount.fromMap(Map<String, dynamic> map) {
    return WalletAccount(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      name: map['name'] ?? '',
      type: map['type'] ?? 'Cash',
      initialBalance: (map['initialBalance'] ?? 0.0).toDouble(),
      currencySymbol: map['currencySymbol'] ?? '₹',
      color: map['color'] ?? '#6366F1',
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  WalletAccount copyWith({
    int? id,
    String? name,
    String? type,
    double? initialBalance,
    String? currencySymbol,
    String? color,
    bool? deleted,
  }) {
    return WalletAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      color: color ?? this.color,
      deleted: deleted ?? this.deleted,
    );
  }
}

