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
  'cauliflower': ['फूलगोभी', 'Phool Gobi'],
  'potato': ['आलू', 'Aloo'],
  'tomato': ['टमाटर', 'Tamatar'],
  'onion': ['प्याज', 'Pyaz'],
  'garlic': ['लहसुन', 'Lahsun'],
  'ginger': ['अदरक', 'Adrak'],
  'chilli': ['मिर्च', 'Mirch'],
  'lemon': ['नींबू', 'Nimbu'],
  'spinach': ['पालक', 'Palak'],
  'cabbage': ['पत्तागोभी', 'Patta Gobi'],
  'brinjal': ['बैंगन', 'Baingan'],
  'okra': ['भिंडी', 'Bhindi'],
  'peas': ['मटर', 'Matar'],
  'cucumber': ['खीरा', 'Kheera'],
  'carrot': ['गाजर', 'Gajar'],
  'gourd': ['लौकी', 'Lauki'],
  'radish': ['मूली', 'Mooli'],
  'apple': ['सेब', 'Seb'],
  'banana': ['केला', 'Kela'],
  'mango': ['आम', 'Aam'],
  'orange': ['संतरा', 'Santra'],
  'grapes': ['अंगूर', 'Angoor'],
  'papaya': ['पपीता', 'Papita'],
  'guava': ['अमरूद', 'Amrood'],
  'pomegranate': ['अनार', 'Anar'],
  'watermelon': ['तरबूज', 'Tarbooz'],
  'pineapple': ['अनानास', 'Ananas'],
  'kiwi': ['कीवी', 'Kiwi'],
  'strawberry': ['स्ट्रॉबेरी', 'Strawberry'],
  'rice': ['चावल', 'Chawal'],
  'atta': ['आटा', 'Atta'],
  'dal': ['दाल', 'Dal'],
  'oil': ['तेल', 'Tel'],
  'salt': ['नमक', 'Namak'],
  'sugar': ['चीनी', 'Cheeni'],
  'ghee': ['घी', 'Ghee'],
  'milk': ['दूध', 'Doodh'],
  'paneer': ['पनीर', 'Paneer'],
  'butter': ['मक्खन', 'Makkhan'],
  'cheese': ['चीज', 'Cheese'],
  'bread': ['ब्रेड', 'Bread'],
  'curd': ['दही', 'Dahi'],
  'eggs': ['अंडे', 'Ande'],
  'pen': ['पेन', 'Pen'],
  'pencil': ['पेंसिल', 'Pencil'],
  'notebook': ['नोटबुक', 'Notebook'],
  'paper': ['पेपर', 'Paper'],
  'soap': ['साबुन', 'Sabun'],
  'shampoo': ['शैम्पू', 'Shampoo'],
  'paste': ['पेस्ट', 'Paste'],
  'cream': ['क्रीम', 'Cream'],
  'tea': ['चाय', 'Chai'],
  'coffee': ['कॉफ़ी', 'Coffee'],
  'juice': ['जूस', 'Juice'],
  'drink': ['ड्रिंक', 'Drink'],
  'water': ['पानी', 'Paani'],
  'biscuit': ['बिस्कुट', 'Biscuit'],
  'cookies': ['कुकीज़', 'Cookies'],
  'chips': ['चिप्स', 'Chips'],
  'chocolate': ['चॉकलेट', 'Chocolate'],
  'namkeen': ['नमकीन', 'Namkeen'],
  'detergent': ['डिटर्जेंट', 'Detergent'],
  'cleaner': ['क्लीनर', 'Cleaner'],
};

