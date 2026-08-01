import 'dart:convert';
import 'package:http/http.dart' as http;

class HinglishTranslator {
  static const Map<String, Map<String, String>> _staticDb = {
    // Relationships & Common terms
    'brother': {'hi': 'भाई', 'en': 'Bhai'},
    'sister': {'hi': 'बहन', 'en': 'Behan'},
    'mother': {'hi': 'माता', 'en': 'Mata'},
    'father': {'hi': 'पिता', 'en': 'Pita'},
    'friend': {'hi': 'दोस्त', 'en': 'Dost'},
    'shop': {'hi': 'दुकान', 'en': 'Dukaan'},
    'money': {'hi': 'पैसा', 'en': 'Paisa'},

    // Vegetables
    'potato': {'hi': 'आलू', 'en': 'Aloo'},
    'potatoes': {'hi': 'आलू', 'en': 'Aloo'},
    'tomato': {'hi': 'टमाटर', 'en': 'Tamatar'},
    'tomatoes': {'hi': 'टमाटर', 'en': 'Tamatar'},
    'onion': {'hi': 'प्याज', 'en': 'Pyaz'},
    'onions': {'hi': 'प्याज', 'en': 'Pyaz'},
    'garlic': {'hi': 'लहसुन', 'en': 'Lahsun'},
    'ginger': {'hi': 'अदरक', 'en': 'Adrak'},
    'spinach': {'hi': 'पालक', 'en': 'Palak'},
    'cauliflower': {'hi': 'फूलगोभी', 'en': 'Phool Gobi'},
    'cabbage': {'hi': 'पत्तागोभी', 'en': 'Patta Gobi'},
    'brinjal': {'hi': 'बैंगन', 'en': 'Baingan'},
    'eggplant': {'hi': 'बैंगन', 'en': 'Baingan'},
    'lady finger': {'hi': 'भिंडी', 'en': 'Bhindi'},
    'okra': {'hi': 'भिंडी', 'en': 'Bhindi'},
    'green peas': {'hi': 'हरी मटर', 'en': 'Hari Matar'},
    'peas': {'hi': 'मटर', 'en': 'Matar'},
    'cucumber': {'hi': 'खीरा', 'en': 'Kheera'},
    'carrot': {'hi': 'गाजर', 'en': 'Gajar'},
    'radish': {'hi': 'मूली', 'en': 'Mooli'},
    'bottle gourd': {'hi': 'लौकी', 'en': 'Lauki'},
    'bitter gourd': {'hi': 'करेला', 'en': 'Karela'},
    'ridge gourd': {'hi': 'तरोई', 'en': 'Taroi'},
    'capsicum': {'hi': 'शिमला मिर्च', 'en': 'Shimla Mirch'},
    'bell pepper': {'hi': 'शिमला मिर्च', 'en': 'Shimla Mirch'},
    'green chilli': {'hi': 'हरी मिर्च', 'en': 'Hari Mirch'},
    'red chilli': {'hi': 'लाल मिर्च', 'en': 'Lal Mirch'},
    'chilli': {'hi': 'मिर्च', 'en': 'Mirch'},
    'chili': {'hi': 'मिर्च', 'en': 'Mirch'},
    'lemon': {'hi': 'नींबू', 'en': 'Nimbu'},
    'coriander': {'hi': 'हरा धनिया', 'en': 'Hara Dhaniya'},
    'mint': {'hi': 'पुदीना', 'en': 'Pudina'},
    'pumpkin': {'hi': 'कद्दू', 'en': 'Kaddu'},
    'sweet potato': {'hi': 'शकरकंद', 'en': 'Shakarkand'},
    'beetroot': {'hi': 'चुकंदर', 'en': 'Chukandar'},
    'mushroom': {'hi': 'मशरूम', 'en': 'Mushroom'},

    // Dairy & Pantry
    'milk': {'hi': 'दूध', 'en': 'Doodh'},
    'curd': {'hi': 'दही', 'en': 'Dahi'},
    'yogurt': {'hi': 'दही', 'en': 'Dahi'},
    'paneer': {'hi': 'पनीर', 'en': 'Paneer'},
    'cottage cheese': {'hi': 'पनीर', 'en': 'Paneer'},
    'butter': {'hi': 'मक्खन', 'en': 'Makhan'},
    'ghee': {'hi': 'घी', 'en': 'Ghee'},
    'cream': {'hi': 'मलाई', 'en': 'Malai'},
    'cheese': {'hi': 'चीज', 'en': 'Cheese'},
    'bread': {'hi': 'ब्रेड / रोटी', 'en': 'Bread / Roti'},
    'egg': {'hi': 'अंडा', 'en': 'Anda'},
    'eggs': {'hi': 'अंडे', 'en': 'Ande'},

    // Staples & Spices
    'rice': {'hi': 'चावल', 'en': 'Chawal'},
    'basmati rice': {'hi': 'बास्मती चावल', 'en': 'Basmati Chawal'},
    'wheat': {'hi': 'गेहूं / आटा', 'en': 'Gehun / Aata'},
    'flour': {'hi': 'आटा', 'en': 'Aata'},
    'atta': {'hi': 'आटा', 'en': 'Aata'},
    'sugar': {'hi': 'चीनी', 'en': 'Cheeni'},
    'salt': {'hi': 'नमक', 'en': 'Namak'},
    'oil': {'hi': 'तेल', 'en': 'Tel'},
    'mustard oil': {'hi': 'सरसों का तेल', 'en': 'Sarson Ka Tel'},
    'refined oil': {'hi': 'रिफाइंड तेल', 'en': 'Refined Tel'},
    'coconut oil': {'hi': 'नारियल का तेल', 'en': 'Nariyal Ka Tel'},
    'tea': {'hi': 'चाय', 'en': 'Chai'},
    'coffee': {'hi': 'कॉफी', 'en': 'Coffee'},
    'water': {'hi': 'पानी', 'en': 'Paani'},
    'turmeric': {'hi': 'हल्दी', 'en': 'Haldi'},
    'cumin': {'hi': 'जीरा', 'en': 'Jeera'},
    'mustard': {'hi': 'सरसों', 'en': 'Sarson'},

    // Fruits
    'apple': {'hi': 'सेब', 'en': 'Seb'},
    'banana': {'hi': 'केला', 'en': 'Kela'},
    'mango': {'hi': 'आम', 'en': 'Aam'},
    'orange': {'hi': 'संतरा', 'en': 'Santra'},
    'grapes': {'hi': 'अंगूर', 'en': 'Angoor'},
  };

