// ignore_for_file: avoid_print
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
  print('Seeding All Fruits into [mWallet] -> wallet_products table');
  print('================================================================\n');

  final users = await queryTarget('SELECT mobile_number FROM users LIMIT 1');
  if (users.isEmpty) {
    print('No users found in users table!');
    return;
  }
  final userId = users.first['mobile_number'].toString();
  print('Using Target User ID: $userId');

  final now = DateTime.now().millisecondsSinceEpoch;

  final fruits = [
    {'id': 'fruit_1', 'productName': 'Apple', 'localName': 'सेब (Seb)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 120},
    {'id': 'fruit_2', 'productName': 'Banana', 'localName': 'केला (Kela)', 'category': 'Fruits', 'unit': 'Dozen', 'quantity': 1, 'currentPrice': 60},
    {'id': 'fruit_3', 'productName': 'Mango', 'localName': 'आम (Aam)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 100},
    {'id': 'fruit_4', 'productName': 'Orange', 'localName': 'संतरा (Santra)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 80},
    {'id': 'fruit_5', 'productName': 'Grapes', 'localName': 'अंगूर (Angoor)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 90},
    {'id': 'fruit_6', 'productName': 'Papaya', 'localName': 'पपीता (Papita)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 50},
    {'id': 'fruit_7', 'productName': 'Guava', 'localName': 'अमरूद (Amrood)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 60},
    {'id': 'fruit_8', 'productName': 'Pomegranate', 'localName': 'अनार (Anar)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 140},
    {'id': 'fruit_9', 'productName': 'Watermelon', 'localName': 'तरबूज (Tarbooz)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1, 'currentPrice': 60},
    {'id': 'fruit_10', 'productName': 'Muskmelon', 'localName': 'खरबूजा (Kharbooza)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1, 'currentPrice': 50},
    {'id': 'fruit_11', 'productName': 'Pineapple', 'localName': 'अनानास (Ananas)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1, 'currentPrice': 80},
    {'id': 'fruit_12', 'productName': 'Sweet Lime / Mosambi', 'localName': 'मौसमी (Mosambi)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 70},
    {'id': 'fruit_13', 'productName': 'Custard Apple', 'localName': 'शरीफा / सीताफल (Sitafal)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 100},
    {'id': 'fruit_14', 'productName': 'Sapota / Chikoo', 'localName': 'चीकू (Chikoo)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 60},
    {'id': 'fruit_15', 'productName': 'Pear', 'localName': 'नाशपाती (Nashpati)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 90},
    {'id': 'fruit_16', 'productName': 'Peach', 'localName': 'आडू (Aadoo)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 120},
    {'id': 'fruit_17', 'productName': 'Plum', 'localName': 'आलूबुखारा (Aloo Bukhara)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 140},
    {'id': 'fruit_18', 'productName': 'Kiwi', 'localName': 'कीवी (Kiwi)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 3, 'currentPrice': 90},
    {'id': 'fruit_19', 'productName': 'Dragon Fruit', 'localName': 'ड्रैगन फ्रूट (Dragon Fruit)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1, 'currentPrice': 100},
    {'id': 'fruit_20', 'productName': 'Strawberry', 'localName': 'स्ट्रॉबेरी (Strawberry)', 'category': 'Fruits', 'unit': 'Box', 'quantity': 1, 'currentPrice': 80},
    {'id': 'fruit_21', 'productName': 'Blueberry', 'localName': 'ब्लूबेरी (Blueberry)', 'category': 'Fruits', 'unit': 'Box', 'quantity': 1, 'currentPrice': 150},
    {'id': 'fruit_22', 'productName': 'Blackberry', 'localName': 'जामुन (Jamun)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 120},
    {'id': 'fruit_23', 'productName': 'Raspberry', 'localName': 'रसभरी (Rasbhari)', 'category': 'Fruits', 'unit': 'Box', 'quantity': 1, 'currentPrice': 100},
    {'id': 'fruit_24', 'productName': 'Lychee', 'localName': 'लीची (Lychee)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 150},
    {'id': 'fruit_25', 'productName': 'Jackfruit (Ripe)', 'localName': 'पका कटहल (Paka Kathal)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 80},
    {'id': 'fruit_26', 'productName': 'Wood Apple', 'localName': 'बेल (Bel)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1, 'currentPrice': 40},
    {'id': 'fruit_27', 'productName': 'Dates', 'localName': 'खजूर (Khajoor)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 200},
    {'id': 'fruit_28', 'productName': 'Fig', 'localName': 'अंजीर (Anjeer)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 250},
    {'id': 'fruit_29', 'productName': 'Coconut (Water)', 'localName': 'नारियल पानी (Nariyal Paani)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1, 'currentPrice': 50},
    {'id': 'fruit_30', 'productName': 'Raw Coconut', 'localName': 'सूखा नारियल (Sookha Nariyal)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1, 'currentPrice': 30},
    {'id': 'fruit_31', 'productName': 'Apricot', 'localName': 'खुबानी (Khubani)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 180},
    {'id': 'fruit_32', 'productName': 'Cherry', 'localName': 'चेरी (Cherry)', 'category': 'Fruits', 'unit': 'Box', 'quantity': 1, 'currentPrice': 150},
    {'id': 'fruit_33', 'productName': 'Avocado', 'localName': 'एवोकैडो (Avocado)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1, 'currentPrice': 100},
    {'id': 'fruit_34', 'productName': 'Passion Fruit', 'localName': 'पैशन फ्रूट (Passion Fruit)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1, 'currentPrice': 60},
    {'id': 'fruit_35', 'productName': 'Star Fruit', 'localName': 'कम्रख (Kamrakh)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 80},
    {'id': 'fruit_36', 'productName': 'Mulberry', 'localName': 'शहतूत (Shahtoot)', 'category': 'Fruits', 'unit': 'Box', 'quantity': 1, 'currentPrice': 60},
    {'id': 'fruit_37', 'productName': 'Green Apple', 'localName': 'हरा सेब (Hara Seb)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 160},
    {'id': 'fruit_38', 'productName': 'Black Grapes', 'localName': 'काला अंगूर (Kala Angoor)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 110},
    {'id': 'fruit_39', 'productName': 'Seedless Grapes', 'localName': 'बिना बीज के अंगूर (Seedless Angoor)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 100},
    {'id': 'fruit_40', 'productName': 'Alphonso Mango', 'localName': 'हापुस आम (Hapus Aam)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 250},
    {'id': 'fruit_41', 'productName': 'Dasheri Mango', 'localName': 'दशहरी आम (Dasheri Aam)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 80},
    {'id': 'fruit_42', 'productName': 'Langra Mango', 'localName': 'लंगड़ा आम (Langra Aam)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 90},
    {'id': 'fruit_43', 'productName': 'Kesar Mango', 'localName': 'केसर आम (Kesar Aam)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 120},
    {'id': 'fruit_44', 'productName': 'Chausa Mango', 'localName': 'चौसा आम (Chausa Aam)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 90},
    {'id': 'fruit_45', 'productName': 'Red Banana', 'localName': 'लाल केला (Lal Kela)', 'category': 'Fruits', 'unit': 'Dozen', 'quantity': 1, 'currentPrice': 100},
    {'id': 'fruit_46', 'productName': 'Robusta Banana', 'localName': 'केला (Kela)', 'category': 'Fruits', 'unit': 'Dozen', 'quantity': 1, 'currentPrice': 50},
    {'id': 'fruit_47', 'productName': 'Sweet Tamarind', 'localName': 'मीठी इमली (Meethi Imli)', 'category': 'Fruits', 'unit': 'Box', 'quantity': 1, 'currentPrice': 80},
    {'id': 'fruit_48', 'productName': 'Persimmon', 'localName': 'जापानी फल (Japani Phal)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 150},
    {'id': 'fruit_49', 'productName': 'Pomelo', 'localName': 'चकोतरा (Chakotra)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1, 'currentPrice': 80},
    {'id': 'fruit_50', 'productName': 'Kinnu / Mandarin', 'localName': 'किन्नू (Kinnu)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1, 'currentPrice': 60},
  ];

  int insertedCount = 0;
  for (final f in fruits) {
    final insertSql = '''
      INSERT INTO wallet_products (id, user_id, "productName", "localName", category, unit, quantity, "currentPrice", "oldPrice", active, deleted, updated_at, last_updated_by)
      VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13)
      ON CONFLICT (user_id, id) DO UPDATE SET
        "productName" = EXCLUDED."productName",
        "localName" = EXCLUDED."localName",
        category = EXCLUDED.category,
        unit = EXCLUDED.unit,
        "currentPrice" = EXCLUDED."currentPrice",
        updated_at = EXCLUDED.updated_at;
    ''';

    final params = [
      f['id'],
      userId,
      f['productName'],
      f['localName'],
      f['category'],
      f['unit'],
      (f['quantity'] as num).toDouble(),
      (f['currentPrice'] as num).toDouble(),
      0.0,
      1,
      0,
      now,
      'fruit_seeder',
    ];

    try {
      await executeTarget(insertSql, params);
      insertedCount++;
    } catch (e) {
      print('  [!] Error inserting ${f['productName']}: $e');
    }
  }

  print('\nSuccessfully inserted/updated $insertedCount/${fruits.length} Fruits in wallet_products!');
}
