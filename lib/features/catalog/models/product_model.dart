import '../../../core/models/base_model.dart';

/// Represents a product or service in the My Wallet catalog.
///
/// Extends [BaseModel] to inherit all 13 standardized audit & control fields.
class ProductModel extends BaseModel {
  final String productCode;
  final String productNameEnglish;
  final String productNameLocal;
  final String languageCode;
  final String? categoryId;
  final String? brand;
  final String? description;
  final String unit; // 'Kg', 'Gram', 'Liter', 'ml', 'Piece', 'Pack', 'Box', 'Bottle', 'Dozen', 'Meter'
  final double oldPrice;
  final double currentPrice;
  final double marketPrice;
  final String currency;
  final String effectiveDate;
  final String? expiryDate;
  final double priceDifference;
  final String priceTrend; // 'increased', 'reduced', 'no_change'
  final String? barcode;
  final String barcodeType; // 'Code128', 'EAN-13', 'UPC', 'Code39'
  final String? qrCode;
  final String? sku;
  final String? hsnCode;
  final double gstPercentage;
  final String? manufacturer;
  final String country;
  final String? referenceLink;
  final String applicationName;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String statusBadge; // 'Active', 'Inactive', 'Discontinued', 'Out of Stock'
  final bool isActiveStatus;

  const ProductModel({
    // Base fields
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.createdBy,
    super.updatedBy,
    super.deletedAt,
    super.deletedBy,
    super.isDeleted,
    super.version,
    super.status,
    super.tenantId,
    super.remarks,
    super.metadata,
    // Product fields
    required this.productCode,
    required this.productNameEnglish,
    required this.productNameLocal,
    this.languageCode = 'hi',
    this.categoryId,
    this.brand,
    this.description,
    this.unit = 'Piece',
    this.oldPrice = 0.0,
    required this.currentPrice,
    this.marketPrice = 0.0,
    this.currency = '₹',
    required this.effectiveDate,
    this.expiryDate,
    this.priceDifference = 0.0,
    this.priceTrend = 'no_change',
    this.barcode,
    this.barcodeType = 'Code128',
    this.qrCode,
    this.sku,
    this.hsnCode,
    this.gstPercentage = 0.0,
    this.manufacturer,
    this.country = 'India',
    this.referenceLink,
    this.applicationName = 'My Wallet',
    this.imageUrl,
    this.thumbnailUrl,
    this.statusBadge = 'Active',
    this.isActiveStatus = true,
  });

  // ── Helper Getters ────────────────────────────────────────────────

  /// Format price difference pill text (+₹5 or -₹2)
  String get formattedPriceDiff {
    final diff = currentPrice - oldPrice;
    if (diff > 0) {
      return '+$currency${diff.toStringAsFixed(0)}';
    } else if (diff < 0) {
      return '-$currency${diff.abs().toStringAsFixed(0)}';
    }
    return '${currency}0';
  }

  /// Price trend icon representation
  String get trendIcon {
    if (currentPrice > oldPrice && oldPrice > 0) return '▲';
    if (currentPrice < oldPrice && oldPrice > 0) return '▼';
    return '▬';
  }

  /// Price trend status label
  String get trendLabel {
    if (currentPrice > oldPrice && oldPrice > 0) return 'Increased';
    if (currentPrice < oldPrice && oldPrice > 0) return 'Reduced';
    return 'No Change';
  }

  // ── Deserialisation ───────────────────────────────────────────────

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    final base = BaseModel.baseFromMap(map);
    final cur = (map['current_price'] as num?)?.toDouble() ?? 0.0;
    final old = (map['old_price'] as num?)?.toDouble() ?? 0.0;

    String trend = map['price_trend']?.toString() ?? 'no_change';
    if (cur > old && old > 0) trend = 'increased';
    if (cur < old && old > 0) trend = 'reduced';

    return ProductModel(
      // Base fields
      id: base['id'] as String,
      createdAt: base['created_at'] as String,
      updatedAt: base['updated_at'] as String,
      createdBy: base['created_by'] as String?,
      updatedBy: base['updated_by'] as String?,
      deletedAt: base['deleted_at'] as String?,
      deletedBy: base['deleted_by'] as String?,
      isDeleted: base['is_deleted'] as bool,
      version: base['version'] as int,
      status: base['status'] as String,
      tenantId: base['tenant_id'] as String?,
      remarks: base['remarks'] as String?,
      metadata: base['metadata'] as String?,
      // Product fields
      productCode: map['product_code']?.toString() ?? 'PRD-001',
      productNameEnglish: map['product_name_english']?.toString() ?? map['name']?.toString() ?? '',
      productNameLocal: map['product_name_local']?.toString() ?? '',
      languageCode: map['language_code']?.toString() ?? 'hi',
      categoryId: map['category_id']?.toString(),
      brand: map['brand']?.toString(),
      description: map['description']?.toString(),
      unit: map['unit']?.toString() ?? 'Piece',
      oldPrice: old,
      currentPrice: cur,
      marketPrice: (map['market_price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? '₹',
      effectiveDate: map['effective_date']?.toString() ?? DateTime.now().toString().split(' ')[0],
      expiryDate: map['expiry_date']?.toString(),
      priceDifference: (map['price_difference'] as num?)?.toDouble() ?? (cur - old),
      priceTrend: trend,
      barcode: map['barcode']?.toString(),
      barcodeType: map['barcode_type']?.toString() ?? 'Code128',
      qrCode: map['qr_code']?.toString(),
      sku: map['sku']?.toString(),
      hsnCode: map['hsn_code']?.toString(),
      gstPercentage: (map['gst_percentage'] as num?)?.toDouble() ?? 0.0,
      manufacturer: map['manufacturer']?.toString(),
      country: map['country']?.toString() ?? 'India',
      referenceLink: map['reference_link']?.toString(),
      applicationName: map['application_name']?.toString() ?? 'My Wallet',
      imageUrl: map['image_url']?.toString(),
      thumbnailUrl: map['thumbnail_url']?.toString(),
      statusBadge: map['status_badge']?.toString() ?? 'Active',
      isActiveStatus: (map['is_active'] as num?)?.toInt() == 1 || map['is_active'] == true || map['is_active'] == null,
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────

  @override
  Map<String, dynamic> toMap() => {
        ...baseToMap(),
        'product_code': productCode,
        'product_name_english': productNameEnglish,
        'product_name_local': productNameLocal,
        'language_code': languageCode,
        'category_id': categoryId,
        'brand': brand,
        'description': description,
        'unit': unit,
        'old_price': oldPrice,
        'current_price': currentPrice,
        'market_price': marketPrice,
        'currency': currency,
        'effective_date': effectiveDate,
        'expiry_date': expiryDate,
        'price_difference': currentPrice - oldPrice,
        'price_trend': priceTrend,
        'barcode': barcode,
        'barcode_type': barcodeType,
        'qr_code': qrCode,
        'sku': sku,
        'hsn_code': hsnCode,
        'gst_percentage': gstPercentage,
        'manufacturer': manufacturer,
        'country': country,
        'reference_link': referenceLink,
        'application_name': applicationName,
        'image_url': imageUrl,
        'thumbnail_url': thumbnailUrl,
        'status_badge': statusBadge,
        'is_active': isActiveStatus ? 1 : 0,
      };
}
