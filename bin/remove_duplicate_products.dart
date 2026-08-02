import 'dart:convert';
import 'package:http/http.dart' as http;

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
  print('Deduplicating Products in wallet_products Table');
  print('================================================================\n');

  try {
    final rows = await queryTarget('''
      SELECT id, user_id, "productName", "localName", category 
      FROM wallet_products 
      ORDER BY user_id, LOWER(TRIM("productName")), id ASC
    ''');

    print('Fetched total ${rows.length} total product rows from database.');

    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final row in rows) {
      final user = row['user_id']?.toString() ?? 'unknown';
      final name = row['productName']?.toString().trim().toLowerCase() ?? '';
      final key = '${user}_$name';

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(row);
    }

    int removedCount = 0;

    for (final entry in grouped.entries) {
      final list = entry.value;
      if (list.length > 1) {
        // Keep the first item (smallest ID), delete the rest
        final keep = list.first;
        final duplicates = list.sublist(1);

        print('Found ${duplicates.length} duplicate(s) for "${keep['productName']}" (User: ${keep['user_id']}). Keeping ID: ${keep['id']}');

        for (final dup in duplicates) {
          final dupId = dup['id'];
          final dupUser = dup['user_id'];
          await executeTarget(
            'DELETE FROM wallet_products WHERE user_id = \$1 AND id = \$2',
            [dupUser, dupId],
          );
          removedCount++;
          print('  ❌ Deleted duplicate ID $dupId');
        }
      }
    }

    print('\n================================================================');
    print('🎉 DEDUPLICATION COMPLETE!');
    print('Total duplicate rows removed: $removedCount');
    print('Remaining unique products in DB: ${rows.length - removedCount}');
    print('================================================================');

  } catch (e) {
    print('❌ Error during deduplication: $e');
  }
}
