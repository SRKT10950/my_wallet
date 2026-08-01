// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

const String targetApiUrl = 'https://db.mhservice.co.in/api/db/mWallet/query';
const String targetApiKey = 'hs_live_8cxzSYAq9aUv79HxDbADCdJ23yLtIWhQ';
const String targetUser = '7400700500';

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

Map<String, List<String>> hinglishDict = {
  'rice': ['चावल', 'Chawal'],
  'atta': ['आटा', 'Atta'],
  'dal': ['दाल', 'Dal'],
  'oil': ['तेल', 'Tel'],
  'salt': ['नमक', 'Namak'],
  'sugar': ['चीनी', 'Cheeni'],
  'potato': ['आलू', 'Aloo'],
  'tomato': ['टमाटर', 'Tamatar'],
  'onion': ['प्याज', 'Pyaz'],
  'garlic': ['लहसुन', 'Lahsun'],
  'ginger': ['अदरक', 'Adrak'],
  'apple': ['सेब', 'Seb'],
  'banana': ['केला', 'Kela'],
  'mango': ['आम', 'Aam'],
  'milk': ['दूध', 'Doodh'],
  'paneer': ['पनीर', 'Paneer'],
  'butter': ['मक्खन', 'Makkhan'],
  'pen': ['पेन', 'Pen'],
  'pencil': ['पेंसिल', 'Pencil'],
  'notebook': ['नोटबुक', 'Notebook'],
  'paper': ['पेपर', 'Paper'],
  'soap': ['साबुन', 'Sabun'],
  'shampoo': ['शैम्पू', 'Shampoo'],
  'tea': ['चाय', 'Chai'],
  'coffee': ['कॉफ़ी', 'Coffee'],
  'juice': ['जूस', 'Juice'],
  'drink': ['ड्रिंक', 'Drink'],
  'biscuit': ['बिस्कुट', 'Biscuit'],
  'chips': ['चिप्स', 'Chips'],
  'chocolate': ['चॉकलेट', 'Chocolate'],
};

String generateLocalName(String englishName) {
  final lower = englishName.toLowerCase();
  for (final key in hinglishDict.keys) {
    if (lower.contains(key)) {
      final dev = hinglishDict[key]![0];
      final roman = hinglishDict[key]![1];
      return '$dev ($roman)';
    }
  }
  return '';
}

