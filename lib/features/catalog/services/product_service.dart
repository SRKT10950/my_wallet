import '../../../core/db/db_base_fields.dart';
import '../../../core/models/base_model.dart';
import '../../../core/services/database_service.dart';
import '../models/price_history_model.dart';
import '../models/product_model.dart';

/// Data service for managing Enterprise Product Catalog and Price History.
class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  final _db = DatabaseService.instance;

  // ── Auto Translation Engine ───────────────────────────────────────
  static final Map<String, Map<String, String>> _dictionary = {
    'rice': {
      'hi': 'चावल',
      'ta': 'அரிசி',
      'kn': 'ಅಕ್ಕಿ',
      'mr': 'तांदूळ',
      'gu': 'ચોખા',
    },
    'wheat': {
      'hi': 'गेहूं',
      'ta': 'கோதுமை',
      'kn': 'ಗೋಧಿ',
      'mr': 'गहू',
      'gu': 'ઘઉં',
    },
    'milk': {
      'hi': 'दूध',
      'ta': 'பால்',
      'kn': 'ಹಾಲು',
      'mr': 'दूध',
      'gu': 'દૂધ',
    },
    'cooking oil': {
      'hi': 'खाना पकाने का तेल',
      'ta': 'சமையல் எண்ணெய்',
      'kn': 'ಅಡುಗೆ ಎಣ್ಣೆ',
      'mr': 'खाद्यतेल',
      'gu': 'તેલ',
    },
    'oil': {
      'hi': 'तेल',
      'ta': 'எண்ணெய்',
      'kn': 'ಎಣ್ಣೆ',
      'mr': 'तेल',
      'gu': 'તેલ',
    },
    'sugar': {
      'hi': 'चीनी',
      'ta': 'சர்க்கரை',
      'kn': 'ಸಕ್ಕರೆ',
      'mr': 'साखर',
      'gu': 'ખાંડ',
    },
    'tea': {
      'hi': 'चाय',
      'ta': 'தேநீர்',
      'kn': 'ಚಹಾ',
      'mr': 'चहा',
      'gu': 'ચા',
    },
    'coffee': {
      'hi': 'कॉफ़ी',
      'ta': 'காபி',
      'kn': 'ಕಾಫಿ',
      'mr': 'कॉफी',
      'gu': 'કોફી',
    },
    'bread': {
      'hi': 'ब्रेड',
      'ta': 'ரொட்டி',
      'kn': 'ಬ್ರೆಡ್',
      'mr': 'ब्रेड',
      'gu': 'બ્રેડ',
    },
    'salt': {
      'hi': 'नमक',
      'ta': 'உப்பு',
      'kn': 'ಉಪ್ಪು',
      'mr': 'मीठ',
      'gu': 'મીઠું',
    },
    'butter': {
      'hi': 'मक्खन',
      'ta': 'வெண்ணெய்',
      'kn': 'ಬೆಣ್ಣೆ',
      'mr': 'लोणी',
      'gu': 'માખણ',
    },
  };

  /// Auto translates an English product name into the target language.
  String autoTranslate(String englishName, String langCode) {
    final key = englishName.trim().toLowerCase();
    if (_dictionary.containsKey(key) && _dictionary[key]!.containsKey(langCode)) {
      return _dictionary[key]![langCode]!;
    }
    // Check partial key matches
    for (final entry in _dictionary.entries) {
      if (key.contains(entry.key) && entry.value.containsKey(langCode)) {
        return entry.value[langCode]!;
      }
    }
    return englishName;
  }

  // ── Default Enterprise Products ───────────────────────────────────
  static final List<ProductModel> _defaultProducts = [
    ProductModel(
      id: 'p1',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      productCode: 'PRD-101',
      productNameEnglish: 'Basmati Rice',
      productNameLocal: 'बासमती चावल',
      languageCode: 'hi',
      categoryId: 'cat_1',
      categoryName: 'Food & Dining',
      brand: 'India Gate',
      unit: 'Kg',
      oldPrice: 55.0,
      currentPrice: 60.0,
      marketPrice: 62.0,
      currency: '₹',
      effectiveDate: '2026-07-31',
      priceDifference: 5.0,
      priceTrend: 'increased',
      barcode: '8901234567890',
      barcodeType: 'EAN-13',
      qrCode: 'PRD-101|Basmati Rice|60',
      sku: 'SKU-RICE-01',
      hsnCode: '1006',
      gstPercentage: 5.0,
      statusBadge: 'Active',
    ),
    ProductModel(
      id: 'p2',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      productCode: 'PRD-102',
      productNameEnglish: 'Sunflower Oil 1L',
      productNameLocal: 'सूरजमुखी तेल',
      languageCode: 'hi',
      categoryId: 'cat_1',
      categoryName: 'Food & Dining',
      brand: 'Fortune',
      unit: 'Liter',
      oldPrice: 155.0,
      currentPrice: 148.0,
      marketPrice: 150.0,
      currency: '₹',
      effectiveDate: '2026-07-28',
      priceDifference: -7.0,
      priceTrend: 'reduced',
      barcode: '8909876543210',
      barcodeType: 'EAN-13',
      qrCode: 'PRD-102|Sunflower Oil|148',
      sku: 'SKU-OIL-02',
      hsnCode: '1512',
      gstPercentage: 5.0,
      statusBadge: 'Active',
    ),
  ];

  // ── Fetch Products ────────────────────────────────────────────────
  Future<List<ProductModel>> fetchProducts() async {
    final result = await _db.query(
      'SELECT * FROM products WHERE (is_deleted = 0 OR is_deleted IS NULL) ORDER BY created_at DESC',
    );

    if (result.success && result.isNotEmpty) {
      final dbProds = result.rows.map((row) => ProductModel.fromMap(row)).toList();
      final defaultsToKeep = _defaultProducts.where((d) => !dbProds.any((p) => p.id == d.id || p.productCode == d.productCode));
      return [...dbProds, ...defaultsToKeep];
    }

    return _defaultProducts;
  }

  // ── Save / Update Product & Log Price History ─────────────────────
  Future<bool> saveProduct(ProductModel product) async {
    final existing = await _db.query(
      'SELECT id, current_price, market_price FROM products WHERE id = ? LIMIT 1',
      [product.id],
    );

    double oldPrice = product.oldPrice;
    if (existing.success && existing.isNotEmpty) {
      final prevPrice = (existing.rows.first['current_price'] as num?)?.toDouble() ?? product.currentPrice;
      if (prevPrice != product.currentPrice) {
        oldPrice = prevPrice;
        // Log price change to product_price_history
        await _logPriceHistory(
          productId: product.id,
          oldPrice: prevPrice,
          newPrice: product.currentPrice,
          marketPrice: product.marketPrice,
          effectiveDate: product.effectiveDate,
        );
      }

      // Update product
      final updateFields = {
        ...DbBaseFields.updatedRecord(updatedBy: 'system', currentVersion: product.version),
        'product_code': product.productCode,
        'product_name_english': product.productNameEnglish,
        'product_name_local': product.productNameLocal,
        'language_code': product.languageCode,
        'category_id': product.categoryId,
        'category_name': product.categoryName,
        'brand': product.brand,
        'description': product.description,
        'unit': product.unit,
        'old_price': oldPrice,
        'current_price': product.currentPrice,
        'market_price': product.marketPrice,
        'currency': product.currency,
        'effective_date': product.effectiveDate,
        'expiry_date': product.expiryDate,
        'price_difference': product.currentPrice - oldPrice,
        'price_trend': product.currentPrice > oldPrice ? 'increased' : (product.currentPrice < oldPrice ? 'reduced' : 'no_change'),
        'barcode': product.barcode,
        'barcode_type': product.barcodeType,
        'qr_code': product.qrCode,
        'sku': product.sku,
        'hsn_code': product.hsnCode,
        'gst_percentage': product.gstPercentage,
        'manufacturer': product.manufacturer,
        'country': product.country,
        'reference_link': product.referenceLink,
        'application_name': product.applicationName,
        'image_url': product.imageUrl,
        'thumbnail_url': product.thumbnailUrl,
        'status_badge': product.statusBadge,
        'is_active': product.isActiveStatus ? 1 : 0,
      };

      final set = DbBaseFields.buildSetClause(updateFields);
      final res = await _db.query(
        'UPDATE products SET ${set.clause} WHERE id = ?',
        [...set.params, product.id],
      );
      return res.success;
    } else {
      // Insert product
      final fields = {
        ...DbBaseFields.newRecord(),
        'id': product.id.isNotEmpty ? product.id : BaseModel.newId(),
        'product_code': product.productCode,
        'product_name_english': product.productNameEnglish,
        'product_name_local': product.productNameLocal,
        'language_code': product.languageCode,
        'category_id': product.categoryId,
        'category_name': product.categoryName,
        'brand': product.brand,
        'description': product.description,
        'unit': product.unit,
        'old_price': product.oldPrice,
        'current_price': product.currentPrice,
        'market_price': product.marketPrice,
        'currency': product.currency,
        'effective_date': product.effectiveDate,
        'expiry_date': product.expiryDate,
        'price_difference': product.currentPrice - product.oldPrice,
        'price_trend': product.priceTrend,
        'barcode': product.barcode,
        'barcode_type': product.barcodeType,
        'qr_code': product.qrCode,
        'sku': product.sku,
        'hsn_code': product.hsnCode,
        'gst_percentage': product.gstPercentage,
        'manufacturer': product.manufacturer,
        'country': product.country,
        'reference_link': product.referenceLink,
        'application_name': product.applicationName,
        'image_url': product.imageUrl,
        'thumbnail_url': product.thumbnailUrl,
        'status_badge': product.statusBadge,
        'is_active': product.isActiveStatus ? 1 : 0,
      };

      final res = await _db.insertRecord('products', fields);

      // Log initial price history
      await _logPriceHistory(
        productId: fields['id'] as String,
        oldPrice: product.oldPrice,
        newPrice: product.currentPrice,
        marketPrice: product.marketPrice,
        effectiveDate: product.effectiveDate,
      );

      return res.success;
    }
  }

  // ── Private Price History Logger ──────────────────────────────────
  Future<void> _logPriceHistory({
    required String productId,
    required double oldPrice,
    required double newPrice,
    required double marketPrice,
    required String effectiveDate,
  }) async {
    final fields = {
      ...DbBaseFields.newRecord(),
      'id': BaseModel.newId(),
      'product_id': productId,
      'old_price': oldPrice,
      'new_price': newPrice,
      'market_price': marketPrice,
      'effective_date': effectiveDate,
      'updated_by_user': 'System Admin',
    };
    await _db.insertRecord('product_price_history', fields);
  }

  // ── Fetch Price History Timeline ──────────────────────────────────
  Future<List<PriceHistoryModel>> fetchPriceHistory(String productId) async {
    final result = await _db.query(
      'SELECT * FROM product_price_history WHERE product_id = ? ORDER BY created_at DESC',
      [productId],
    );

    if (result.success && result.isNotEmpty) {
      return result.rows.map((r) => PriceHistoryModel.fromMap(r)).toList();
    }

    return [
      PriceHistoryModel(
        id: 'h1',
        createdAt: DateTime.now().toUtc().toIso8601String(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
        productId: productId,
        oldPrice: 55.0,
        newPrice: 60.0,
        marketPrice: 62.0,
        effectiveDate: '2026-07-31',
        updatedByUser: 'System Admin',
      ),
    ];
  }

  // ── Soft Delete Product ───────────────────────────────────────────
  Future<bool> deleteProduct(String productId) async {
    final res = await _db.softDelete(
      'products',
      productId,
      deletedBy: 'system',
      currentVersion: 1,
    );
    return res.success;
  }
}