  /// Converts any Devanagari Hindi text to Roman Hinglish (e.g. "भाई" -> "Bhai", "दूध" -> "Doodh")
  static String devanagariToHinglish(String devText) {
    if (devText.trim().isEmpty) return '';

    final StringBuffer result = StringBuffer();
    final runes = devText.runes.toList();

    for (int i = 0; i < runes.length; i++) {
      final char = String.fromCharCode(runes[i]);
      final nextChar = (i + 1 < runes.length) ? String.fromCharCode(runes[i + 1]) : '';

      switch (char) {
        // Consonants
        case 'क': result.write('k'); break;
        case 'ख': result.write('kh'); break;
        case 'ग': result.write('g'); break;
        case 'घ': result.write('gh'); break;
        case 'च': result.write('ch'); break;
        case 'छ': result.write('chh'); break;
        case 'ज': result.write('j'); break;
        case 'झ': result.write('jh'); break;
        case 'ट': result.write('t'); break;
        case 'ठ': result.write('th'); break;
        case 'ड': result.write('d'); break;
        case 'ढ': result.write('dh'); break;
        case 'ण': result.write('n'); break;
        case 'त': result.write('t'); break;
        case 'थ': result.write('th'); break;
        case 'द': result.write('d'); break;
        case 'ध': result.write('dh'); break;
        case 'न': result.write('n'); break;
        case 'प': result.write('p'); break;
        case 'फ': result.write('ph'); break;
        case 'ब': result.write('b'); break;
        case 'भ': result.write('bh'); break;
        case 'म': result.write('m'); break;
        case 'य': result.write('y'); break;
        case 'र': result.write('r'); break;
        case 'ल': result.write('l'); break;
        case 'व': result.write('v'); break;
        case 'श': result.write('sh'); break;
        case 'ष': result.write('sh'); break;
        case 'स': result.write('s'); break;
        case 'ह': result.write('h'); break;

        // Standalone Vowels
        case 'अ': result.write('A'); break;
        case 'आ': result.write('Aa'); break;
        case 'इ': result.write('I'); break;
        case 'ई': result.write('Ee'); break;
        case 'उ': result.write('U'); break;
        case 'ऊ': result.write('Oo'); break;
        case 'ए': result.write('E'); break;
        case 'ऐ': result.write('Ai'); break;
        case 'ओ': result.write('O'); break;
        case 'औ': result.write('Au'); break;

        // Vowel Signs / Matras
        case 'ा': result.write('a'); break;
        case 'ि': result.write('i'); break;
        case 'ी': result.write('i'); break;
        case 'ु': result.write('u'); break;
        case 'ू': result.write('oo'); break;
        case 'े': result.write('e'); break;
        case 'ै': result.write('ai'); break;
        case 'ो': result.write('o'); break;
        case 'ौ': result.write('au'); break;
        case 'ं': result.write('n'); break;
        case '्': break;

        default:
          result.write(char);
      }

      // Implicit vowel 'a' addition between consonants if no matra follows
      if (_isConsonant(char) && nextChar.isNotEmpty && _isConsonant(nextChar)) {
        result.write('a');
      }
    }

    final s = result.toString().trim();
    if (s.isEmpty) return devText;
    return s[0].toUpperCase() + s.substring(1);
  }

