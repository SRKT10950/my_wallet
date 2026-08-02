import 'dart:convert';
import 'package:http/http.dart' as http;

const String targetApiUrl = 'https://db.mhservice.co.in/api/db/mWallet/query';
const String targetApiKey = 'hs_live_8cxzSYAq9aUv79HxDbADCdJ23yLtIWhQ';
const String targetUser = '7400700500';

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

final List<Map<String, dynamic>> dryFruitsAndSpices = [
  {'productName': 'Kishmish (Raisins)', 'localName': 'किशमिश (Kishmish)', 'category': 'Dry Fruits & Nuts', 'unit': 'Gram', 'quantity': 250.0, 'currentPrice': 90.0, 'description': 'Sweet high quality green raisins'},
  {'productName': 'Tejpatta (Bay Leaf)', 'localName': 'तेजपत्ता (Tejpatta / Bay Leaf)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 50.0, 'currentPrice': 25.0, 'description': 'Aromatic dried Indian bay leaves'},
  {'productName': 'Kaju (Cashew Nuts)', 'localName': 'काजू (Kaju)', 'category': 'Dry Fruits & Nuts', 'unit': 'Gram', 'quantity': 250.0, 'currentPrice': 220.0, 'description': 'Whole premium cashews'},
  {'productName': 'Badam (Almonds)', 'localName': 'बादाम (Badam)', 'category': 'Dry Fruits & Nuts', 'unit': 'Gram', 'quantity': 250.0, 'currentPrice': 210.0, 'description': 'California almonds'},
  {'productName': 'Pista (Pistachios)', 'localName': 'पिस्ता (Pista)', 'category': 'Dry Fruits & Nuts', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 280.0, 'description': 'Salted roasted pistachios'},
  {'productName': 'Akhrot (Walnuts)', 'localName': 'अखरोट (Akhrot)', 'category': 'Dry Fruits & Nuts', 'unit': 'Gram', 'quantity': 250.0, 'currentPrice': 290.0, 'description': 'Premium walnut kernels'},
  {'productName': 'Dry Anjeer (Figs)', 'localName': 'अंजीर (Dry Anjeer)', 'category': 'Dry Fruits & Nuts', 'unit': 'Gram', 'quantity': 250.0, 'currentPrice': 320.0, 'description': 'Dried sweet figs'},
  {'productName': 'Khajoor (Dates)', 'localName': 'खजूर (Khajoor)', 'category': 'Dry Fruits & Nuts', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 150.0, 'description': 'Premium soft dates 500g'},
  {'productName': 'Makhana (Fox Nuts)', 'localName': 'मखाना (Makhana)', 'category': 'Dry Fruits & Nuts', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 180.0, 'description': 'Phool makhana lotus seeds'},
  {'productName': 'Chironji', 'localName': 'चिरौंजी (Chironji)', 'category': 'Dry Fruits & Nuts', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 160.0, 'description': 'Charoli seeds for desserts'},
  {'productName': 'Kesar (Saffron)', 'localName': 'केसर (Kesar)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 1.0, 'currentPrice': 280.0, 'description': 'Pure Kashmiri saffron strands 1g'},
  {'productName': 'Poppy Seeds (Khas Khas)', 'localName': 'खसखस (Khas Khas)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 120.0, 'description': 'White poppy seeds'},
  {'productName': 'Sesame Seeds (Til)', 'localName': 'तिल (Til / Sesame)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 60.0, 'description': 'White sesame seeds'},
  {'productName': 'Melon Seeds (Magaz)', 'localName': 'मगज / खरबूजे के बीज (Magaz)', 'category': 'Dry Fruits & Nuts', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 65.0, 'description': 'Muskmelon seeds for gravy'},
  {'productName': 'Saunth (Dry Ginger Powder)', 'localName': 'सोंठ (Saunth)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 45.0, 'description': 'Dried ginger powder'},
  {'productName': 'Imli (Tamarind)', 'localName': 'इमली (Imli)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 250.0, 'currentPrice': 40.0, 'description': 'Pressed seedless tamarind'},
  {'productName': 'Kasuri Methi', 'localName': 'कसूरी मेथी (Kasuri Methi)', 'category': 'Spices', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 30.0, 'description': 'Dried fenugreek leaves 50g'},
  {'productName': 'Kalonji (Nigella Seeds)', 'localName': 'कलौंजी (Kalonji)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 35.0, 'description': 'Black nigella seeds'},
  {'productName': 'Alsi (Flax Seeds)', 'localName': 'अलसी (Flax Seeds / Alsi)', 'category': 'Dry Fruits & Nuts', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 50.0, 'description': 'Roasted flax seeds'},
  {'productName': 'Chia Seeds', 'localName': 'चिया सीड्स (Chia Seeds)', 'category': 'Dry Fruits & Nuts', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 120.0, 'description': 'Organic black chia seeds'},
  {'productName': 'Pumpkin Seeds', 'localName': 'कद्दू के बीज (Pumpkin Seeds)', 'category': 'Dry Fruits & Nuts', 'unit': 'Gram', 'quantity': 150.0, 'currentPrice': 95.0, 'description': 'Raw pumpkin seed kernels'},
  {'productName': 'Sunflower Seeds', 'localName': 'सूरजमुखी के बीज (Sunflower Seeds)', 'category': 'Dry Fruits & Nuts', 'unit': 'Gram', 'quantity': 150.0, 'currentPrice': 85.0, 'description': 'Raw sunflower seed kernels'},
];

Future<void> main() async {
  print('================================================================');
  print('Adding Kishmish, Tejpatta & Dry Fruits/Spices for User: $targetUser');
  print('================================================================\n');

  int nextId = 2000;
  try {
    final maxIdRows = await queryTarget('SELECT COALESCE(MAX(id::integer), 0) as max_id FROM wallet_products WHERE user_id = \$1', [targetUser]);
    if (maxIdRows.isNotEmpty && maxIdRows.first['max_id'] != null) {
      nextId = (int.tryParse(maxIdRows.first['max_id'].toString()) ?? 2000) + 1;
    }
  } catch (e) {
    print('Starting id at 2000: $e');
  }

  // Get existing products for user to prevent duplicates
  final existingRows = await queryTarget('SELECT LOWER(TRIM("productName")) as name FROM wallet_products WHERE user_id = \$1', [targetUser]);
  final Set<String> existingNames = existingRows.map((r) => r['name']?.toString() ?? '').toSet();

  final today = DateTime.now().toIso8601String().substring(0, 10);
  final now = DateTime.now().millisecondsSinceEpoch;
  int addedCount = 0;

  for (final item in dryFruitsAndSpices) {
    final lowerName = item['productName'].toString().trim().toLowerCase();
    if (existingNames.contains(lowerName)) {
      print('⏩ Skipping duplicate: ${item['productName']} (already exists)');
      continue;
    }

    final sql = '''
      INSERT INTO wallet_products (
        id, user_id, "productName", "localName", category, "referenceLink", "appName", 
        "priceDate", "currentPrice", "oldPrice", unit, quantity, "description", 
        active, deleted, updated_at, last_updated_by
      ) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15, \$16, \$17)
    ''';

    final params = [
      nextId++,
      targetUser,
      item['productName'],
      item['localName'],
      item['category'],
      'https://google.com/search?q=' + Uri.encodeComponent(item['productName']),
      'Dry Fruits & Spices',
      today,
      item['currentPrice'],
      (item['currentPrice'] as double) * 1.1,
      item['unit'],
      item['quantity'],
      item['description'],
      1,
      0,
      now,
      'system'
    ];

    try {
      await executeTarget(sql, params);
      addedCount++;
      print('✓ Inserted: ${item['productName']} (${item['localName']})');
    } catch (e) {
      print('❌ Error inserting ${item['productName']}: $e');
    }
  }

  print('\n================================================================');
  print('🎉 SUCCESS: Inserted $addedCount items for user $targetUser');
  print('================================================================');
}