String getLocalName(String englishName) {
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

final List<Map<String, dynamic>> rawMasterCatalog = [
  // ==================== VEGETABLE ====================
  {'name': 'Cauliflower', 'category': 'Vegetable', 'unit': 'Pcs', 'qty': 1.0, 'price': 30.0},
  {'name': 'Potato', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 24.0},
  {'name': 'Baby Potato', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 35.0},
  {'name': 'Red Potato', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 32.0},
  {'name': 'Sweet Potato (Shakarkandi)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 40.0},
  {'name': 'Tomato', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 35.0},
  {'name': 'Cherry Tomato', 'category': 'Vegetable', 'unit': 'Gram', 'qty': 250.0, 'price': 45.0},
  {'name': 'Roma Tomato', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 38.0},
  {'name': 'Onion', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 30.0},
  {'name': 'Red Onion', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 32.0},
  {'name': 'White Onion', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 45.0},
  {'name': 'Shallots (Sambar Pyaz)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 60.0},
  {'name': 'Spring Onion', 'category': 'Vegetable', 'unit': 'Pack', 'qty': 1.0, 'price': 25.0},
  {'name': 'Garlic', 'category': 'Vegetable', 'unit': 'Gram', 'qty': 250.0, 'price': 50.0},
  {'name': 'Green Garlic (Hara Lahsun)', 'category': 'Vegetable', 'unit': 'Gram', 'qty': 250.0, 'price': 40.0},
  {'name': 'Ginger', 'category': 'Vegetable', 'unit': 'Gram', 'qty': 250.0, 'price': 30.0},
  {'name': 'Green Chilli', 'category': 'Vegetable', 'unit': 'Gram', 'qty': 250.0, 'price': 20.0},
  {'name': 'Red Chilli Fresh', 'category': 'Vegetable', 'unit': 'Gram', 'qty': 250.0, 'price': 30.0},
  {'name': 'Lemon', 'category': 'Vegetable', 'unit': 'Pcs', 'qty': 4.0, 'price': 20.0},
  {'name': 'Spinach (Palak)', 'category': 'Vegetable', 'unit': 'Pack', 'qty': 1.0, 'price': 25.0},
  {'name': 'Cabbage', 'category': 'Vegetable', 'unit': 'Pcs', 'qty': 1.0, 'price': 25.0},
  {'name': 'Red Cabbage', 'category': 'Vegetable', 'unit': 'Pcs', 'qty': 1.0, 'price': 45.0},
  {'name': 'Brinjal (Baingan)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 40.0},
  {'name': 'Small Brinjal (Bhartay Baingan)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 45.0},
  {'name': 'Lady Finger (Bhindi)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 45.0},
  {'name': 'Green Peas (Matar)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 60.0},
  {'name': 'Cucumber (Kheera)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 30.0},
  {'name': 'Carrot (Gajar)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 40.0},
  {'name': 'Orange Carrot', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 35.0},
  {'name': 'Bottle Gourd (Lauki)', 'category': 'Vegetable', 'unit': 'Pcs', 'qty': 1.0, 'price': 30.0},
  {'name': 'Bitter Gourd (Karela)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 50.0},
  {'name': 'Ridge Gourd (Taroi)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 40.0},
  {'name': 'Capsicum (Shimla Mirch)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 60.0},
  {'name': 'Red Capsicum', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 120.0},
  {'name': 'Yellow Capsicum', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 120.0},
  {'name': 'Radish (Mooli)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 25.0},
  {'name': 'Pumpkin (Kaddu)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 30.0},
  {'name': 'Mushroom Button', 'category': 'Vegetable', 'unit': 'Box', 'qty': 1.0, 'price': 50.0},
  {'name': 'Mushroom Oyster', 'category': 'Vegetable', 'unit': 'Box', 'qty': 1.0, 'price': 75.0},
  {'name': 'Broccoli Fresh', 'category': 'Vegetable', 'unit': 'Pcs', 'qty': 1.0, 'price': 60.0},
  {'name': 'Baby Corn', 'category': 'Vegetable', 'unit': 'Pack', 'qty': 1.0, 'price': 45.0},
  {'name': 'Raw Banana (Kacha Kela)', 'category': 'Vegetable', 'unit': 'Pcs', 'qty': 4.0, 'price': 20.0},
  {'name': 'Colocasia (Arbi)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 40.0},
  {'name': 'Ash Gourd (Petha)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 30.0},
  {'name': 'Snake Gourd', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 40.0},
  {'name': 'Drumstick (Sahjan)', 'category': 'Vegetable', 'unit': 'Pack', 'qty': 1.0, 'price': 30.0},
  {'name': 'Beetroot', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 40.0},
  {'name': 'Turnip (Salgam)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 35.0},
  {'name': 'Ivy Gourd (Tindora)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 45.0},
  {'name': 'Pointed Gourd (Parwal)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 50.0},
  {'name': 'Cluster Beans (Gwar Phali)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 45.0},
  {'name': 'French Beans', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 60.0},
  {'name': 'Mint Leaves (Pudina)', 'category': 'Vegetable', 'unit': 'Pack', 'qty': 1.0, 'price': 15.0},
  {'name': 'Coriander Leaves (Dhania)', 'category': 'Vegetable', 'unit': 'Pack', 'qty': 1.0, 'price': 20.0},
  {'name': 'Curry Leaves (Kadi Patta)', 'category': 'Vegetable', 'unit': 'Pack', 'qty': 1.0, 'price': 15.0},
  {'name': 'Fenugreek Leaves (Methi)', 'category': 'Vegetable', 'unit': 'Pack', 'qty': 1.0, 'price': 25.0},
  {'name': 'Raw Mango (Kachi Kairi)', 'category': 'Vegetable', 'unit': 'Kg', 'qty': 1.0, 'price': 50.0},

  // ==================== FRUITS ====================
  {'name': 'Apple Shimla', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 95.0},
  {'name': 'Apple Washington', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 160.0},
  {'name': 'Green Apple', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 150.0},
  {'name': 'Banana Robusta', 'category': 'Fruits', 'unit': 'Dozen', 'qty': 1.0, 'price': 45.0},
  {'name': 'Banana Yelakki', 'category': 'Fruits', 'unit': 'Dozen', 'qty': 1.0, 'price': 65.0},
  {'name': 'Red Banana', 'category': 'Fruits', 'unit': 'Dozen', 'qty': 1.0, 'price': 90.0},
  {'name': 'Mango Alphonso', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 180.0},
  {'name': 'Mango Dasheri', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 80.0},
  {'name': 'Mango Langra', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 85.0},
  {'name': 'Mango Kesar', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 110.0},
  {'name': 'Mango Chausa', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 90.0},
  {'name': 'Orange Nagpur', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 60.0},
  {'name': 'Orange Kinnu', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 50.0},
  {'name': 'Mandarin Orange', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 80.0},
  {'name': 'Grapes Seedless Green', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 80.0},
  {'name': 'Grapes Black', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 110.0},
  {'name': 'Grapes Red Globe', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 140.0},
  {'name': 'Papaya Ripe', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 45.0},
  {'name': 'Guava Pink', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 60.0},
  {'name': 'Guava White', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 50.0},
  {'name': 'Pomegranate (Anar)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 130.0},
  {'name': 'Watermelon', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 1.0, 'price': 60.0},
  {'name': 'Muskmelon (Kharbooza)', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 1.0, 'price': 50.0},
  {'name': 'Pineapple', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 1.0, 'price': 80.0},
  {'name': 'Kiwi Green', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 3.0, 'price': 90.0},
  {'name': 'Kiwi Gold', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 3.0, 'price': 140.0},
  {'name': 'Strawberry', 'category': 'Fruits', 'unit': 'Box', 'qty': 1.0, 'price': 80.0},
  {'name': 'Blueberry', 'category': 'Fruits', 'unit': 'Box', 'qty': 1.0, 'price': 150.0},
  {'name': 'Blackberry (Jamun)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 120.0},
  {'name': 'Raspberry', 'category': 'Fruits', 'unit': 'Box', 'qty': 1.0, 'price': 110.0},
  {'name': 'Lychee Fresh', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 150.0},
  {'name': 'Jackfruit Ripe', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 80.0},
  {'name': 'Wood Apple (Bel)', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 1.0, 'price': 40.0},
  {'name': 'Dates Kimia', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 220.0},
  {'name': 'Fig Fresh (Anjeer)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 250.0},
  {'name': 'Coconut Water', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 1.0, 'price': 50.0},
  {'name': 'Raw Coconut Dry', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 1.0, 'price': 30.0},
  {'name': 'Apricot Fresh (Khubani)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 180.0},
  {'name': 'Cherry Fresh', 'category': 'Fruits', 'unit': 'Box', 'qty': 1.0, 'price': 150.0},
  {'name': 'Avocado Hass', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 1.0, 'price': 100.0},
  {'name': 'Passion Fruit', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 1.0, 'price': 60.0},
  {'name': 'Star Fruit (Kamrakh)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 80.0},
  {'name': 'Mulberry (Shahtoot)', 'category': 'Fruits', 'unit': 'Box', 'qty': 1.0, 'price': 60.0},
  {'name': 'Dragon Fruit Pink', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 1.0, 'price': 100.0},
  {'name': 'Dragon Fruit White', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 1.0, 'price': 90.0},
  {'name': 'Persimmon (Japani Phal)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 150.0},
  {'name': 'Pomelo (Chakotra)', 'category': 'Fruits', 'unit': 'Pcs', 'qty': 1.0, 'price': 80.0},
  {'name': 'Sweet Lime (Mosambi)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 70.0},
  {'name': 'Custard Apple (Sitafal)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 100.0},
  {'name': 'Sapota (Chikoo)', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 60.0},
  {'name': 'Pear Nashpati', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 90.0},
  {'name': 'Peach Fresh', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 120.0},
  {'name': 'Plum Fresh', 'category': 'Fruits', 'unit': 'Kg', 'qty': 1.0, 'price': 140.0},

  // ==================== GROCERY ====================
  {'name': 'Basmati Rice India Gate Classic', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 120.0},
  {'name': 'Basmati Rice Fortune Rozana', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 90.0},
  {'name': 'Sona Masoori Rice Raw', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 55.0},
  {'name': 'Wada Kolam Rice', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 65.0},
  {'name': 'Indrayani Rice', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 70.0},
  {'name': 'Brown Rice Organic', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 95.0},
  {'name': 'Aashirvaad Shuddh Chakki Atta', 'category': 'Grocery', 'unit': 'Kg', 'qty': 5.0, 'price': 225.0},
  {'name': 'Multigrain Atta Aashirvaad', 'category': 'Grocery', 'unit': 'Kg', 'qty': 5.0, 'price': 275.0},
  {'name': 'Fortune Besan Fine', 'category': 'Grocery', 'unit': 'Gram', 'qty': 500.0, 'price': 55.0},
  {'name': 'Maida Fine', 'category': 'Grocery', 'unit': 'Gram', 'qty': 500.0, 'price': 35.0},
  {'name': 'Sooji Coarse', 'category': 'Grocery', 'unit': 'Gram', 'qty': 500.0, 'price': 35.0},
  {'name': 'Poha Thick', 'category': 'Grocery', 'unit': 'Gram', 'qty': 500.0, 'price': 40.0},
  {'name': 'Sabudana (Tapioca Pearls)', 'category': 'Grocery', 'unit': 'Gram', 'qty': 500.0, 'price': 50.0},
  {'name': 'Toor Dal Premium Unpolished', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 140.0},
  {'name': 'Moong Dal Yellow Split', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 125.0},
  {'name': 'Chana Dal Desi', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 80.0},
  {'name': 'Urad Dal Split White', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 130.0},
  {'name': 'Rajma Chitra Red', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 140.0},
  {'name': 'Kabuli Chana Bold', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 130.0},
  {'name': 'Fortune Sunlite Refined Sunflower Oil', 'category': 'Grocery', 'unit': 'Litre', 'qty': 1.0, 'price': 135.0},
  {'name': 'Mustard Oil Kachi Ghani', 'category': 'Grocery', 'unit': 'Litre', 'qty': 1.0, 'price': 150.0},
  {'name': 'Pure Cow Ghee Amul', 'category': 'Grocery', 'unit': 'Litre', 'qty': 1.0, 'price': 620.0},
  {'name': 'Tata Salt Iodized', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 28.0},
  {'name': 'Sugar White Refined', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 44.0},
  {'name': 'Jaggery Powder Gud', 'category': 'Grocery', 'unit': 'Kg', 'qty': 1.0, 'price': 60.0},

  // ==================== STATIONERY ====================
  {'name': 'Classmate Notebook A4 200 Pages', 'category': 'Stationery', 'unit': 'Pcs', 'qty': 1.0, 'price': 65.0},
  {'name': 'Classmate Notebook A4 300 Pages', 'category': 'Stationery', 'unit': 'Pcs', 'qty': 1.0, 'price': 90.0},
  {'name': 'Classmate Spiral Bound Notebook A5', 'category': 'Stationery', 'unit': 'Pcs', 'qty': 1.0, 'price': 95.0},
  {'name': 'Classmate Practical File', 'category': 'Stationery', 'unit': 'Pcs', 'qty': 1.0, 'price': 50.0},
  {'name': 'Reynolds Ball Pen Blue', 'category': 'Stationery', 'unit': 'Pack', 'qty': 5.0, 'price': 50.0},
  {'name': 'Reynolds Trimax Gel Pen Blue', 'category': 'Stationery', 'unit': 'Pcs', 'qty': 1.0, 'price': 60.0},
  {'name': 'Cello Butterflow Ball Pen', 'category': 'Stationery', 'unit': 'Pcs', 'qty': 1.0, 'price': 15.0},
  {'name': 'Pilot V5 Hi-Tecpoint Pen', 'category': 'Stationery', 'unit': 'Pcs', 'qty': 1.0, 'price': 65.0},
  {'name': 'Natraj HB Pencils Box', 'category': 'Stationery', 'unit': 'Box', 'qty': 1.0, 'price': 60.0},
  {'name': 'Apsara Platinum Extra Dark Pencils', 'category': 'Stationery', 'unit': 'Box', 'qty': 1.0, 'price': 75.0},
  {'name': 'Camlin Oil Pastels 25 Shades', 'category': 'Stationery', 'unit': 'Box', 'qty': 1.0, 'price': 110.0},
  {'name': 'Camlin Water Color Kit 12 Shades', 'category': 'Stationery', 'unit': 'Box', 'qty': 1.0, 'price': 140.0},
  {'name': 'Faber-Castell Color Pencils 24 Shades', 'category': 'Stationery', 'unit': 'Box', 'qty': 1.0, 'price': 180.0},
  {'name': 'Faber-Castell Highlighters Pack of 4', 'category': 'Stationery', 'unit': 'Pack', 'qty': 1.0, 'price': 120.0},
  {'name': 'Classmate Geometry Mathematical Box', 'category': 'Stationery', 'unit': 'Pcs', 'qty': 1.0, 'price': 125.0},
  {'name': 'Fevicol MR Synthetic Glue 100g', 'category': 'Stationery', 'unit': 'Gram', 'qty': 100.0, 'price': 45.0},
  {'name': 'Fevistick Glue Stick 15g', 'category': 'Stationery', 'unit': 'Pcs', 'qty': 1.0, 'price': 30.0},
  {'name': 'A4 Printer Paper Ream 500 Sheets', 'category': 'Stationery', 'unit': 'Pack', 'qty': 1.0, 'price': 280.0},
  {'name': 'Sticky Notes Yellow Pad 100 Sheets', 'category': 'Stationery', 'unit': 'Pcs', 'qty': 1.0, 'price': 40.0},
  {'name': 'Office Scissors Stainless Steel', 'category': 'Stationery', 'unit': 'Pcs', 'qty': 1.0, 'price': 75.0},
  {'name': 'Casio Basic Calculator MJ-12D', 'category': 'Stationery', 'unit': 'Pcs', 'qty': 1.0, 'price': 450.0},

  // ==================== PERSONAL CARE ====================
  {'name': 'Dove Beauty Cream Soap Bar', 'category': 'Personal Care', 'unit': 'Gram', 'qty': 125.0, 'price': 62.0},
  {'name': 'Dettol Original Bathing Soap Bar', 'category': 'Personal Care', 'unit': 'Gram', 'qty': 125.0, 'price': 45.0},
  {'name': 'Pears Pure & Gentle Soap Bar', 'category': 'Personal Care', 'unit': 'Gram', 'qty': 125.0, 'price': 58.0},
  {'name': 'Lux Velvet Touch Soap Bar', 'category': 'Personal Care', 'unit': 'Gram', 'qty': 125.0, 'price': 40.0},
  {'name': 'Santoor Sandalwood Soap Bar', 'category': 'Personal Care', 'unit': 'Gram', 'qty': 125.0, 'price': 42.0},
  {'name': 'Colgate MaxFresh Gel Toothpaste', 'category': 'Personal Care', 'unit': 'Gram', 'qty': 150.0, 'price': 110.0},
  {'name': 'Colgate Strong Teeth Toothpaste', 'category': 'Personal Care', 'unit': 'Gram', 'qty': 200.0, 'price': 115.0},
  {'name': 'Sensodyne Rapid Relief Toothpaste', 'category': 'Personal Care', 'unit': 'Gram', 'qty': 100.0, 'price': 160.0},
  {'name': 'Pepsodent Germicheck Toothpaste', 'category': 'Personal Care', 'unit': 'Gram', 'qty': 150.0, 'price': 85.0},
  {'name': 'Oral-B Soft Toothbrush', 'category': 'Personal Care', 'unit': 'Pcs', 'qty': 1.0, 'price': 35.0},
  {'name': 'Himalaya Purifying Neem Face Wash', 'category': 'Personal Care', 'unit': 'Ml', 'qty': 100.0, 'price': 140.0},
  {'name': 'Garnier Bright Complete Face Wash', 'category': 'Personal Care', 'unit': 'Ml', 'qty': 100.0, 'price': 160.0},
  {'name': 'Nivea Soft Light Moisturiser Cream', 'category': 'Personal Care', 'unit': 'Ml', 'qty': 100.0, 'price': 190.0},
  {'name': 'Vaseline Intensive Care Lotion', 'category': 'Personal Care', 'unit': 'Ml', 'qty': 400.0, 'price': 310.0},
  {'name': 'Pantene Hairfall Control Shampoo', 'category': 'Personal Care', 'unit': 'Ml', 'qty': 340.0, 'price': 260.0},
  {'name': 'Head & Shoulders Shampoo', 'category': 'Personal Care', 'unit': 'Ml', 'qty': 340.0, 'price': 280.0},
  {'name': 'Sunsilk Black Shine Shampoo', 'category': 'Personal Care', 'unit': 'Ml', 'qty': 340.0, 'price': 240.0},
  {'name': 'Tresemme Keratin Smooth Shampoo', 'category': 'Personal Care', 'unit': 'Ml', 'qty': 340.0, 'price': 310.0},
  {'name': 'Parachute Coconut Hair Oil', 'category': 'Personal Care', 'unit': 'Ml', 'qty': 300.0, 'price': 135.0},
  {'name': 'Gillette Mach 3 Razor', 'category': 'Personal Care', 'unit': 'Pcs', 'qty': 1.0, 'price': 250.0},
  {'name': 'Fogg Body Spray Deodorant', 'category': 'Personal Care', 'unit': 'Ml', 'qty': 120.0, 'price': 220.0},

  // ==================== SNACKS ====================
  {'name': 'Haldiram Alu Bhujia Namkeen', 'category': 'Snacks', 'unit': 'Gram', 'qty': 200.0, 'price': 60.0},
  {'name': 'Haldiram Khatta Meetha Mix', 'category': 'Snacks', 'unit': 'Gram', 'qty': 400.0, 'price': 95.0},
  {'name': 'Lay\'s Potato Chips Magic Masala', 'category': 'Snacks', 'unit': 'Pack', 'qty': 1.0, 'price': 20.0},
  {'name': 'Lay\'s Spanish Tomato Chips', 'category': 'Snacks', 'unit': 'Pack', 'qty': 1.0, 'price': 20.0},
  {'name': 'Kurkure Masala Munch Crunchy', 'category': 'Snacks', 'unit': 'Pack', 'qty': 1.0, 'price': 20.0},
  {'name': 'Bingo Mad Angles Cheese Nachos', 'category': 'Snacks', 'unit': 'Pack', 'qty': 1.0, 'price': 20.0},
  {'name': 'Uncle Chipps Spicy Treat', 'category': 'Snacks', 'unit': 'Pack', 'qty': 1.0, 'price': 20.0},
  {'name': 'Parle-G Glucose Biscuits', 'category': 'Snacks', 'unit': 'Gram', 'qty': 250.0, 'price': 30.0},
  {'name': 'Parle Monaco Salted Crackers', 'category': 'Snacks', 'unit': 'Gram', 'qty': 200.0, 'price': 25.0},
  {'name': 'Britannia Good Day Cashew Cookies', 'category': 'Snacks', 'unit': 'Gram', 'qty': 200.0, 'price': 40.0},
  {'name': 'Britannia Bourbon Chocolate Biscuits', 'category': 'Snacks', 'unit': 'Gram', 'qty': 150.0, 'price': 35.0},
  {'name': 'Cadbury Dairy Milk Silk Chocolate', 'category': 'Snacks', 'unit': 'Gram', 'qty': 60.0, 'price': 80.0},
  {'name': 'Cadbury 5 Star Chocolate Bar', 'category': 'Snacks', 'unit': 'Pcs', 'qty': 1.0, 'price': 20.0},
  {'name': 'KitKat Chocolate Wafer', 'category': 'Snacks', 'unit': 'Pcs', 'qty': 1.0, 'price': 30.0},
  {'name': 'Oreo Chocolate Cream Biscuit', 'category': 'Snacks', 'unit': 'Gram', 'qty': 120.0, 'price': 35.0},

  // ==================== DRINK ====================
  {'name': 'Tata Tea Gold Leaf Premium', 'category': 'Drink', 'unit': 'Gram', 'qty': 500.0, 'price': 310.0},
  {'name': 'Red Label Natural Care Tea', 'category': 'Drink', 'unit': 'Gram', 'qty': 500.0, 'price': 320.0},
  {'name': 'Taj Mahal Premium Leaf Tea', 'category': 'Drink', 'unit': 'Gram', 'qty': 500.0, 'price': 380.0},
  {'name': 'Nescafe Classic Instant Coffee', 'category': 'Drink', 'unit': 'Gram', 'qty': 100.0, 'price': 340.0},
  {'name': 'Bru Instant Coffee Blend', 'category': 'Drink', 'unit': 'Gram', 'qty': 100.0, 'price': 210.0},
  {'name': 'Coca-Cola Soft Drink Bottle', 'category': 'Drink', 'unit': 'Litre', 'qty': 1.25, 'price': 65.0},
  {'name': 'Pepsi Carbonated Soft Drink', 'category': 'Drink', 'unit': 'Litre', 'qty': 1.25, 'price': 65.0},
  {'name': 'Sprite Lemon Soft Drink', 'category': 'Drink', 'unit': 'Litre', 'qty': 1.25, 'price': 65.0},
  {'name': 'Thums Up Soft Drink Bottle', 'category': 'Drink', 'unit': 'Litre', 'qty': 1.25, 'price': 65.0},
  {'name': 'Real 100% Mixed Fruit Juice', 'category': 'Drink', 'unit': 'Litre', 'qty': 1.0, 'price': 130.0},
  {'name': 'Tropicana Orange Juice', 'category': 'Drink', 'unit': 'Litre', 'qty': 1.0, 'price': 125.0},
  {'name': 'Paper Boat Aamras Mango Drink', 'category': 'Drink', 'unit': 'Ml', 'qty': 200.0, 'price': 30.0},
  {'name': 'Red Bull Energy Drink Can', 'category': 'Drink', 'unit': 'Ml', 'qty': 250.0, 'price': 125.0},
  {'name': 'Bisleri Packaged Drinking Water', 'category': 'Drink', 'unit': 'Litre', 'qty': 1.0, 'price': 20.0},

  // ==================== GENERAL ====================
  {'name': 'Amul Pasteurised Salted Butter', 'category': 'General', 'unit': 'Gram', 'qty': 100.0, 'price': 58.0},
  {'name': 'Amul Taaza T-Special Fresh Milk', 'category': 'General', 'unit': 'Litre', 'qty': 1.0, 'price': 54.0},
  {'name': 'Amul Gold Full Cream Milk', 'category': 'General', 'unit': 'Litre', 'qty': 1.0, 'price': 66.0},
  {'name': 'Paneer Fresh Malai Block', 'category': 'General', 'unit': 'Gram', 'qty': 200.0, 'price': 90.0},
  {'name': 'Curd Dahi Tub Masti', 'category': 'General', 'unit': 'Gram', 'qty': 400.0, 'price': 45.0},
  {'name': 'Brown Whole Wheat Bread', 'category': 'General', 'unit': 'Gram', 'qty': 400.0, 'price': 45.0},
  {'name': 'White Sandwich Bread', 'category': 'General', 'unit': 'Gram', 'qty': 400.0, 'price': 35.0},
  {'name': 'Farm Fresh Eggs Box', 'category': 'General', 'unit': 'Pcs', 'qty': 6.0, 'price': 48.0},
  {'name': 'Surf Excel Easy Wash Detergent Powder', 'category': 'General', 'unit': 'Kg', 'qty': 1.0, 'price': 140.0},
  {'name': 'Vim Dishwash Gel Lemon Bottle', 'category': 'General', 'unit': 'Ml', 'qty': 500.0, 'price': 120.0},
  {'name': 'Harpic Toilet Cleaner Liquid Blue', 'category': 'General', 'unit': 'Ml', 'qty': 500.0, 'price': 95.0},
  {'name': 'Lizol Disinfectant Floor Cleaner Citrus', 'category': 'General', 'unit': 'Litre', 'qty': 1.0, 'price': 190.0},
  {'name': 'Colin Glass & Surface Cleaner Spray', 'category': 'General', 'unit': 'Ml', 'qty': 500.0, 'price': 105.0},
  {'name': 'Good Knight Mosquito Refill Twin', 'category': 'General', 'unit': 'Pcs', 'qty': 2.0, 'price': 150.0},
  {'name': 'Comfort After Wash Fabric Conditioner', 'category': 'General', 'unit': 'Ml', 'qty': 860.0, 'price': 235.0},
];

Future<void> main() async {
  print('================================================================');
  print('Deleting ALL Existing Products & Seeding Clean Exact Formatting for User: $targetUser');
  print('================================================================\n');

  // 1. Delete all products for user 7400700500
  print('Deleting all records from wallet_products for user $targetUser...');
  await executeTarget('DELETE FROM wallet_products WHERE user_id = \$1;', [targetUser]);
  print('Successfully cleared previous products for user $targetUser!\n');

  int idCounter = 1;
  final now = DateTime.now().millisecondsSinceEpoch;

  for (final p in rawMasterCatalog) {
    final insertSql = '''
      INSERT INTO wallet_products (id, user_id, "productName", "localName", category, unit, quantity, "currentPrice", "oldPrice", "appName", "referenceLink", active, deleted, updated_at, last_updated_by)
      VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, 1, 0, \$12, 'clean_exact_format_v2');
    ''';

    final name = p['name'] as String;
    final category = p['category'] as String;
    final local = getLocalName(name);
    final unit = p['unit'] as String;
    final qty = (p['qty'] as num).toDouble();
    final price = (p['price'] as num).toDouble();

    final params = [
      idCounter.toString(),
      targetUser,
      name,
      local,
      category,
      unit,
      qty,
      price,
      price,
      'Zepto',
      'https://zepto.co/search?q=${Uri.encodeComponent(name)}',
      now,
    ];

    try {
      await executeTarget(insertSql, params);
      print('  [✓] $name | $category ${local.isNotEmpty ? "| $local" : ""}');
      idCounter++;
    } catch (e) {
      print('  [!] Error inserting $name: $e');
    }
  }

  print('\n================================================================');
  print('Successfully inserted ${rawMasterCatalog.length} clean exact-formatted products for User: $targetUser!');
  print('================================================================');
}