  static bool _isConsonant(String c) {
    const consonants = 'कखगघचछजझटठडढणतथदधनपफबभमयरलवशषसह';
    return consonants.contains(c);
  }

  /// Instant synchronous translator
  static String translateToHinglish(String englishName) {
    if (englishName.trim().isEmpty) return '';

    final cleanInput = englishName.trim().toLowerCase();

    // 1. Direct Static Match
    if (_staticDb.containsKey(cleanInput)) {
      final entry = _staticDb[cleanInput]!;
      return '${entry['hi']} (${entry['en']})';
    }

    // 2. Contains Sub-Phrase Match
    String? bestMatchKey;
    int maxLen = 0;
    _staticDb.forEach((key, val) {
      if (cleanInput.contains(key) && key.length > maxLen) {
        bestMatchKey = key;
        maxLen = key.length;
      }
    });

    if (bestMatchKey != null) {
      final entry = _staticDb[bestMatchKey!]!;
      return '${entry['hi']} (${entry['en']})';
    }

    // 3. Fallback Devanagari transliteration + Roman Hinglish
    final dev = _englishToDevanagari(cleanInput);
    final hinglish = devanagariToHinglish(dev);
    return '$dev ($hinglish)';
  }

  /// Dynamic Async Web Translator via Google Translate API
  /// Translates English -> Hindi, then transliterates Hindi -> Hinglish Roman script!
  /// Example: "brother" -> Hindi: "भाई", Hinglish: "Bhai" -> Result: "भाई (Bhai)"
  static Future<String> translateDynamic(String text) async {
    if (text.trim().isEmpty) return '';

    final clean = text.trim().toLowerCase();

    // Static check first
    if (_staticDb.containsKey(clean)) {
      final entry = _staticDb[clean]!;
      return '${entry['hi']} (${entry['en']})';
    }

    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=hi&dt=t&q=${Uri.encodeComponent(text.trim())}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty && data[0] is List && data[0].isNotEmpty) {
          final translatedHindi = data[0][0][0]?.toString();
          if (translatedHindi != null && translatedHindi.trim().isNotEmpty) {
            final devanagariText = translatedHindi.trim();
            final hinglishRoman = devanagariToHinglish(devanagariText);
            return '$devanagariText ($hinglishRoman)';
          }
        }
      }
    } catch (_) {
      // Network fallback
    }

    return translateToHinglish(text);
  }

  static String _englishToDevanagari(String text) {
    String s = text.toLowerCase();
    final rules = [
      ['sh', 'श'], ['ch', 'च'], ['kh', 'ख'], ['gh', 'घ'],
      ['jh', 'झ'], ['th', 'थ'], ['dh', 'ध'], ['bh', 'भ'],
      ['ph', 'फ'], ['aa', 'आ'], ['ee', 'ई'], ['oo', 'ऊ'],
      ['ai', 'ऐ'], ['au', 'औ'], ['k', 'क'], ['g', 'ग'],
      ['c', 'क'], ['j', 'ज'], ['t', 'त'], ['d', 'द'],
      ['n', 'न'], ['p', 'प'], ['b', 'ब'], ['m', 'म'],
      ['y', 'य'], ['r', 'र'], ['l', 'ल'], ['v', 'व'],
      ['w', 'व'], ['s', 'स'], ['h', 'ह'], ['a', 'आ'],
      ['i', 'इ'], ['u', 'उ'], ['e', 'ए'], ['o', 'ओ'],
    ];

    for (final rule in rules) {
      s = s.replaceAll(rule[0], rule[1]);
    }

    return s;
  }
}
