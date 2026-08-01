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
  'atta': ['आटा', 'Atta'],
  'rice': ['चावल', 'Chawal'],
  'oil': ['तेल', 'Tel'],
  'salt': ['नमक', 'Namak'],
  'sugar': ['चीनी', 'Cheeni'],
  'dal': ['दाल', 'Dal'],
  'ghee': ['घी', 'Ghee'],
  'milk': ['दूध', 'Doodh'],
  'curd': ['दही', 'Dahi'],
  'paneer': ['पनीर', 'Paneer'],
  'butter': ['मक्खन', 'Makkhan'],
  'cheese': ['चीज', 'Cheese'],
  'tea': ['चाय', 'Chai'],
  'coffee': ['कॉफ़ी', 'Coffee'],
  'biscuit': ['बिस्कुट', 'Biscuit'],
  'namkeen': ['नमकीन', 'Namkeen'],
  'soap': ['साबुन', 'Sabun'],
  'shampoo': ['शैम्पू', 'Shampoo'],
  'paste': ['पेस्ट', 'Paste'],
  'cleaner': ['क्लीनर', 'Cleaner'],
  'detergent': ['डिटर्जेंट', 'Detergent'],
  'juice': ['जूस', 'Juice'],
  'water': ['पानी', 'Paani'],
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