List<Map<String, dynamic>> generate10kProductsForUser() {
  final products = <Map<String, dynamic>>[];
  int idCounter = 10001;

  final categoriesSpec = [
    {
      'category': 'Grocery',
      'items': [
        {'base': 'Basmati Rice Premium', 'unit': 'Kg', 'qty': 1, 'price': 110.0, 'sizes': [1, 2, 5, 10]},
        {'base': 'Sona Masoori Rice Raw', 'unit': 'Kg', 'qty': 1, 'price': 55.0, 'sizes': [1, 5, 10, 25]},
        {'base': 'Fortune Sunlite Refined Oil', 'unit': 'Litre', 'qty': 1, 'price': 135.0, 'sizes': [1, 2, 5]},
        {'base': 'Mustard Oil Kachi Ghani', 'unit': 'Litre', 'qty': 1, 'price': 150.0, 'sizes': [1, 2, 5]},
        {'base': 'Aashirvaad Shuddh Chakki Atta', 'unit': 'Kg', 'qty': 5, 'price': 225.0, 'sizes': [1, 5, 10]},
        {'base': 'Tata Salt Iodized Crystal', 'unit': 'Kg', 'qty': 1, 'price': 28.0, 'sizes': [1, 2]},
        {'base': 'Refined White Sugar', 'unit': 'Kg', 'qty': 1, 'price': 44.0, 'sizes': [1, 2, 5]},
        {'base': 'Toor Dal Premium Unpolished', 'unit': 'Kg', 'qty': 1, 'price': 140.0, 'sizes': [1, 2, 5]},
        {'base': 'Moong Dal Yellow Split', 'unit': 'Kg', 'qty': 1, 'price': 125.0, 'sizes': [1, 2, 5]},
        {'base': 'Chana Dal Desi Bold', 'unit': 'Kg', 'qty': 1, 'price': 80.0, 'sizes': [1, 2, 5]},
        {'base': 'Urad Dal Whole Black', 'unit': 'Kg', 'qty': 1, 'price': 130.0, 'sizes': [1, 2, 5]},
        {'base': 'Rajma Red Kidney Beans', 'unit': 'Kg', 'qty': 1, 'price': 140.0, 'sizes': [1, 2]},
        {'base': 'Kabuli Chana Chickpeas', 'unit': 'Kg', 'qty': 1, 'price': 130.0, 'sizes': [1, 2]},
        {'base': 'Besan Gram Flour Fine', 'unit': 'Gram', 'qty': 500, 'price': 55.0, 'sizes': [250, 500, 1000]},
        {'base': 'Maida All Purpose Flour', 'unit': 'Gram', 'qty': 500, 'price': 35.0, 'sizes': [500, 1000]},
        {'base': 'Sooji Coarse Semolina', 'unit': 'Gram', 'qty': 500, 'price': 35.0, 'sizes': [500, 1000]},
        {'base': 'Poha Thick Flattened Rice', 'unit': 'Gram', 'qty': 500, 'price': 40.0, 'sizes': [500, 1000]},
        {'base': 'Ghee Pure Cow Pouch', 'unit': 'Litre', 'qty': 1, 'price': 620.0, 'sizes': [1, 2]},
      ]
    },
    {
      'category': 'Vegetable',
      'items': [
        {'base': 'Potato (Aloo)', 'unit': 'Kg', 'qty': 1, 'price': 24.0, 'sizes': [1, 2, 5]},
        {'base': 'Tomato (Tamatar)', 'unit': 'Kg', 'qty': 1, 'price': 35.0, 'sizes': [1, 2, 3]},
        {'base': 'Onion (Pyaz)', 'unit': 'Kg', 'qty': 1, 'price': 30.0, 'sizes': [1, 2, 5]},
        {'base': 'Garlic (Lahsun)', 'unit': 'Gram', 'qty': 250, 'price': 50.0, 'sizes': [100, 250, 500]},
        {'base': 'Ginger (Adrak)', 'unit': 'Gram', 'qty': 250, 'price': 30.0, 'sizes': [100, 250, 500]},
        {'base': 'Green Chilli (Hari Mirch)', 'unit': 'Gram', 'qty': 250, 'price': 20.0, 'sizes': [100, 250, 500]},
        {'base': 'Lemon (Nimbu)', 'unit': 'Pcs', 'qty': 4, 'price': 20.0, 'sizes': [2, 4, 10]},
        {'base': 'Spinach (Palak)', 'unit': 'Pack', 'qty': 1, 'price': 25.0, 'sizes': [1, 2]},
        {'base': 'Cauliflower (Phool Gobi)', 'unit': 'Pcs', 'qty': 1, 'price': 30.0, 'sizes': [1, 2]},
        {'base': 'Cabbage (Patta Gobi)', 'unit': 'Pcs', 'qty': 1, 'price': 25.0, 'sizes': [1, 2]},
        {'base': 'Brinjal (Baingan)', 'unit': 'Kg', 'qty': 1, 'price': 40.0, 'sizes': [1, 2]},
        {'base': 'Lady Finger (Bhindi)', 'unit': 'Kg', 'qty': 1, 'price': 45.0, 'sizes': [1, 2]},
        {'base': 'Green Peas (Matar)', 'unit': 'Kg', 'qty': 1, 'price': 60.0, 'sizes': [1, 2]},
        {'base': 'Cucumber (Kheera)', 'unit': 'Kg', 'qty': 1, 'price': 30.0, 'sizes': [1, 2]},
        {'base': 'Carrot (Gajar)', 'unit': 'Kg', 'qty': 1, 'price': 40.0, 'sizes': [1, 2]},
        {'base': 'Bottle Gourd (Lauki)', 'unit': 'Pcs', 'qty': 1, 'price': 30.0, 'sizes': [1, 2]},
      ]
    },
    {
      'category': 'Fruits',
      'items': [
        {'base': 'Apple Fresh Washington/Kashmir', 'unit': 'Kg', 'qty': 1, 'price': 95.0, 'sizes': [1, 2]},
        {'base': 'Banana Robusta Yellow', 'unit': 'Dozen', 'qty': 1, 'price': 45.0, 'sizes': [1, 2]},
        {'base': 'Mango Alphonso / Dasheri', 'unit': 'Kg', 'qty': 1, 'price': 85.0, 'sizes': [1, 2, 5]},
        {'base': 'Orange Nagpur Juicy', 'unit': 'Kg', 'qty': 1, 'price': 60.0, 'sizes': [1, 2]},
        {'base': 'Grapes Seedless Green', 'unit': 'Kg', 'qty': 1, 'price': 80.0, 'sizes': [1, 2]},
        {'base': 'Papaya Ripe Sweet', 'unit': 'Kg', 'qty': 1, 'price': 45.0, 'sizes': [1, 2]},
        {'base': 'Guava Fresh Pink/White', 'unit': 'Kg', 'qty': 1, 'price': 50.0, 'sizes': [1, 2]},
        {'base': 'Pomegranate Anar Sweet', 'unit': 'Kg', 'qty': 1, 'price': 130.0, 'sizes': [1, 2]},
        {'base': 'Watermelon Red Giant', 'unit': 'Pcs', 'qty': 1, 'price': 60.0, 'sizes': [1, 2]},
        {'base': 'Pineapple Fresh Sweet', 'unit': 'Pcs', 'qty': 1, 'price': 80.0, 'sizes': [1, 2]},
        {'base': 'Kiwi Fresh Imported', 'unit': 'Pcs', 'qty': 3, 'price': 90.0, 'sizes': [3, 6]},
        {'base': 'Strawberry Fresh Pack', 'unit': 'Box', 'qty': 1, 'price': 80.0, 'sizes': [1, 2]},
      ]
    },
    {
      'category': 'Stationery',
      'items': [
        {'base': 'Classmate Long Book Rule A4', 'unit': 'Pcs', 'qty': 1, 'price': 65.0, 'sizes': [1, 2, 6, 12]},
        {'base': 'Classmate Spiral Bound Notebook', 'unit': 'Pcs', 'qty': 1, 'price': 95.0, 'sizes': [1, 2, 5]},
        {'base': 'Reynolds Ball Pen Blue/Black', 'unit': 'Pack', 'qty': 5, 'price': 50.0, 'sizes': [5, 10, 20]},
        {'base': 'Cello Butterflow Gel Pen', 'unit': 'Pcs', 'qty': 1, 'price': 15.0, 'sizes': [1, 5, 10]},
        {'base': 'Natraj HB Pencils Set', 'unit': 'Box', 'qty': 1, 'price': 60.0, 'sizes': [1, 2, 5]},
        {'base': 'Apsara Platinum Extra Dark Pencils', 'unit': 'Box', 'qty': 1, 'price': 75.0, 'sizes': [1, 2, 5]},
        {'base': 'Camlin Oil Pastels Colors', 'unit': 'Box', 'qty': 1, 'price': 110.0, 'sizes': [1, 2]},
        {'base': 'Camlin Water Color Kit 12 Shades', 'unit': 'Box', 'qty': 1, 'price': 140.0, 'sizes': [1, 2]},
        {'base': 'Classmate Geometry Mathematical Box', 'unit': 'Pcs', 'qty': 1, 'price': 125.0, 'sizes': [1, 2]},
        {'base': 'Fevicol MR Synthetic Glue', 'unit': 'Gram', 'qty': 100, 'price': 45.0, 'sizes': [50, 100, 200]},
        {'base': 'A4 Printer Paper Ream 500 Sheets', 'unit': 'Pack', 'qty': 1, 'price': 280.0, 'sizes': [1, 2, 5]},
        {'base': 'Sticky Notes Yellow Pad 100 Sheets', 'unit': 'Pcs', 'qty': 1, 'price': 40.0, 'sizes': [1, 3, 5]},
      ]
    },
    {
      'category': 'Personal Care',
      'items': [
        {'base': 'Dove Beauty Cream Soap Bar', 'unit': 'Gram', 'qty': 125, 'price': 62.0, 'sizes': [125, 375]},
        {'base': 'Dettol Original Bathing Soap', 'unit': 'Gram', 'qty': 125, 'price': 45.0, 'sizes': [125, 375]},
        {'base': 'Pears Pure & Gentle Transparent Soap', 'unit': 'Gram', 'qty': 125, 'price': 58.0, 'sizes': [125, 375]},
        {'base': 'Colgate MaxFresh Gel Toothpaste', 'unit': 'Gram', 'qty': 150, 'price': 110.0, 'sizes': [150, 300]},
        {'base': 'Sensodyne Toothpaste Fluoride', 'unit': 'Gram', 'qty': 100, 'price': 160.0, 'sizes': [100, 200]},
        {'base': 'Himalaya Purifying Neem Face Wash', 'unit': 'Ml', 'qty': 100, 'price': 140.0, 'sizes': [100, 200]},
        {'base': 'Nivea Soft Light Moisturiser Cream', 'unit': 'Ml', 'qty': 100, 'price': 190.0, 'sizes': [100, 200, 300]},
        {'base': 'Pantene Hairfall Control Shampoo', 'unit': 'Ml', 'qty': 340, 'price': 260.0, 'sizes': [180, 340, 650]},
        {'base': 'Head & Shoulders Anti-Dandruff Shampoo', 'unit': 'Ml', 'qty': 340, 'price': 280.0, 'sizes': [180, 340, 650]},
        {'base': 'Tresemme Keratin Smooth Shampoo', 'unit': 'Ml', 'qty': 340, 'price': 310.0, 'sizes': [340, 580]},
      ]
    },
    {
      'category': 'Snacks',
      'items': [
        {'base': 'Haldiram Alu Bhujia Namkeen', 'unit': 'Gram', 'qty': 200, 'price': 60.0, 'sizes': [150, 200, 400, 1000]},
        {'base': 'Lay\'s Potato Chips Magic Masala', 'unit': 'Pack', 'qty': 1, 'price': 20.0, 'sizes': [1, 2, 5]},
        {'base': 'Kurkure Masala Munch Crunchy', 'unit': 'Pack', 'qty': 1, 'price': 20.0, 'sizes': [1, 2, 5]},
        {'base': 'Parle-G Gold Glucose Biscuits', 'unit': 'Gram', 'qty': 250, 'price': 30.0, 'sizes': [250, 500, 1000]},
        {'base': 'Britannia Good Day Cashew Cookies', 'unit': 'Gram', 'qty': 200, 'price': 40.0, 'sizes': [200, 400]},
        {'base': 'Cadbury Dairy Milk Silk Chocolate', 'unit': 'Gram', 'qty': 60, 'price': 80.0, 'sizes': [60, 150]},
        {'base': 'KitKat Chocolate Crisp Wafer', 'unit': 'Pcs', 'qty': 1, 'price': 30.0, 'sizes': [1, 2, 5]},
        {'base': 'Oreo Chocolate Cream Biscuit', 'unit': 'Gram', 'qty': 120, 'price': 35.0, 'sizes': [120, 300]},
      ]
    },
    {
      'category': 'Drink',
      'items': [
        {'base': 'Tata Tea Gold Leaf Premium', 'unit': 'Gram', 'qty': 500, 'price': 310.0, 'sizes': [250, 500, 1000]},
        {'base': 'Red Label Natural Care Tea', 'unit': 'Gram', 'qty': 500, 'price': 320.0, 'sizes': [250, 500, 1000]},
        {'base': 'Nescafe Classic Instant Coffee', 'unit': 'Gram', 'qty': 100, 'price': 340.0, 'sizes': [50, 100, 200]},
        {'base': 'Bru Instant Coffee Blend', 'unit': 'Gram', 'qty': 100, 'price': 210.0, 'sizes': [100, 200]},
        {'base': 'Coca-Cola Soft Drink Bottle', 'unit': 'Litre', 'qty': 1.25, 'price': 65.0, 'sizes': [750, 1250, 2000]},
        {'base': 'Pepsi Carbonated Soft Drink', 'unit': 'Litre', 'qty': 1.25, 'price': 65.0, 'sizes': [750, 1250, 2000]},
        {'base': 'Sprite Lemon Soft Drink', 'unit': 'Litre', 'qty': 1.25, 'price': 65.0, 'sizes': [750, 1250, 2000]},
        {'base': 'Real 100% Mixed Fruit Juice', 'unit': 'Litre', 'qty': 1, 'price': 130.0, 'sizes': [1, 2]},
        {'base': 'Paper Boat Aamras Mango Drink', 'unit': 'Ml', 'qty': 200, 'price': 30.0, 'sizes': [200, 1000]},
        {'base': 'Red Bull Energy Drink Can', 'unit': 'Ml', 'qty': 250, 'price': 125.0, 'sizes': [250, 4 * 250]},
      ]
    },
    {
      'category': 'General',
      'items': [
        {'base': 'Amul Pasteurised Salted Butter', 'unit': 'Gram', 'qty': 100, 'price': 58.0, 'sizes': [100, 500]},
        {'base': 'Amul Taaza T-Special Fresh Milk', 'unit': 'Litre', 'qty': 1, 'price': 54.0, 'sizes': [500, 1000]},
        {'base': 'Surf Excel Easy Wash Powder', 'unit': 'Kg', 'qty': 1, 'price': 140.0, 'sizes': [1, 2, 5]},
        {'base': 'Vim Dishwash Gel Lemon Bottle', 'unit': 'Ml', 'qty': 500, 'price': 120.0, 'sizes': [250, 500, 1000]},
        {'base': 'Harpic Toilet Cleaner Liquid', 'unit': 'Ml', 'qty': 500, 'price': 95.0, 'sizes': [500, 1000]},
        {'base': 'Lizol Disinfectant Floor Cleaner', 'unit': 'Litre', 'qty': 1, 'price': 190.0, 'sizes': [1, 2]},
        {'base': 'Good Knight Mosquito Refill Twin', 'unit': 'Pcs', 'qty': 2, 'price': 150.0, 'sizes': [1, 2]},
        {'base': 'Comfort After Wash Fabric Conditioner', 'unit': 'Ml', 'qty': 860, 'price': 235.0, 'sizes': [400, 860]},
      ]
    },
  ];

  for (final spec in categoriesSpec) {
    final catName = spec['category'] as String;
    final items = spec['items'] as List<Map<String, dynamic>>;

    for (final item in items) {
      final baseName = item['base'] as String;
      final sizes = item['sizes'] as List<num>;
      final baseUnit = item['unit'] as String;
      final basePrice = (item['price'] as num).toDouble();

      for (final sz in sizes) {
        for (int v = 1; v <= 50; v++) {
          final prodName = '$baseName ($sz $baseUnit) #$v';
          final localName = generateLocalName(prodName);
          final price = basePrice * (sz / (item['qty'] as num)) + (v * 0.2);

          products.add({
            'id': idCounter.toString(),
            'user_id': targetUser,
            'productName': prodName,
            'localName': localName,
            'category': catName,
            'unit': baseUnit,
            'quantity': sz.toDouble(),
            'currentPrice': double.parse(price.toStringAsFixed(2)),
            'oldPrice': double.parse(price.toStringAsFixed(2)),
            'appName': 'Zepto',
            'referenceLink': 'https://zepto.co/search?q=${Uri.encodeComponent(prodName)}',
          });

          idCounter++;
          if (products.length >= 10000) break;
        }
        if (products.length >= 10000) break;
      }
      if (products.length >= 10000) break;
    }
    if (products.length >= 10000) break;
  }

  print('Generated ${products.length} product rows exclusively for user $targetUser.');
  return products;
}

