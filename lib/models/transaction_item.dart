class TransactionItem {
  final int? id;
  final int? transactionId;
  final String userId;
  final int? productId;
  final String itemName;
  final String localName;
  final String category;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;
  final bool deleted;
  final int? createdAt;
  final int? updatedAt;

  TransactionItem({
    this.id,
    this.transactionId,
    this.userId = 'user_1',
    this.productId,
    required this.itemName,
    this.localName = '',
    this.category = 'General',
    this.quantity = 1.0,
    this.unit = 'Pcs',
    this.unitPrice = 0.0,
    double? totalPrice,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  }) : totalPrice = totalPrice ?? (unitPrice * quantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'user_id': userId,
      'product_id': productId,
      'item_name': itemName,
      'local_name': localName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'deleted': deleted ? 1 : 0,
      'created_at': createdAt ?? DateTime.now().millisecondsSinceEpoch,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      transactionId: map['transaction_id'] != null ? int.tryParse(map['transaction_id'].toString()) : null,
      userId: map['user_id']?.toString() ?? 'user_1',
      productId: map['product_id'] != null ? int.tryParse(map['product_id'].toString()) : null,
      itemName: map['item_name']?.toString() ?? map['productName']?.toString() ?? 'Item',
      localName: map['local_name']?.toString() ?? map['localName']?.toString() ?? '',
      category: map['category']?.toString() ?? 'General',
      quantity: (map['quantity'] != null) ? (double.tryParse(map['quantity'].toString()) ?? 1.0) : 1.0,
      unit: map['unit']?.toString() ?? 'Pcs',
      unitPrice: (map['unit_price'] != null) ? (double.tryParse(map['unit_price'].toString()) ?? 0.0) : 0.0,
      totalPrice: (map['total_price'] != null) ? (double.tryParse(map['total_price'].toString()) ?? 0.0) : null,
      deleted: (map['deleted'] == 1 || map['deleted'] == true),
      createdAt: map['created_at'] != null ? int.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? int.tryParse(map['updated_at'].toString()) : null,
    );
  }

  TransactionItem copyWith({
    int? id,
    int? transactionId,
    String? userId,
    int? productId,
    String? itemName,
    String? localName,
    String? category,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? totalPrice,
    bool? deleted,
    int? createdAt,
    int? updatedAt,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      itemName: itemName ?? this.itemName,
      localName: localName ?? this.localName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
