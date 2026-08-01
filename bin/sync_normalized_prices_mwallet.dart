// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../lib/services/product_price_sync_service.dart';

const String targetApiUrl = 'https://db.mhservice.co.in/api/db/mWallet/query';
const String targetApiKey = 'hs_live_8cxzSYAq9aUv79HxDbADCdJ23yLtIWhQ';

Future<List<Map<String, dynamic>>> queryTarget(String sql, [List<dynamic>? params]) async {
  final res = await http.post(
    Uri.parse(targetApiUrl),
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': targetApiKey,
    },
    body: jsonEncode({
      'query': sql,
      'params': params ?? [],
    }),
  );
  if (res.statusCode != 200) {
    throw Exception('Query Failed (${res.statusCode}): ${res.body}');
  }
  final data = jsonDecode(res.body);
  if (data['success'] != true) {
    throw Exception('DB Error: ${data['error']}');
  }
  return List<Map<String, dynamic>>.from(data['rows'] ?? []);
}

Future<void> executeTarget(String sql, List<dynamic> params) async {
  final res = await http.post(
    Uri.parse(targetApiUrl),
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': targetApiKey,
    },
    body: jsonEncode({
      'query': sql,
      'params': params,
    }),
  );
  if (res.statusCode != 200) {
    throw Exception('Exec Failed (${res.statusCode}): ${res.body}');
  }
  final data = jsonDecode(res.body);
  if (data['success'] != true) {
    throw Exception('DB Error: ${data['error']}');
  }
}

Future<void> main() async {
  print('================================================================');
  print('Syncing Quantity-Normalized Lowest Prices to [mWallet]');
  print('================================================================\n');

  final products = await queryTarget('SELECT id, user_id, "productName", quantity, unit, "currentPrice" FROM wallet_products WHERE active = 1 AND deleted = 0');
  print('Found ${products.length} product(s) to benchmark & normalize.\n');

  int updatedCount = 0;
  final today = DateTime.now().toIso8601String().substring(0, 10);

  for (final p in products) {
    final prodName = p['productName']?.toString() ?? '';
    final qty = (p['quantity'] as num?)?.toDouble() ?? 1.0;
    final unit = p['unit']?.toString() ?? 'Pcs';
    final id = p['id']?.toString() ?? '';
    final userId = p['user_id']?.toString() ?? '';
    final currentPrice = (p['currentPrice'] as num?)?.toDouble() ?? 0.0;

    final quote = await ProductPriceSyncService.findMinimumPriceQuote(
      prodName,
      targetQuantity: qty,
      targetUnit: unit,
    );

    if (quote != null) {
      final updateSql = '''
        UPDATE wallet_products
        SET "oldPrice" = CASE WHEN "currentPrice" != \$1 THEN "currentPrice" ELSE "oldPrice" END,
            "currentPrice" = \$1,
            "appName" = \$2,
            "referenceLink" = \$3,
            "priceDate" = \$4,
            updated_at = \$5,
            last_updated_by = 'price_sync'
        WHERE id = \$6 AND user_id = \$7;
      ''';

      final params = [
        quote.normalizedPrice,
        quote.appName,
        quote.link,
        today,
        DateTime.now().millisecondsSinceEpoch,
        id,
        userId,
      ];

      try {
        await executeTarget(updateSql, params);
        updatedCount++;
        print('  [✓] $prodName ($qty $unit): Scaled price ₹${quote.normalizedPrice} on ${quote.appName}');
      } catch (e) {
        print('  [!] Failed to update $prodName: $e');
      }
    }
  }

  print('\n================================================================');
  print('Successfully benchmarked & updated $updatedCount products in [mWallet]!');
  print('================================================================');
}
