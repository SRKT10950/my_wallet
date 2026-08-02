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

final List<Map<String, dynamic>> masterProducts = [
  // --- Vegetables ---
  {'productName': 'Potato', 'localName': 'आलू (Aloo)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 30.0, 'description': 'Fresh farm potatoes'},
  {'productName': 'Tomato', 'localName': 'टमाटर (Tamatar)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 40.0, 'description': 'Ripe red tomatoes'},
  {'productName': 'Onion', 'localName': 'प्याज (Pyaz)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 35.0, 'description': 'Fresh red onions'},
  {'productName': 'Garlic', 'localName': 'लहसुन (Lahsun)', 'category': 'Vegetables', 'unit': 'Gram', 'quantity': 250.0, 'currentPrice': 50.0, 'description': 'Organic garlic cloves'},
  {'productName': 'Ginger', 'localName': 'अदरक (Adrak)', 'category': 'Vegetables', 'unit': 'Gram', 'quantity': 250.0, 'currentPrice': 30.0, 'description': 'Fresh ginger root'},
  {'productName': 'Spinach', 'localName': 'पालक (Palak)', 'category': 'Vegetables', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 25.0, 'description': 'Fresh leafy spinach'},
  {'productName': 'Cauliflower', 'localName': 'फूलगोभी (Phool Gobi)', 'category': 'Vegetables', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 30.0, 'description': 'Fresh white cauliflower'},
  {'productName': 'Cabbage', 'localName': 'पत्तागोभी (Patta Gobi)', 'category': 'Vegetables', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 25.0, 'description': 'Fresh green cabbage'},
  {'productName': 'Brinjal / Eggplant', 'localName': 'बैंगन (Baingan)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 40.0, 'description': 'Fresh purple brinjal'},
  {'productName': 'Lady Finger / Okra', 'localName': 'भिंडी (Bhindi)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 45.0, 'description': 'Tender lady fingers'},
  {'productName': 'Green Peas', 'localName': 'हरी मटर (Hari Matar)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 60.0, 'description': 'Fresh green peas'},
  {'productName': 'Cucumber', 'localName': 'खीरा (Kheera)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 30.0, 'description': 'Crisp green cucumber'},
  {'productName': 'Carrot', 'localName': 'गाजर (Gajar)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 40.0, 'description': 'Fresh orange carrots'},
  {'productName': 'Radish', 'localName': 'मूली (Mooli)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 25.0, 'description': 'Fresh white radish'},
  {'productName': 'Bottle Gourd', 'localName': 'लौकी (Lauki)', 'category': 'Vegetables', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 30.0, 'description': 'Fresh bottle gourd'},
  {'productName': 'Bitter Gourd', 'localName': 'करेला (Karela)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 50.0, 'description': 'Fresh bitter gourd'},
  {'productName': 'Ridge Gourd', 'localName': 'तरोई (Taroi)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 40.0, 'description': 'Fresh ridge gourd'},
  {'productName': 'Capsicum', 'localName': 'शिमला मिर्च (Shimla Mirch)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 60.0, 'description': 'Fresh green capsicum'},
  {'productName': 'Green Chilli', 'localName': 'हरी मिर्च (Hari Mirch)', 'category': 'Vegetables', 'unit': 'Gram', 'quantity': 250.0, 'currentPrice': 20.0, 'description': 'Spicy green chillies'},
  {'productName': 'Lemon', 'localName': 'नींबू (Nimbu)', 'category': 'Vegetables', 'unit': 'Pcs', 'quantity': 4.0, 'currentPrice': 20.0, 'description': 'Juicy yellow lemons'},
  {'productName': 'Coriander Leaves', 'localName': 'हरा धनिया (Hara Dhaniya)', 'category': 'Vegetables', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 15.0, 'description': 'Fresh coriander leaves'},
  {'productName': 'Mint Leaves', 'localName': 'पुदीना (Pudina)', 'category': 'Vegetables', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 15.0, 'description': 'Fresh mint leaves'},
  {'productName': 'Pumpkin', 'localName': 'कद्दू (Kaddu)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 30.0, 'description': 'Fresh pumpkin'},
  {'productName': 'Sweet Potato', 'localName': 'शकरकंद (Shakarkand)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 40.0, 'description': 'Sweet potatoes'},
  {'productName': 'Beetroot', 'localName': 'चुकंदर (Chukandar)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 35.0, 'description': 'Red beetroot'},
  {'productName': 'Broccoli', 'localName': 'ब्रोकोली (Broccoli)', 'category': 'Vegetables', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 70.0, 'description': 'Fresh green broccoli'},
  {'productName': 'Button Mushroom', 'localName': 'मशरूम (Mushroom)', 'category': 'Vegetables', 'unit': 'Box', 'quantity': 1.0, 'currentPrice': 50.0, 'description': 'Fresh button mushrooms'},
  {'productName': 'Cluster Beans', 'localName': 'ग्वार फली (Gwar Phali)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 45.0, 'description': 'Fresh cluster beans'},
  {'productName': 'French Beans', 'localName': 'बीन्स (Beans)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 50.0, 'description': 'Fresh french beans'},
  {'productName': 'Drumstick', 'localName': 'सहजन (Sahjan)', 'category': 'Vegetables', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 30.0, 'description': 'Fresh drumsticks'},
  {'productName': 'Raw Banana', 'localName': 'कच्चा केला (Katcha Kela)', 'category': 'Vegetables', 'unit': 'Pcs', 'quantity': 4.0, 'currentPrice': 20.0, 'description': 'Raw cooking bananas'},
  {'productName': 'Raw Papaya', 'localName': 'कच्चा पपीता (Katcha Papita)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 30.0, 'description': 'Raw cooking papaya'},
  {'productName': 'Raw Mango', 'localName': 'कच्चा आम (Katcha Aam)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 50.0, 'description': 'Sour raw mangoes'},
  {'productName': 'Colocasia Root', 'localName': 'अरबी (Arbi)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 40.0, 'description': 'Fresh arbi roots'},
  {'productName': 'Pointed Gourd', 'localName': 'परवल (Parwal)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 50.0, 'description': 'Fresh parwal'},
  {'productName': 'Ivy Gourd', 'localName': 'कुंदरू (Kundru)', 'category': 'Vegetables', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 35.0, 'description': 'Fresh kundru'},
  {'productName': 'Fenugreek Leaves', 'localName': 'मेथी (Methi)', 'category': 'Vegetables', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 20.0, 'description': 'Fresh methi leaves'},
  {'productName': 'Curry Leaves', 'localName': 'कढ़ी पत्ता (Kadi Patta)', 'category': 'Vegetables', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 10.0, 'description': 'Fresh curry leaves'},
  {'productName': 'Spring Onion', 'localName': 'हरा प्याज (Hara Pyaz)', 'category': 'Vegetables', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 30.0, 'description': 'Fresh spring onions'},
  {'productName': 'Sweet Corn', 'localName': 'स्वीट कॉर्न (Sweet Corn)', 'category': 'Vegetables', 'unit': 'Pcs', 'quantity': 2.0, 'currentPrice': 30.0, 'description': 'Juicy sweet corn cobs'},

  // --- Fruits ---
  {'productName': 'Mango', 'localName': 'आम (Aam)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 100.0, 'description': 'Sweet juicy mangoes'},
  {'productName': 'Apple', 'localName': 'सेब (Seb)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 120.0, 'description': 'Fresh red apples'},
  {'productName': 'Banana', 'localName': 'केला (Kela)', 'category': 'Fruits', 'unit': 'Dozen', 'quantity': 1.0, 'currentPrice': 60.0, 'description': 'Ripe yellow bananas'},
  {'productName': 'Orange', 'localName': 'संतरा (Santra)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 80.0, 'description': 'Juicy Nagpur oranges'},
  {'productName': 'Grapes', 'localName': 'अंगूर (Angoor)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 90.0, 'description': 'Sweet seedless grapes'},
  {'productName': 'Papaya', 'localName': 'पपीता (Papita)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 50.0, 'description': 'Ripe sweet papaya'},
  {'productName': 'Guava', 'localName': 'अमरूद (Amrood)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 60.0, 'description': 'Fresh guava'},
  {'productName': 'Pomegranate', 'localName': 'अनार (Anar)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 140.0, 'description': 'Red pomegranate'},
  {'productName': 'Watermelon', 'localName': 'तरबूज (Tarbooz)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 60.0, 'description': 'Sweet watermelon'},
  {'productName': 'Muskmelon', 'localName': 'खरबूजा (Kharbooza)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 50.0, 'description': 'Fragrant muskmelon'},
  {'productName': 'Pineapple', 'localName': 'अनानास (Ananas)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 80.0, 'description': 'Sweet pineapple'},
  {'productName': 'Sweet Lime / Mosambi', 'localName': 'मौसमी (Mosambi)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 70.0, 'description': 'Fresh mosambi'},
  {'productName': 'Custard Apple', 'localName': 'शरीफा / सीताफल (Sitafal)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 100.0, 'description': 'Sweet sitafal'},
  {'productName': 'Sapota / Chikoo', 'localName': 'चीकू (Chikoo)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 60.0, 'description': 'Sweet chikoo'},
  {'productName': 'Pear', 'localName': 'नाशपाती (Nashpati)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 90.0, 'description': 'Juicy pears'},
  {'productName': 'Peach', 'localName': 'आडू (Aadoo)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 120.0, 'description': 'Fresh peaches'},
  {'productName': 'Plum', 'localName': 'आलूबुखारा (Aloo Bukhara)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 140.0, 'description': 'Sweet plums'},
  {'productName': 'Kiwi', 'localName': 'कीवी (Kiwi)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 3.0, 'currentPrice': 90.0, 'description': 'Fresh green kiwis'},
  {'productName': 'Dragon Fruit', 'localName': 'ड्रैगन फ्रूट (Dragon Fruit)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 100.0, 'description': 'Pink dragon fruit'},
  {'productName': 'Strawberry', 'localName': 'स्ट्रॉबेरी (Strawberry)', 'category': 'Fruits', 'unit': 'Box', 'quantity': 1.0, 'currentPrice': 80.0, 'description': 'Fresh strawberries'},
  {'productName': 'Blueberry', 'localName': 'ब्लूबेरी (Blueberry)', 'category': 'Fruits', 'unit': 'Box', 'quantity': 1.0, 'currentPrice': 150.0, 'description': 'Imported blueberries'},
  {'productName': 'Jamun / Blackberry', 'localName': 'जामुन (Jamun)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 120.0, 'description': 'Fresh jamun'},
  {'productName': 'Lychee', 'localName': 'लीची (Lychee)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 150.0, 'description': 'Sweet juicy lychees'},
  {'productName': 'Dates', 'localName': 'खजूर (Khajoor)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 200.0, 'description': 'Sweet dates'},
  {'productName': 'Fig', 'localName': 'अंजीर (Anjeer)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 250.0, 'description': 'Fresh figs'},
  {'productName': 'Coconut (Water)', 'localName': 'नारियल पानी (Nariyal Paani)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 50.0, 'description': 'Fresh tender coconut water'},
  {'productName': 'Dry Coconut', 'localName': 'सूखा नारियल (Sookha Nariyal)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 30.0, 'description': 'Dry coconut copra'},
  {'productName': 'Apricot', 'localName': 'खुबानी (Khubani)', 'category': 'Fruits', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 180.0, 'description': 'Fresh apricots'},
  {'productName': 'Cherry', 'localName': 'चेरी (Cherry)', 'category': 'Fruits', 'unit': 'Box', 'quantity': 1.0, 'currentPrice': 150.0, 'description': 'Red cherries'},
  {'productName': 'Avocado', 'localName': 'एवोकैडो (Avocado)', 'category': 'Fruits', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 100.0, 'description': 'Ripe avocado'},

  // --- Groceries ---
  {'productName': 'KitKat Chocolate', 'localName': 'किटपैट (KitKat)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 25.0, 'description': 'Crispy wafer chocolate bar'},
  {'productName': 'Sugar', 'localName': 'चीनी / शक्कर (Sugar)', 'category': 'Groceries', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 45.0, 'description': 'Pure refined white sugar'},
  {'productName': 'Tata Salt', 'localName': 'टाटा नमक (Tata Namak)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 28.0, 'description': 'Vacuum evaporated iodized salt'},
  {'productName': 'Basmati Rice', 'localName': 'बासमती चावल (Basmati Chawal)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 450.0, 'description': 'Premium long grain basmati rice 5kg'},
  {'productName': 'Wheat Flour (Atta)', 'localName': 'गेहूं का आटा (Gehun Atta)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 245.0, 'description': '100% whole wheat atta 5kg'},
  {'productName': 'Toor Dal / Arhar Dal', 'localName': 'तूर दाल / अरहर दाल (Toor Dal)', 'category': 'Groceries', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 160.0, 'description': 'Unpolished toor dal'},
  {'productName': 'Moong Dal', 'localName': 'मूंग दाल (Moong Dal)', 'category': 'Groceries', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 120.0, 'description': 'Yellow moong dal'},
  {'productName': 'Chana Dal', 'localName': 'चना दाल (Chana Dal)', 'category': 'Groceries', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 90.0, 'description': 'High protein chana dal'},
  {'productName': 'Urad Dal', 'localName': 'उड़द दाल (Urad Dal)', 'category': 'Groceries', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 130.0, 'description': 'Split urad dal'},
  {'productName': 'Rajma / Kidney Beans', 'localName': 'राजमा (Rajma)', 'category': 'Groceries', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 140.0, 'description': 'Premium red rajma'},
  {'productName': 'Kabuli Chana / Chickpeas', 'localName': 'काबुली चना (Kabuli Chana)', 'category': 'Groceries', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 130.0, 'description': 'Large kabuli chana'},
  {'productName': 'Mustard Oil', 'localName': 'सरसों का तेल (Sarson Tel)', 'category': 'Groceries', 'unit': 'Ltr', 'quantity': 1.0, 'currentPrice': 160.0, 'description': 'Kachi ghani mustard oil 1L'},
  {'productName': 'Sunflower Oil', 'localName': 'सूरजमुखी का तेल (Sunflower Oil)', 'category': 'Groceries', 'unit': 'Ltr', 'quantity': 1.0, 'currentPrice': 140.0, 'description': 'Refined sunflower oil 1L'},
  {'productName': 'Desi Ghee', 'localName': 'देसी घी (Desi Ghee)', 'category': 'Groceries', 'unit': 'Ltr', 'quantity': 1.0, 'currentPrice': 580.0, 'description': 'Pure cow desi ghee 1L'},
  {'productName': 'Turmeric Powder (Haldi)', 'localName': 'हल्दी पाउडर (Haldi Powder)', 'category': 'Groceries', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 55.0, 'description': 'Pure turmeric powder 200g'},
  {'productName': 'Red Chilli Powder', 'localName': 'लाल मिर्च पाउडर (Lal Mirch Powder)', 'category': 'Groceries', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 65.0, 'description': 'Spicy red chilli powder 200g'},
  {'productName': 'Coriander Powder', 'localName': 'धनिया पाउडर (Dhaniya Powder)', 'category': 'Groceries', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 45.0, 'description': 'Aromatic coriander powder 200g'},
  {'productName': 'Cumin Seeds (Jeera)', 'localName': 'जीरा (Jeera)', 'category': 'Groceries', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 40.0, 'description': 'Whole cumin seeds 100g'},
  {'productName': 'Garam Masala', 'localName': 'गरम मसाला (Garam Masala)', 'category': 'Groceries', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 75.0, 'description': 'Blended spice powder 100g'},
  {'productName': 'Tea Leaves (Chai Patti)', 'localName': 'चाय पत्ती (Chai Patti)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 140.0, 'description': 'Premium CTC tea leaves 250g'},
  {'productName': 'Instant Coffee', 'localName': 'कॉफी (Coffee)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 170.0, 'description': 'Rich blend instant coffee 50g'},
  {'productName': 'Fresh Paneer', 'localName': 'पनीर (Paneer)', 'category': 'Groceries', 'unit': 'Gram', 'quantity': 200.0, 'currentPrice': 90.0, 'description': 'Fresh cottage cheese 200g'},
  {'productName': 'Full Cream Milk', 'localName': 'दूध (Doodh)', 'category': 'Groceries', 'unit': 'Ltr', 'quantity': 1.0, 'currentPrice': 66.0, 'description': 'Pasteurised full cream milk 1L'},
  {'productName': 'Fresh Curd / Dahi', 'localName': 'दही (Dahi)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 35.0, 'description': 'Thick fresh curd 400g'},
  {'productName': 'Amul Pasteurised Butter', 'localName': 'अमूल मक्खन (Amul Makhan)', 'category': 'Groceries', 'unit': 'Gram', 'quantity': 100.0, 'currentPrice': 58.0, 'description': 'Pasteurised salted butter 100g'},
  {'productName': 'Process Cheese Slices', 'localName': 'चीज (Cheese)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 135.0, 'description': 'Cheese slices pack of 10'},
  {'productName': 'Bread', 'localName': 'ब्रेड (Bread)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 40.0, 'description': 'Fresh sliced bread 400g'},
  {'productName': 'Eggs', 'localName': 'अंडे (Ande)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 6.0, 'currentPrice': 45.0, 'description': 'Fresh farm white eggs tray of 6'},
  {'productName': 'Thick Poha', 'localName': 'पोहा (Poha)', 'category': 'Groceries', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 50.0, 'description': 'Beaten rice poha 1kg'},
  {'productName': 'Besan / Gram Flour', 'localName': 'बेसन (Besan)', 'category': 'Groceries', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 90.0, 'description': 'Fine chana besan 1kg'},
  {'productName': 'Maida', 'localName': 'मैदा (Maida)', 'category': 'Groceries', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 45.0, 'description': 'Refined wheat flour 1kg'},
  {'productName': 'Suji / Rava', 'localName': 'सूजी (Suji)', 'category': 'Groceries', 'unit': 'Kg', 'quantity': 1.0, 'currentPrice': 45.0, 'description': 'Fine semolina suji 1kg'},
  {'productName': 'Rolled Oats', 'localName': 'ओट्स (Oats)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 180.0, 'description': '100% natural rolled oats 1kg'},
  {'productName': 'Cadbury Dairy Milk', 'localName': 'डेयरी मिल्क (Dairy Milk)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 40.0, 'description': 'Milk chocolate bar 50g'},
  {'productName': 'Maggi 2-Minute Noodles', 'localName': 'मैगी (Maggi)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 14.0, 'description': 'Masala instant noodles 70g'},
  {'productName': 'Parle-G Biscuits', 'localName': 'पारले-जी बिस्किट (Parle-G)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 10.0, 'description': 'Glucose biscuits 130g'},
  {'productName': 'Britannia Good Day Biscuits', 'localName': 'गुड डे बिस्किट (Good Day)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 20.0, 'description': 'Butter cookies 100g'},
  {'productName': 'Lay\'s Potato Chips', 'localName': 'लेज चिप्स (Lays Chips)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 20.0, 'description': 'Magic Masala potato chips'},
  {'productName': 'Haldiram Bhujia', 'localName': 'हल्दीराम भुजिया (Haldiram Bhujia)', 'category': 'Groceries', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 50.0, 'description': 'Crispy spicy bhujia sev 200g'},

  // --- Medicines ---
  {'productName': 'Paracetamol 650mg', 'localName': 'पैरासिटामोल (Paracetamol)', 'category': 'Medicines', 'unit': 'Strip', 'quantity': 10.0, 'currentPrice': 30.0, 'description': 'Fever and pain relief tablets'},
  {'productName': 'Dolo 650 Tablet', 'localName': 'डोलो ६५० (Dolo 650)', 'category': 'Medicines', 'unit': 'Strip', 'quantity': 15.0, 'currentPrice': 32.0, 'description': 'Antipyretic fever and pain relief'},
  {'productName': 'Crocin Advance', 'localName': 'क्रोसीन (Crocin)', 'category': 'Medicines', 'unit': 'Strip', 'quantity': 15.0, 'currentPrice': 25.0, 'description': 'Fast acting paracetamol tablet'},
  {'productName': 'Disprin 350mg', 'localName': 'डिस्प्रिन (Disprin)', 'category': 'Medicines', 'unit': 'Strip', 'quantity': 10.0, 'currentPrice': 12.0, 'description': 'Efferverscent headache tablet'},
  {'productName': 'Combiflam Tablet', 'localName': 'कॉम्बीफ्लैम (Combiflam)', 'category': 'Medicines', 'unit': 'Strip', 'quantity': 20.0, 'currentPrice': 45.0, 'description': 'Ibuprofen and paracetamol pain relief'},
  {'productName': 'Gelusil Antacid Syrup', 'localName': 'गेलुसिल (Gelusil)', 'category': 'Medicines', 'unit': 'Bottle', 'quantity': 1.0, 'currentPrice': 110.0, 'description': 'Acidity and heartburn relief liquid 200ml'},
  {'productName': 'Digene Antacid Syrup', 'localName': 'डाइजीन (Digene)', 'category': 'Medicines', 'unit': 'Bottle', 'quantity': 1.0, 'currentPrice': 130.0, 'description': 'Gas and acidity relief syrup 200ml'},
  {'productName': 'Otic / Ocotic Ear Drops', 'localName': 'कान की दवा (Kaan Ki Drop)', 'category': 'Medicines', 'unit': 'Ml', 'quantity': 10.0, 'currentPrice': 85.0, 'description': 'Ear infection and pain relief drops 10ml'},
  {'productName': 'Lubricant Eye Drops', 'localName': 'आंख की दवा (Aankh Ki Drop)', 'category': 'Medicines', 'unit': 'Ml', 'quantity': 10.0, 'currentPrice': 95.0, 'description': 'Soothing eye drop solution 10ml'},
  {'productName': 'Cough Syrup', 'localName': 'खांसी की सिरप (Khansi Ki Syrup)', 'category': 'Medicines', 'unit': 'Bottle', 'quantity': 1.0, 'currentPrice': 115.0, 'description': 'Relief for dry & wet cough 100ml'},
  {'productName': 'Band-Aid Adhesive Bandage', 'localName': 'बैंड-एड (Band-Aid)', 'category': 'Medicines', 'unit': 'Box', 'quantity': 1.0, 'currentPrice': 45.0, 'description': 'Medicated waterproof strips box of 10'},
  {'productName': 'Volini Pain Relief Spray', 'localName': 'वोलिनी (Volini)', 'category': 'Medicines', 'unit': 'Bottle', 'quantity': 1.0, 'currentPrice': 160.0, 'description': 'Instant muscle & joint pain spray 40g'},
  {'productName': 'ORS Powder', 'localName': 'ओआरएस (ORS)', 'category': 'Medicines', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 22.0, 'description': 'Oral rehydration salts sachet 21g'},
  {'productName': 'Vitamin C Chewable Tablets', 'localName': 'विटामिन सी (Vitamin C)', 'category': 'Medicines', 'unit': 'Strip', 'quantity': 15.0, 'currentPrice': 40.0, 'description': 'Immunity booster Celin 500mg'},
  {'productName': 'Dettol Antiseptic Liquid', 'localName': 'डेटॉल (Dettol Liquid)', 'category': 'Medicines', 'unit': 'Bottle', 'quantity': 1.0, 'currentPrice': 90.0, 'description': 'First aid antiseptic liquid 100ml'},
  {'productName': 'Vicks Vaporub', 'localName': 'विक्र्स वैपोरब (Vicks Vaporub)', 'category': 'Medicines', 'unit': 'Box', 'quantity': 1.0, 'currentPrice': 60.0, 'description': 'Cold and congestion relief balm 25g'},
  {'productName': 'Pudin Hara Pearls', 'localName': 'पुदीन हरा (Pudin Hara)', 'category': 'Medicines', 'unit': 'Strip', 'quantity': 10.0, 'currentPrice': 30.0, 'description': 'Natural mint digestive pearls'},
  {'productName': 'Moov Pain Relief Ointment', 'localName': 'मूव (Moov)', 'category': 'Medicines', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 95.0, 'description': 'Backache specialist pain cream 30g'},
  {'productName': 'Boroline Antiseptic Cream', 'localName': 'बोरोलीन (Boroline)', 'category': 'Medicines', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 40.0, 'description': 'Night repair antiseptic cream 20g'},
  {'productName': 'Digital Thermometer', 'localName': 'थर्मामीटर (Thermometer)', 'category': 'Medicines', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 220.0, 'description': 'Accurate body temperature sensor'},

  // --- Personal Care ---
  {'productName': 'Dettol Bathing Soap', 'localName': 'डेटॉल साबुन (Dettol Sabun)', 'category': 'Personal Care', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 45.0, 'description': 'Germ protection bathing bar 100g'},
  {'productName': 'Dove Bathing Bar', 'localName': 'डव साबुन (Dove Sabun)', 'category': 'Personal Care', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 65.0, 'description': 'Moisturizing cream beauty bar 100g'},
  {'productName': 'Lux Soap', 'localName': 'लक्स साबुन (Lux Sabun)', 'category': 'Personal Care', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 38.0, 'description': 'Fragrant rose bathing soap 100g'},
  {'productName': 'Clinic Plus Shampoo', 'localName': 'क्लिनिक प्लस शैम्पू (Clinic Plus)', 'category': 'Personal Care', 'unit': 'Bottle', 'quantity': 1.0, 'currentPrice': 140.0, 'description': 'Strong & long milk protein shampoo 340ml'},
  {'productName': 'Pantene Hair Fall Shampoo', 'localName': 'पैंटीन शैम्पू (Pantene)', 'category': 'Personal Care', 'unit': 'Bottle', 'quantity': 1.0, 'currentPrice': 190.0, 'description': 'Pro-V hair fall control shampoo 340ml'},
  {'productName': 'Colgate Total Toothpaste', 'localName': 'कोलगेट टूथपेस्ट (Colgate)', 'category': 'Personal Care', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 110.0, 'description': 'Whole mouth cavity protection paste 150g'},
  {'productName': 'Sensodyne Toothpaste', 'localName': 'सेंसोडाइन (Sensodyne)', 'category': 'Personal Care', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 150.0, 'description': 'Sensitivity relief dental paste 70g'},
  {'productName': 'Soft Toothbrush', 'localName': 'टूथब्रश (Toothbrush)', 'category': 'Personal Care', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 35.0, 'description': 'Gentle bristle toothbrush'},
  {'productName': 'Dettol Liquid Hand Wash', 'localName': 'हैंड वॉश (Hand Wash)', 'category': 'Personal Care', 'unit': 'Bottle', 'quantity': 1.0, 'currentPrice': 99.0, 'description': 'Germ protection hand wash pump 200ml'},
  {'productName': 'Himalaya Neem Face Wash', 'localName': 'फेस वॉश (Face Wash)', 'category': 'Personal Care', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 130.0, 'description': 'Purifying neem face wash 100ml'},
  {'productName': 'Parachute Coconut Hair Oil', 'localName': 'नारियल तेल (Nariyal Tel)', 'category': 'Personal Care', 'unit': 'Bottle', 'quantity': 1.0, 'currentPrice': 110.0, 'description': '100% pure coconut hair oil 200ml'},
  {'productName': 'Nivea Soft Body Lotion', 'localName': 'बॉडी लोशन (Body Lotion)', 'category': 'Personal Care', 'unit': 'Bottle', 'quantity': 1.0, 'currentPrice': 240.0, 'description': 'Light moisturizing lotion 200ml'},
  {'productName': 'Fogg Deodorant Body Spray', 'localName': 'फॉग स्प्रे (Fogg Spray)', 'category': 'Personal Care', 'unit': 'Bottle', 'quantity': 1.0, 'currentPrice': 210.0, 'description': 'Long lasting no-gas body spray 150ml'},
  {'productName': 'Glow & Lovely Face Cream', 'localName': 'ग्लो एंड लवली (Glow & Lovely)', 'category': 'Personal Care', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 75.0, 'description': 'Multivitamin skin cream 50g'},
  {'productName': 'Gillette Guard Razor', 'localName': 'शेविंग रेजर (Razor)', 'category': 'Personal Care', 'unit': 'Pcs', 'quantity': 1.0, 'currentPrice': 60.0, 'description': 'Safety shaving razor with blade'},
  {'productName': 'Gillette Shaving Foam', 'localName': 'शेविंग फोम (Shaving Foam)', 'category': 'Personal Care', 'unit': 'Can', 'quantity': 1.0, 'currentPrice': 180.0, 'description': 'Sensitive skin shaving foam 200g'},
  {'productName': 'Whisper Choice Sanitary Pads', 'localName': 'सैनिटरी पैड्स (Sanitary Pads)', 'category': 'Personal Care', 'unit': 'Pack', 'quantity': 1.0, 'currentPrice': 90.0, 'description': 'Extra heavy flow wings pack of 20'},
  {'productName': 'Dettol Hand Sanitizer', 'localName': 'सैनिटाइजर (Sanitizer)', 'category': 'Personal Care', 'unit': 'Bottle', 'quantity': 1.0, 'currentPrice': 50.0, 'description': 'Instant waterless sanitizer 50ml'},
  {'productName': 'Vaseline Petroleum Jelly', 'localName': 'वेसलीन (Vaseline)', 'category': 'Personal Care', 'unit': 'Box', 'quantity': 1.0, 'currentPrice': 45.0, 'description': 'Pure skin jelly 42g'},
  {'productName': 'Bajaj Almond Drops Hair Oil', 'localName': 'बादाम तेल (Almond Oil)', 'category': 'Personal Care', 'unit': 'Bottle', 'quantity': 1.0, 'currentPrice': 125.0, 'description': 'Non-sticky almond hair oil with Vitamin E 100ml'},
];

Future<void> main() async {
  print('================================================================');
  print('Step 1: Deleting ALL existing products from database...');
  print('================================================================\n');

  try {
    await executeTarget('DELETE FROM wallet_products', []);
    print('✅ Successfully deleted ALL existing products from database table wallet_products.');
  } catch (e) {
    print('⚠️ Error clearing database table wallet_products: $e');
  }

  print('\n================================================================');
  print('Step 2: Inserting Master Product Catalog (${masterProducts.length} items)...');
  print('================================================================\n');

  List<String> targetUsers = [];
  try {
    final dbUsers = await queryTarget('SELECT DISTINCT mobile_number FROM users');
    for (final u in dbUsers) {
      final mob = u['mobile_number']?.toString();
      if (mob != null && mob.isNotEmpty && !targetUsers.contains(mob)) {
        targetUsers.add(mob);
      }
    }
  } catch (e) {
    print('Note fetching users list: $e');
  }
  if (targetUsers.isEmpty) {
    targetUsers = ['7400700500'];
  }

  int totalInserted = 0;
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final now = DateTime.now().millisecondsSinceEpoch;

  for (final user in targetUsers) {
    int idCounter = 1;
    print('Processing database insertion for user: $user ...');

    for (final prod in masterProducts) {
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
        idCounter++,
        user,
        prod['productName'],
        prod['localName'],
        prod['category'],
        'https://google.com/search?q=' + Uri.encodeComponent(prod['productName']),
        'Master Catalog',
        today,
        prod['currentPrice'],
        (prod['currentPrice'] as double) * 1.1,
        prod['unit'],
        prod['quantity'],
        prod['description'],
        1,
        0,
        now,
        'system'
      ];

      try {
        await executeTarget(sql, params);
        totalInserted++;
      } catch (e) {
        print('  Failed to insert ${prod['productName']} for $user: $e');
      }
    }
    print('  ✓ Finished inserting ${masterProducts.length} items for user: $user\n');
  }

  print('================================================================');
  print('🎉 COMPLETED: Wiped old products & inserted ${masterProducts.length} master products into database.');
  print('Total rows written: $totalInserted');
  print('================================================================');
}