List<Map<String, dynamic>> build10kProducts() {
  final list = <Map<String, dynamic>>[];
  int counter = 1;

  final catalogSpec = [
    {
      'category': 'Staples & Oils',
      'brands': ['Aashirvaad', 'Fortune', 'India Gate', 'Tata Sampann', 'Patanjali', 'Rajdhani', 'Dhara', 'Saffola', 'Gemini', 'Mahakosh', 'Engine', 'Anupam', 'Nature Fresh'],
      'variants': [
        {'name': 'Shuddh Chakki Atta', 'unit': 'Kg', 'qty': 5, 'price': 220.0},
        {'name': 'Select Sharbati Whole Wheat Atta', 'unit': 'Kg', 'qty': 10, 'price': 450.0},
        {'name': 'Multi-Grain Super Atta', 'unit': 'Kg', 'qty': 5, 'price': 270.0},
        {'name': 'Classic Basmati Rice', 'unit': 'Kg', 'qty': 5, 'price': 480.0},
        {'name': 'Rozana Feast Basmati Rice', 'unit': 'Kg', 'qty': 5, 'price': 380.0},
        {'name': 'Tibhar Long Grain Basmati Rice', 'unit': 'Kg', 'qty': 1, 'price': 110.0},
        {'name': 'Sona Masoori Rice Raw', 'unit': 'Kg', 'qty': 10, 'price': 510.0},
        {'name': 'Toor Dal Premium Unpolished', 'unit': 'Kg', 'qty': 1, 'price': 140.0},
        {'name': 'Moong Dal Yellow Split', 'unit': 'Kg', 'qty': 1, 'price': 125.0},
        {'name': 'Chana Dal Desi Bold', 'unit': 'Kg', 'qty': 1, 'price': 80.0},
        {'name': 'Urad Dal Whole Black', 'unit': 'Kg', 'qty': 1, 'price': 120.0},
        {'name': 'Sunlite Refined Sunflower Oil', 'unit': 'Litre', 'qty': 1, 'price': 130.0},
        {'name': 'Kachi Ghani Mustard Oil', 'unit': 'Litre', 'qty': 1, 'price': 150.0},
        {'name': 'Pure Cow Ghee Pouch', 'unit': 'Litre', 'qty': 1, 'price': 610.0},
        {'name': 'Iodized Crystal Salt', 'unit': 'Kg', 'qty': 1, 'price': 28.0},
        {'name': 'Refined White Sugar', 'unit': 'Kg', 'qty': 1, 'price': 44.0},
        {'name': 'Fine Besan Gram Flour', 'unit': 'Gram', 'qty': 500, 'price': 55.0},
        {'name': 'Maida All Purpose Flour', 'unit': 'Gram', 'qty': 500, 'price': 35.0},
        {'name': 'Sooji Coarse Semolina', 'unit': 'Gram', 'qty': 500, 'price': 35.0},
        {'name': 'Poha Thick Flattened Rice', 'unit': 'Gram', 'qty': 500, 'price': 40.0},
      ],
    },
    {
      'category': 'Snacks & Sweets',
      'brands': ['Haldiram', 'Lay\'s', 'Kurkure', 'Parle', 'Britannia', 'Cadbury', 'Bikano', 'Bikaji', 'Sunfeast', 'Oreo', 'Bingo', 'Uncle Chipps', 'Balaji', 'Cadbury Celebration'],
      'variants': [
        {'name': 'Bhujia Sev Spicy', 'unit': 'Gram', 'qty': 400, 'price': 110.0},
        {'name': 'Alu Bhujia Classic', 'unit': 'Gram', 'qty': 200, 'price': 60.0},
        {'name': 'Khatta Meetha Namkeen', 'unit': 'Gram', 'qty': 400, 'price': 95.0},
        {'name': 'Navratna Mixture Mix', 'unit': 'Gram', 'qty': 350, 'price': 90.0},
        {'name': 'Magic Masala Potato Chips', 'unit': 'Pack', 'qty': 1, 'price': 20.0},
        {'name': 'Spanish Tomato Chips', 'unit': 'Pack', 'qty': 1, 'price': 20.0},
        {'name': 'Cream & Onion Chips', 'unit': 'Pack', 'qty': 1, 'price': 20.0},
        {'name': 'Masala Munch Kurkure', 'unit': 'Pack', 'qty': 1, 'price': 20.0},
        {'name': 'Parle-G Gold Biscuits', 'unit': 'Gram', 'qty': 250, 'price': 30.0},
        {'name': 'Monaco Salted Biscuits', 'unit': 'Gram', 'qty': 200, 'price': 25.0},
        {'name': 'Good Day Cashew Cookies', 'unit': 'Gram', 'qty': 200, 'price': 40.0},
        {'name': 'Bourbon Chocolate Biscuits', 'unit': 'Gram', 'qty': 150, 'price': 35.0},
        {'name': 'Dairy Milk Silk Chocolate', 'unit': 'Gram', 'qty': 60, 'price': 80.0},
        {'name': '5 Star Chocolate Bar', 'unit': 'Pcs', 'qty': 1, 'price': 20.0},
        {'name': 'KitKat Chocolate Wafers', 'unit': 'Pcs', 'qty': 1, 'price': 30.0},
      ],
    },
    {
      'category': 'Personal Care',
      'brands': ['Dove', 'Nivea', 'Colgate', 'Dettol', 'Pears', 'Himalaya', 'Pantene', 'Head & Shoulders', 'Sunsilk', 'Tresemme', 'Lux', 'Pond\'s', 'Garnier', 'Vaseline', 'Wild Stone'],
      'variants': [
        {'name': 'Cream Beauty Bathing Soap Bar', 'unit': 'Gram', 'qty': 125, 'price': 62.0},
        {'name': 'Pure & Gentle Soap', 'unit': 'Gram', 'qty': 125, 'price': 58.0},
        {'name': 'Original Germ Protection Soap', 'unit': 'Gram', 'qty': 125, 'price': 45.0},
        {'name': 'MaxFresh Gel Toothpaste', 'unit': 'Gram', 'qty': 150, 'price': 110.0},
        {'name': 'Strong Teeth Calcium Toothpaste', 'unit': 'Gram', 'qty': 200, 'price': 115.0},
        {'name': 'Purifying Neem Face Wash', 'unit': 'Ml', 'qty': 100, 'price': 140.0},
        {'name': 'Soft Light Cream', 'unit': 'Ml', 'qty': 100, 'price': 190.0},
        {'name': 'Anti-Hairfall Shampoo', 'unit': 'Ml', 'qty': 340, 'price': 260.0},
        {'name': 'Smooth & Silky Shampoo', 'unit': 'Ml', 'qty': 340, 'price': 270.0},
        {'name': 'Body Wash Shower Gel', 'unit': 'Ml', 'qty': 250, 'price': 220.0},
        {'name': 'Intense Moisture Body Lotion', 'unit': 'Ml', 'qty': 400, 'price': 310.0},
      ],
    },
    {
      'category': 'Dairy & Bakery',
      'brands': ['Amul', 'Mother Dairy', 'Britannia', 'Nestlé', 'Milky Mist', 'Harvest Gold', 'English Oven', 'Gowardhan', 'Nandini', 'Epigamia'],
      'variants': [
        {'name': 'Taaza T-Special Milk Poly Pack', 'unit': 'Litre', 'qty': 1, 'price': 54.0},
        {'name': 'Gold Full Cream Fresh Milk', 'unit': 'Litre', 'qty': 1, 'price': 66.0},
        {'name': 'Fresh Malai Paneer Block', 'unit': 'Gram', 'qty': 200, 'price': 90.0},
        {'name': 'Pasteurised Salted Butter Block', 'unit': 'Gram', 'qty': 100, 'price': 58.0},
        {'name': 'Processed Cheese Slices Pack', 'unit': 'Gram', 'qty': 200, 'price': 145.0},
        {'name': 'Masti Thick Dahi Curd Tub', 'unit': 'Gram', 'qty': 400, 'price': 45.0},
        {'name': 'Brown Whole Wheat Bread', 'unit': 'Gram', 'qty': 400, 'price': 45.0},
        {'name': 'White Sandwich Bread', 'unit': 'Gram', 'qty': 400, 'price': 35.0},
        {'name': 'Fresh Fruit Cake Bar', 'unit': 'Gram', 'qty': 150, 'price': 40.0},
        {'name': 'Farm Fresh Eggs Box', 'unit': 'Pcs', 'qty': 6, 'price': 48.0},
      ],
    },
    {
      'category': 'Household Care',
      'brands': ['Surf Excel', 'Vim', 'Harpic', 'Ariel', 'Colin', 'Lizol', 'Comfort', 'Tide', 'Rin', 'Good Knight', 'Domex', 'Hit', 'All Out'],
      'variants': [
        {'name': 'Easy Wash Detergent Powder', 'unit': 'Kg', 'qty': 1, 'price': 140.0},
        {'name': 'Matic Front Load Detergent', 'unit': 'Kg', 'qty': 1, 'price': 240.0},
        {'name': 'Dishwash Gel Lemon Bottle', 'unit': 'Ml', 'qty': 500, 'price': 120.0},
        {'name': 'Dishwash Bar Green Tub', 'unit': 'Gram', 'qty': 500, 'price': 45.0},
        {'name': 'Disinfectant Toilet Cleaner Blue', 'unit': 'Ml', 'qty': 500, 'price': 95.0},
        {'name': 'Disinfectant Floor Cleaner Citrus', 'unit': 'Litre', 'qty': 1, 'price': 190.0},
        {'name': 'Glass & Surface Cleaner Spray', 'unit': 'Ml', 'qty': 500, 'price': 105.0},
        {'name': 'Fabric Conditioner After Wash', 'unit': 'Ml', 'qty': 860, 'price': 235.0},
        {'name': 'Gold Flash Mosquito Refill', 'unit': 'Pcs', 'qty': 2, 'price': 150.0},
      ],
    },
    {
      'category': 'Beverages',
      'brands': ['Tata Tea', 'Red Label', 'Nescafe', 'Taj Mahal', 'Wagh Bakri', 'Bru', 'Coca-Cola', 'Pepsi', 'Real', 'Tropicana', 'Paper Boat', 'Thums Up', 'Sprite', 'Maaza', 'Red Bull'],
      'variants': [
        {'name': 'Gold Leaf Tea Pack', 'unit': 'Gram', 'qty': 500, 'price': 310.0},
        {'name': 'Natural Care Tea Pack', 'unit': 'Gram', 'qty': 500, 'price': 330.0},
        {'name': 'Classic Instant Coffee Jar', 'unit': 'Gram', 'qty': 100, 'price': 340.0},
        {'name': 'Gold Blend Instant Coffee', 'unit': 'Gram', 'qty': 50, 'price': 290.0},
        {'name': 'Carbonated Soft Drink Bottle', 'unit': 'Litre', 'qty': 1.25, 'price': 65.0},
        {'name': 'Zero Sugar Soft Drink', 'unit': 'Ml', 'qty': 750, 'price': 45.0},
        {'name': '100% Mixed Fruit Juice Pack', 'unit': 'Litre', 'qty': 1, 'price': 130.0},
        {'name': 'Guava Nectar Fruit Juice', 'unit': 'Litre', 'qty': 1, 'price': 120.0},
        {'name': 'Aamras Mango Drink Pouch', 'unit': 'Ml', 'qty': 200, 'price': 30.0},
      ],
    },
  ];

  for (final spec in catalogSpec) {
    final catName = spec['category'] as String;
    final brands = spec['brands'] as List<String>;
    final variants = spec['variants'] as List<Map<String, dynamic>>;

    for (final brand in brands) {
      for (final v in variants) {
        for (int i = 1; i <= 35; i++) {
          final prodName = '$brand ${v['name']} Pack #$i';
          final localName = generateLocalName(prodName);

          list.add({
            'id': '${10000 + counter}',
            'productName': prodName,
            'localName': localName,
            'category': catName,
            'unit': v['unit'],
            'quantity': (v['qty'] as num).toDouble(),
            'currentPrice': (v['price'] as num).toDouble() + (i * 0.5),
            'oldPrice': (v['price'] as num).toDouble(),
            'appName': 'Zepto',
            'referenceLink': 'https://zepto.co/search?q=${Uri.encodeComponent(prodName)}',
          });

          counter++;
          if (list.length >= 10000) break;
        }
        if (list.length >= 10000) break;
      }
      if (list.length >= 10000) break;
    }
    if (list.length >= 10000) break;
  }

  print('Generated ${list.length} products specifically for user $targetUser.');
  return list;
}

Future<void> main() async {
  print('================================================================');
  print('Seeding 10,000+ Standardized Products for User: $targetUser');
  print('================================================================\n');

  final products = build10kProducts();

  // Clear existing items for user 7400700500 first if needed
  print('Cleaning existing records for user $targetUser...');
  await executeTarget('DELETE FROM wallet_products WHERE user_id = \$1', [targetUser]);

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
      buffer.write('(\$$paramIndex, \$${paramIndex + 1}, \$${paramIndex + 2}, \$${paramIndex + 3}, \$${paramIndex + 4}, \$${paramIndex + 5}, \$${paramIndex + 6}, \$${paramIndex + 7}, \$${paramIndex + 8}, \$${paramIndex + 9}, \$${paramIndex + 10}, 1, 0, \$${paramIndex + 11}, \'user_7400_10k_seeder\')');

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
  print('Successfully inserted $insertedCount products for User: $targetUser in [mWallet]!');
  print('================================================================');
}
