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

final List<Map<String, dynamic>> spicesList = [
  {'productName': 'Turmeric Powder (Haldi)', 'localName': 'हल्दी पाउडर (Haldi Powder)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 55.0, 'description': 'Pure aromatic turmeric powder'},
  {'productName': 'Red Chilli Powder', 'localName': 'लाल मिर्च पाउडर (Lal Mirch Powder)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 65.0, 'description': 'Spicy ground red chilli'},
  {'productName': 'Kashmiri Red Chilli Powder', 'localName': 'कश्मीरी लाल मिर्च (Kashmiri Lal Mirch)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 70.0, 'description': 'Rich red color mild chilli powder'},
  {'productName': 'Coriander Powder (Dhaniya)', 'localName': 'धनिया पाउडर (Dhaniya Powder)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 45.0, 'description': 'Aromatic coriander powder'},
  {'productName': 'Cumin Seeds (Jeera)', 'localName': 'जीरा (Jeera)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 40.0, 'description': 'Whole cumin seeds'},
  {'productName': 'Cumin Powder (Jeera Powder)', 'localName': 'जीरा पाउडर (Jeera Powder)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 48.0, 'description': 'Roasted ground cumin powder'},
  {'productName': 'Garam Masala', 'localName': 'गरम मसाला (Garam Masala)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 75.0, 'description': 'Authentic Indian spice blend'},
  {'productName': 'Black Pepper (Kali Mirch)', 'localName': 'काली मिर्च (Kali Mirch)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 85.0, 'description': 'Whole black peppercorns'},
  {'productName': 'Green Cardamom (Elaichi)', 'localName': 'छोटी इलायची (Chhoti Elaichi)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 50.0, 'currentPrice': 140.0, 'description': 'Fragrant green cardamom pods'},
  {'productName': 'Black Cardamom (Badi Elaichi)', 'localName': 'बड़ी इलायची (Badi Elaichi)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 50.0, 'currentPrice': 90.0, 'description': 'Smoky black cardamom pods'},
  {'productName': 'Cloves (Laung)', 'localName': 'लौंग (Laung)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 50.0, 'currentPrice': 65.0, 'description': 'Aromatic spice cloves'},
  {'productName': 'Cinnamon Stick (Dalchini)', 'localName': 'दालचीनी (Dalchini)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 50.0, 'currentPrice': 45.0, 'description': 'Natural cinnamon bark sticks'},
  {'productName': 'Mustard Seeds (Rai / Sarson)', 'localName': 'रागी / राय (Rai / Sarson)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 35.0, 'description': 'Black mustard seeds for tempering'},
  {'productName': 'Fenugreek Seeds (Methi Dana)', 'localName': 'मेथी दाना (Methi Dana)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 30.0, 'description': 'Whole fenugreek seeds'},
  {'productName': 'Fennel Seeds (Saunf)', 'localName': 'सौंफ (Saunf)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 50.0, 'description': 'Sweet aromatic fennel seeds'},
  {'productName': 'Carom Seeds (Ajwain)', 'localName': 'अजवाइन (Ajwain)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 35.0, 'description': 'Digestive ajwain seeds'},
  {'productName': 'Asafoetida (Hing)', 'localName': 'हींग (Hing)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 50.0, 'currentPrice': 85.0, 'description': 'Pure asafoetida powder'},
  {'productName': 'Dry Mango Powder (Amchur)', 'localName': 'अमचूर पाउडर (Amchur Powder)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 40.0, 'description': 'Tangy dry mango powder'},
  {'productName': 'Chaat Masala', 'localName': 'चाट मसाला (Chaat Masala)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 35.0, 'description': 'Tangy chaat spice mix'},
  {'productName': 'Kitchen King Masala', 'localName': 'किचन किंग मसाला (Kitchen King)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 65.0, 'description': 'All-purpose curry spice powder'},
  {'productName': 'Chole Masala', 'localName': 'छोले मसाला (Chole Masala)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 55.0, 'description': 'Special chickpea curry masala'},
  {'productName': 'Sambhar Masala', 'localName': 'सांभर मसाला (Sambhar Masala)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 55.0, 'description': 'South Indian sambhar spice blend'},
  {'productName': 'Pav Bhaji Masala', 'localName': 'पाव भाजी मसाला (Pav Bhaji Masala)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 55.0, 'description': 'Pav bhaji spice blend'},
  {'productName': 'Biryani Masala', 'localName': 'बिरयानी मसाला (Biryani Masala)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 75.0, 'description': 'Aromatic biryani spice mix'},
  {'productName': 'Bay Leaves (Tejpatta)', 'localName': 'तेजपत्ता (Tejpatta)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 50.0, 'currentPrice': 25.0, 'description': 'Fragrant dried bay leaves'},
  {'productName': 'Star Anise (Chakra Phool)', 'localName': 'चक्र फूल (Chakra Phool)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 50.0, 'currentPrice': 60.0, 'description': 'Whole star anise pods'},
  {'productName': 'Nutmeg (Jaiphal)', 'localName': 'जायफल (Jaiphal)', 'category': 'Spices', 'unit': 'Pcs', 'quantity': 2.0, 'currentPrice': 30.0, 'description': 'Whole nutmeg spice'},
  {'productName': 'Mace (Javitri)', 'localName': 'जावित्री (Javitri)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 25.0, 'currentPrice': 95.0, 'description': 'Aromatic mace flower spice'},
  {'productName': 'Black Salt (Kala Namak)', 'localName': 'काला नमक (Kala Namak)', 'category': 'Spices', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 25.0, 'description': 'Digestive black salt powder'},
  {'productName': 'Rock Salt (Sendha Namak)', 'localName': 'सेंधा नमक (Sendha Namak)', 'category': 'Spices', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 45.0, 'description': 'Pure rock salt for fasting'},
];

Future<void> main() async {
  print('================================================================');
  print('Inserting Spices for User: $targetUser');
  print('================================================================\n');

  int nextId = 1000;
  try {
    final maxIdRows = await queryTarget('SELECT COALESCE(MAX(id::integer), 0) as max_id FROM wallet_products WHERE user_id = \$1', [targetUser]);
    if (maxIdRows.isNotEmpty && maxIdRows.first['max_id'] != null) {
      nextId = (int.tryParse(maxIdRows.first['max_id'].toString()) ?? 1000) + 1;
    }
  } catch (e) {
    print('Starting id at 1000: $e');
  }

  final today = DateTime.now().toIso8601String().substring(0, 10);
  final now = DateTime.now().millisecondsSinceEpoch;
  int insertedCount = 0;

  for (final spice in spicesList) {
    final sql = '''
      INSERT INTO wallet_products (
        id, user_id, "productName", "localName", category, "referenceLink", "appName", 
        "priceDate", "currentPrice", "oldPrice", unit, quantity, "description", 
        active, deleted, updated_at, last_updated_by
      ) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15, \$16, \$17)
      ON CONFLICT (user_id, id) DO UPDATE SET
        "productName" = EXCLUDED."productName",
        "localName" = EXCLUDED."localName",
        category = EXCLUDED.category,
        "currentPrice" = EXCLUDED."currentPrice",
        unit = EXCLUDED.unit,
        quantity = EXCLUDED.quantity,
        "description" = EXCLUDED."description",
        updated_at = EXCLUDED.updated_at;
    ''';

    final params = [
      nextId++,
      targetUser,
      spice['productName'],
      spice['localName'],
      spice['category'],
      'https://google.com/search?q=' + Uri.encodeComponent(spice['productName']),
      'Spices Master',
      today,
      spice['currentPrice'],
      (spice['currentPrice'] as double) * 1.1,
      spice['unit'],
      spice['quantity'],
      spice['description'],
      1,
      0,
      now,
      'system'
    ];

    try {
      await executeTarget(sql, params);
      insertedCount++;
      print('✓ Inserted spice: ${spice['productName']} (${spice['localName']})');
    } catch (e) {
      print('❌ Error inserting ${spice['productName']}: $e');
    }
  }

  print('\n================================================================');
  print('🎉 SUCCESS: Inserted $insertedCount spices into database for user $targetUser');
  print('================================================================');
}
