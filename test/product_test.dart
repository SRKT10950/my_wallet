import 'package:flutter_test/flutter_test.dart';
import 'package:my_wallet/models/product.dart';

void main() {
  group('Product Model Tests', () {
    test('Product creation & toMap / fromMap serialization with Category', () {
      final p = Product(
        id: 1,
        productName: 'Organic Rice',
        localName: 'चावल',
        category: 'Groceries',
        referenceLink: 'https://example.com/rice',
        appName: 'Blinkit',
        priceDate: '2026-07-25',
        currentPrice: 120.0,
        oldPrice: 135.0,
        unit: 'Kg',
        quantity: 5.0,
      );

      expect(p.displayName, 'Organic Rice (चावल)');
      expect(p.effectivePrice, 120.0);
      expect(p.category, 'Groceries');

      final map = p.toMap();
      expect(map['productName'], 'Organic Rice');
      expect(map['localName'], 'चावल');
      expect(map['category'], 'Groceries');
      expect(map['unit'], 'Kg');

      final fromMap = Product.fromMap(map);
      expect(fromMap.productName, 'Organic Rice');
      expect(fromMap.category, 'Groceries');
      expect(fromMap.effectivePrice, 120.0);
    });

    test('Effective price falls back to oldPrice if currentPrice is 0', () {
      final p = Product(
        productName: 'Coconut Water',
        category: 'Snacks & Drinks',
        priceDate: '2026-07-25',
        currentPrice: 0.0,
        oldPrice: 45.0,
      );

      expect(p.effectivePrice, 45.0);
      expect(p.category, 'Snacks & Drinks');
    });
  });
}
