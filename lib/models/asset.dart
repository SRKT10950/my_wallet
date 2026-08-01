class Asset {
  final int? id;
  final String name;
  final String category; // 'Precious Metals', 'Crypto', 'Stocks/MFs', 'Real Estate', 'Other'
  final double quantity;
  final double buyPrice; // price per unit when bought
  final double currentPrice; // current mock price per unit
  final String symbol; // e.g., 'BTC', 'GOLD', 'AAPL'
  final String dateAdded;
  final bool deleted;

  Asset({
    this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.buyPrice,
    required this.currentPrice,
    required this.symbol,
    required this.dateAdded,
    this.deleted = false,
  });

  double get totalInvested => quantity * buyPrice;
  double get totalCurrentValue => quantity * currentPrice;
  double get unrealizedGainLoss => totalCurrentValue - totalInvested;
  double get unrealizedGainLossPercentage => totalInvested > 0 ? (unrealizedGainLoss / totalInvested) * 100 : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'buyPrice': buyPrice,
      'currentPrice': currentPrice,
      'symbol': symbol,
      'dateAdded': dateAdded,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      name: map['name'] ?? '',
      category: map['category'] ?? 'Other',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      buyPrice: (map['buyPrice'] ?? 0.0).toDouble(),
      currentPrice: (map['currentPrice'] ?? 0.0).toDouble(),
      symbol: map['symbol'] ?? '',
      dateAdded: map['dateAdded'] ?? DateTime.now().toIso8601String(),
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  Asset copyWith({
    int? id,
    String? name,
    String? category,
    double? quantity,
    double? buyPrice,
    double? currentPrice,
    String? symbol,
    String? dateAdded,
    bool? deleted,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      buyPrice: buyPrice ?? this.buyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      symbol: symbol ?? this.symbol,
      dateAdded: dateAdded ?? this.dateAdded,
      deleted: deleted ?? this.deleted,
    );
  }
}