Future<void> main() async {
  print('================================================================');
  print('Deleting Products for User $targetUser & Seeding 10,000+ Items under Exact Categories');
  print('================================================================\n');

  // 1. DELETE ALL PRODUCTS FOR USER 7400700500
  print('Deleting all records from wallet_products for user $targetUser...');
  await executeTarget('DELETE FROM wallet_products WHERE user_id = \$1;', [targetUser]);
  print('Successfully cleared previous products for user $targetUser!\n');

  final products = generate10kProductsForUser();

  int insertedCount = 0;
  const batchSize = 100;
  final now = DateTime.now().millisecondsSinceEpoch;

  for (int i = 0; i < products.length; i += batchSize) {
    final end = (i + batchSize < products.length) ? i + batchSize : products.length;
    final chunk = products.sublist(i, end);

    final buffer = StringBuffer();
    final params = <dynamic>[];
    int paramIndex = 1;

    buffer.write('''
      INSERT INTO wallet_products (id, user_id, "productName", "localName", category, unit, quantity, "currentPrice", "oldPrice", "appName", "referenceLink", active, deleted, updated_at, last_updated_by)
      VALUES 
    ''');

    for (int j = 0; j < chunk.length; j++) {
      final p = chunk[j];
      if (j > 0) buffer.write(', ');
      buffer.write('(\$$paramIndex, \$${paramIndex + 1}, \$${paramIndex + 2}, \$${paramIndex + 3}, \$${paramIndex + 4}, \$${paramIndex + 5}, \$${paramIndex + 6}, \$${paramIndex + 7}, \$${paramIndex + 8}, \$${paramIndex + 9}, \$${paramIndex + 10}, 1, 0, \$${paramIndex + 11}, \'custom_10k_seeder_user\')');

      params.addAll([
        p['id'],
        targetUser,
        p['productName'],
        p['localName'],
        p['category'],
        p['unit'],
        p['quantity'],
        p['currentPrice'],
        p['oldPrice'],
        p['appName'],
        p['referenceLink'],
        now,
      ]);

      paramIndex += 12;
    }

    try {
      await executeTarget(buffer.toString(), params);
      insertedCount += chunk.length;
      if (insertedCount % 1000 == 0 || end == products.length) {
        print('  [✓] Inserted $insertedCount / ${products.length} products for user $targetUser...');
      }
    } catch (e) {
      print('  [!] Batch Error at index $i: $e');
    }
  }

  print('\n================================================================');
  print('Successfully populated $insertedCount products specifically for User: $targetUser in [mWallet]!');
  print('================================================================');
}
