class Product {
  final int? id;
  final String userId;
  final String productName;
  final String localName;
  final String category;
  final String referenceLink;
  final String appName;
  final String priceDate;
  final double currentPrice;
  final double oldPrice;
  final String unit;
  final double quantity;
  final String barcode;
  final String qrCode;
  final String imageUrl;
  final String description;
  final bool active;
  final bool deleted;

  Product({
    this.id,
    this.userId = 'user_1',
    required this.productName,
    this.localName = '',
    this.category = 'General',
    this.referenceLink = '',
    this.appName = '',
    this.priceDate = '',
    this.currentPrice = 0.0,
    this.oldPrice = 0.0,
    this.unit = 'Pcs',
    this.quantity = 1.0,
    this.barcode = '',
    this.qrCode = '',
    this.imageUrl = '',
    this.description = '',
    this.active = true,
    this.deleted = false,
  });

  double get effectivePrice => currentPrice > 0 ? currentPrice : oldPrice;

  String get displayName => productName + (localName.isNotEmpty ? ' ($localName)' : '');

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'productName': productName,
      'localName': localName,
      'category': category,
      'referenceLink': referenceLink,
      'appName': appName,
      'priceDate': priceDate,
      'currentPrice': currentPrice,
      'oldPrice': oldPrice,
      'unit': unit,
      'quantity': quantity,
      'barcode': barcode,
      'qrCode': qrCode,
      'imageUrl': imageUrl,
      'description': description,
      'active': active ? 1 : 0,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      userId: map['user_id']?.toString() ?? 'user_1',
      productName: map['productName']?.toString() ?? '',
      localName: map['localName']?.toString() ?? '',
      category: map['category']?.toString() ?? 'General',
      referenceLink: map['referenceLink']?.toString() ?? '',
      appName: map['appName']?.toString() ?? '',
      priceDate: map['priceDate']?.toString() ?? '',
      currentPrice: (map['currentPrice'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (map['oldPrice'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? 'Pcs',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      barcode: map['barcode']?.toString() ?? '',
      qrCode: map['qrCode']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      description: map['description']?.toString() ?? map['Description']?.toString() ?? '',
      active: map['active'] == 1 || map['active'] == true,
      deleted: map['deleted'] == 1 || map['deleted'] == true,
    );
  }

  Product copyWith({
    int? id,
    String? userId,
    String? productName,
    String? localName,
    String? category,
    String? referenceLink,
    String? appName,
    String? priceDate,
    double? currentPrice,
    double? oldPrice,
    String? unit,
    double? quantity,
    String? barcode,
    String? qrCode,
    String? imageUrl,
    String? description,
    bool? active,
    bool? deleted,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productName: productName ?? this.productName,
      localName: localName ?? this.localName,
      category: category ?? this.category,
      referenceLink: referenceLink ?? this.referenceLink,
      appName: appName ?? this.appName,
      priceDate: priceDate ?? this.priceDate,
      currentPrice: currentPrice ?? this.currentPrice,
      oldPrice: oldPrice ?? this.oldPrice,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      barcode: barcode ?? this.barcode,
      qrCode: qrCode ?? this.qrCode,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      active: active ?? this.active,
      deleted: deleted ?? this.deleted,
    );
  }
}
