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

final List<Map<String, dynamic>> cleanEssentialProducts = [
  // --- STAPLES & RICE & DALS & OILS ---
  {'name': 'Basmati Rice', 'local': 'बासमती चावल (Basmati Chawal)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 1.0, 'price': 110.0},
  {'name': 'Rice (Standard)', 'local': 'चावल (Chawal)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 1.0, 'price': 55.0},
  {'name': 'Sona Masoori Rice', 'local': 'सोना मसूरी चावल (Sona Masoori Chawal)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 1.0, 'price': 60.0},
  {'name': 'Brown Rice', 'local': 'ब्राउन राइस (Brown Rice)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 1.0, 'price': 90.0},
  {'name': 'Wheat Atta (Aashirvaad)', 'local': 'गेहूं का आटा (Gehun ka Atta)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 5.0, 'price': 225.0},
  {'name': 'Multigrain Atta', 'local': 'मल्टीग्रेन आटा (Multigrain Atta)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 5.0, 'price': 275.0},
  {'name': 'Besan (Gram Flour)', 'local': 'बेसन (Besan)', 'category': 'Staples & Oils', 'unit': 'Gram', 'qty': 500.0, 'price': 55.0},
  {'name': 'Maida (All Purpose Flour)', 'local': 'मैदा (Maida)', 'category': 'Staples & Oils', 'unit': 'Gram', 'qty': 500.0, 'price': 35.0},
  {'name': 'Sooji (Rava)', 'local': 'सूजी (Sooji)', 'category': 'Staples & Oils', 'unit': 'Gram', 'qty': 500.0, 'price': 35.0},
  {'name': 'Poha (Flattened Rice)', 'local': 'पोहा (Poha)', 'category': 'Staples & Oils', 'unit': 'Gram', 'qty': 500.0, 'price': 40.0},
  {'name': 'Toor Dal (Arhar)', 'local': 'तुअर दाल (Toor Dal)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 1.0, 'price': 140.0},
  {'name': 'Moong Dal (Yellow)', 'local': 'मूंग दाल (Moong Dal)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 1.0, 'price': 125.0},
  {'name': 'Chana Dal', 'local': 'चना दाल (Chana Dal)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 1.0, 'price': 80.0},
  {'name': 'Urad Dal (Split)', 'local': 'उड़द दाल (Urad Dal)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 1.0, 'price': 130.0},
  {'name': 'Rajma (Red Kidney Beans)', 'local': 'राजमा (Rajma)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 1.0, 'price': 140.0},
  {'name': 'Kabuli Chana (Chickpeas)', 'local': 'काबूली चना (Kabuli Chana)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 1.0, 'price': 130.0},
  {'name': 'Refined Sunflower Oil', 'local': 'रिफाइंड तेल (Refined Tel)', 'category': 'Staples & Oils', 'unit': 'Litre', 'qty': 1.0, 'price': 135.0},
  {'name': 'Mustard Oil (Kachi Ghani)', 'local': 'सरसों का तेल (Sarson ka Tel)', 'category': 'Staples & Oils', 'unit': 'Litre', 'qty': 1.0, 'price': 150.0},
  {'name': 'Pure Cow Ghee', 'local': 'गाय का शुद्ध घी (Gai ka Ghee)', 'category': 'Staples & Oils', 'unit': 'Litre', 'qty': 1.0, 'price': 620.0},
  {'name': 'Tata Salt', 'local': 'टाटा नमक (Tata Namak)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 1.0, 'price': 28.0},
  {'name': 'Sugar (White)', 'local': 'चीनी (Cheeni)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 1.0, 'price': 44.0},
  {'name': 'Jaggery (Gud)', 'local': 'गुड़ (Gud)', 'category': 'Staples & Oils', 'unit': 'Kg', 'qty': 1.0, 'price': 60.0},

  // --- VEGETABLES ---
  {'name': 'Potato', 'local': 'आलू (Aloo)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 24.0},
  {'name': 'Tomato', 'local': 'टमाटर (Tamatar)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 35.0},
  {'name': 'Onion', 'local': 'प्याज (Pyaz)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 30.0},
  {'name': 'Garlic', 'local': 'लहसुन (Lahsun)', 'category': 'Vegetable', 'unit': 'Gram', 'qty': 250.0, 'price': 50.0},
  {'name': 'Ginger', 'local': 'अदरक (Adrak)', 'category': 'Vegetable', 'unit': 'Gram', 'qty': 250.0, 'price': 30.0},
  {'name': 'Green Chilli', 'local': 'हरी मिर्च (Hari Mirch)', 'category': 'Vegetable', 'unit': 'Gram', 'qty': 250.0, 'price': 20.0},
  {'name': 'Lemon', 'local': 'नींबू (Nimbu)', 'category': 'Vegetable', 'unit': 'Pcs', 'qty': 4.0, 'price': 20.0},
  {'name': 'Spinach (Palak)', 'local': 'पालक (Palak)', 'category': 'Vegetable', 'unit': 'Pack', 'qty': 1.0, 'price': 25.0},
  {'name': 'Cauliflower', 'local': 'फूलगोभी (Phool Gobi)', 'category': 'Vegetable', 'unit': 'Pcs', 'qty': 1.0, 'price': 30.0},
  {'name': 'Cabbage', 'local': 'पत्तागोभी (Patta Gobi)', 'category': 'Vegetable', 'unit': 'Pcs', 'qty': 1.0, 'price': 25.0},
  {'name': 'Brinjal (Baingan)', 'local': 'बैंगन (Baingan)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 40.0},
  {'name': 'Lady Finger (Bhindi)', 'local': 'भिंडी (Bhindi)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 45.0},
  {'name': 'Green Peas (Matar)', 'local': 'हरी मटर (Hari Matar)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 60.0},
  {'name': 'Cucumber (Kheera)', 'local': 'खीरा (Kheera)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 30.0},
  {'name': 'Carrot (Gajar)', 'local': 'गाजर (Gajar)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 40.0},
  {'name': 'Bottle Gourd (Lauki)', 'local': 'लौकी (Lauki)', 'category': 'Vegetable', 'unit': 'Pcs', 'qty': 1.0, 'price': 30.0},

  // --- FRUITS ---
  {'name': 'Apple', 'local': 'सेब (Seb)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 95.0},
  {'name': 'Banana', 'local': 'केला (Kela)', 'category': 'Fruits', 'unit': 'Dozen', 'qty': 1.0, 'price': 45.0},
  {'name': 'Mango (Alphonso / Dasheri)', 'local': 'आम (Aam)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 85.0},
  {'name': 'Orange', 'local': 'संतरा (Santra)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 60.0},
  {'name': 'Grapes', 'local': 'अंगूर (Angoor)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 80.0},
  {'name': 'Papaya', 'local': 'पपीता (Papita)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 45.0},
  {'name': 'Guava', 'local': 'अमरूद (Amrood)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 50.0},
  {'name': 'Pomegranate (Anar)', 'local': 'अनार (Anar)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 130.0},
  {'name': 'Watermelon', 'local': 'तरबूज (Tarbooz)', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 1.0, 'price': 60.0},
  {'name': 'Pineapple', 'local': 'अनानास (Ananas)', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 1.0, 'price': 80.0},
  {'name': 'Kiwi', 'local': 'कीवी (Kiwi)', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 3.0, 'price': 90.0},
  {'name': 'Strawberry', 'local': 'स्ट्रॉबेरी (Strawberry)', 'category': 'Fruits', 'unit': 'Box', 'qty': 1.0, 'price': 80.0},

  // --- DAIRY, EGGS & BAKERY ---
  {'name': 'Amul Taaza T-Special Milk', 'local': 'अमूल ताज़ा दूध (Amul Taaza Doodh)', 'category': 'Dairy & Bakery', 'unit': 'Litre', 'qty': 1.0, 'price': 54.0},
  {'name': 'Amul Gold Full Cream Milk', 'local': 'अमूल गोल्ड दूध (Amul Gold Doodh)', 'category': 'Dairy & Bakery', 'unit': 'Litre', 'qty': 1.0, 'price': 66.0},
  {'name': 'Paneer (Fresh Malai)', 'local': 'पनीर (Paneer)', 'category': 'Dairy & Bakery', 'unit': 'Gram', 'qty': 200.0, 'price': 90.0},
  {'name': 'Amul Butter (Salted)', 'local': 'अमूल मक्खन (Amul Makkhan)', 'category': 'Dairy & Bakery', 'unit': 'Gram', 'qty': 100.0, 'price': 58.0},
  {'name': 'Curd (Dahi Tub)', 'local': 'दही (Dahi)', 'category': 'Dairy & Bakery', 'unit': 'Gram', 'qty': 400.0, 'price': 45.0},
  {'name': 'Cheese Slices', 'local': 'चीज (Cheese)', 'category': 'Dairy & Bakery', 'unit': 'Gram', 'qty': 200.0, 'price': 145.0},
  {'name': 'Brown Bread (Whole Wheat)', 'local': 'ब्राउन ब्रेड (Brown Bread)', 'category': 'Dairy & Bakery', 'unit': 'Gram', 'qty': 400.0, 'price': 45.0},
  {'name': 'White Sandwich Bread', 'local': 'व्हाइट ब्रेड (White Bread)', 'category': 'Dairy & Bakery', 'unit': 'Gram', 'qty': 400.0, 'price': 35.0},
  {'name': 'Eggs (Farm Fresh)', 'local': 'अंडे (Ande)', 'category': 'Dairy & Bakery', 'unit': 'Pcs', 'qty': 6.0, 'price': 48.0},

  // --- SNACKS & SWEETS ---
  {'name': 'Haldiram Alu Bhujia', 'local': 'हल्दीराम आलू भुजिया (Alu Bhujia)', 'category': 'Snacks & Sweets', 'unit': 'Gram', 'qty': 200.0, 'price': 60.0},
  {'name': 'Lay\'s Potato Chips (Magic Masala)', 'local': 'लेज चिप्स (Lay\'s Chips)', 'category': 'Snacks & Sweets', 'unit': 'Pack', 'qty': 1.0, 'price': 20.0},
  {'name': 'Kurkure Masala Munch', 'local': 'कुरकुरे (Kurkure)', 'category': 'Snacks & Sweets', 'unit': 'Pack', 'qty': 1.0, 'price': 20.0},
  {'name': 'Parle-G Biscuits', 'local': 'पारले-जी बिस्कुट (Parle-G Biscuit)', 'category': 'Snacks & Sweets', 'unit': 'Gram', 'qty': 250.0, 'price': 30.0},
  {'name': 'Britannia Good Day Cookies', 'local': 'गुड डे बिस्कुट (Good Day Biscuit)', 'category': 'Snacks & Sweets', 'unit': 'Gram', 'qty': 200.0, 'price': 40.0},
  {'name': 'Cadbury Dairy Milk Chocolate', 'local': 'कैडबरी डेरी मिल्क (Cadbury Dairy Milk)', 'category': 'Snacks & Sweets', 'unit': 'Gram', 'qty': 60.0, 'price': 80.0},
  {'name': 'KitKat Chocolate Wafers', 'local': 'किटकेट (KitKat)', 'category': 'Snacks & Sweets', 'unit': 'Pcs', 'qty': 1.0, 'price': 30.0},

  // --- BEVERAGES ---
  {'name': 'Tata Tea Gold', 'local': 'टाटा गोल्ड चाय (Tata Gold Chai)', 'category': 'Beverages', 'unit': 'Gram', 'qty': 500.0, 'price': 310.0},
  {'name': 'Red Label Tea', 'local': 'रेड लेबल चाय (Red Label Chai)', 'category': 'Beverages', 'unit': 'Gram', 'qty': 500.0, 'price': 320.0},
  {'name': 'Nescafe Classic Instant Coffee', 'local': 'नेस्कैफे कॉफी (Nescafe Coffee)', 'category': 'Beverages', 'unit': 'Gram', 'qty': 100.0, 'price': 340.0},
  {'name': 'Coca-Cola / Pepsi Soft Drink', 'local': 'कोका कोला / पेप्सी (Soft Drink)', 'category': 'Beverages', 'unit': 'Litre', 'qty': 1.25, 'price': 65.0},
  {'name': 'Real Mixed Fruit Juice', 'local': 'रियल जूस (Real Juice)', 'category': 'Beverages', 'unit': 'Litre', 'qty': 1.0, 'price': 130.0},

  // --- HOUSEHOLD CARE ---
  {'name': 'Surf Excel Easy Wash Detergent', 'local': 'सर्फ एक्सेल (Surf Excel Detergent)', 'category': 'Household Care', 'unit': 'Kg', 'qty': 1.0, 'price': 140.0},
  {'name': 'Vim Dishwash Liquid Gel', 'local': 'विम जेल (Vim Gel)', 'category': 'Household Care', 'unit': 'Ml', 'qty': 500.0, 'price': 120.0},
  {'name': 'Harpic Toilet Cleaner', 'local': 'हारपिक (Harpic Cleaner)', 'category': 'Household Care', 'unit': 'Ml', 'qty': 500.0, 'price': 95.0},
  {'name': 'Lizol Floor Cleaner', 'local': 'लायज़ोल (Lizol Cleaner)', 'category': 'Household Care', 'unit': 'Litre', 'qty': 1.0, 'price': 190.0},
  {'name': 'Good Knight Mosquito Refill', 'local': 'गुड नाइट (Good Knight)', 'category': 'Household Care', 'unit': 'Pcs', 'qty': 2.0, 'price': 150.0},

  // --- PERSONAL CARE ---
  {'name': 'Dettol Soap Bar', 'local': 'डेटॉल साबुन (Dettol Sabun)', 'category': 'Personal Care', 'unit': 'Gram', 'qty': 125.0, 'price': 45.0},
  {'name': 'Dove Cream Beauty Bar', 'local': 'डव साबुन (Dove Sabun)', 'category': 'Personal Care', 'unit': 'Gram', 'qty': 125.0, 'price': 62.0},
  {'name': 'Colgate MaxFresh Toothpaste', 'local': 'कोलगेट पेस्ट (Colgate Paste)', 'category': 'Personal Care', 'unit': 'Gram', 'qty': 150.0, 'price': 110.0},
  {'name': 'Himalaya Neem Face Wash', 'local': 'हिमालय फेस वॉश (Himalaya Face Wash)', 'category': 'Personal Care', 'unit': 'Ml', 'qty': 100.0, 'price': 140.0},
  {'name': 'Pantene / Sunsilk Shampoo', 'local': 'शैम्पू (Shampoo)', 'category': 'Personal Care', 'unit': 'Ml', 'qty': 340.0, 'price': 260.0},
];

Future<void> main() async {
  print('================================================================');
  print('Seeding Clean, Real-World Essential Products for User: $targetUser');
  print('================================================================\n');

  // Clear existing items for user 7400700500
  print('Cleaning existing records for user $targetUser...');
  await executeTarget('DELETE FROM wallet_products WHERE user_id = \$1', [targetUser]);

  int idCounter = 1;
  final now = DateTime.now().millisecondsSinceEpoch;

  for (final p in cleanEssentialProducts) {
    final insertSql = '''
      INSERT INTO wallet_products (id, user_id, "productName", "localName", category, unit, quantity, "currentPrice", "oldPrice", "appName", "referenceLink", active, deleted, updated_at, last_updated_by)
      VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, 1, 0, \$12, 'clean_essential_seeder');
    ''';

    final params = [
      idCounter.toString(),
      targetUser,
      p['name'],
      p['local'],
      p['category'],
      p['unit'],
      p['qty'],
      p['price'],
      p['price'],
      'Zepto',
      'https://zepto.co/search?q=${Uri.encodeComponent(p['name'] as String)}',
      now,
    ];

    try {
      await executeTarget(insertSql, params);
      print('  [✓] ${p['name']} (${p['local']}) - ${p['category']}');
      idCounter++;
    } catch (e) {
      print('  [!] Error inserting ${p['name']}: $e');
    }
  }

  print('\n================================================================');
  print('Successfully inserted ${cleanEssentialProducts.length} clean essential products for User: $targetUser!');
  print('================================================================');
}
