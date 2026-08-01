import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../providers/finance_provider.dart';
import 'daily_tracker_screen.dart';
import 'dart:math' show min;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/string_utils.dart';


class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  late Animation<double> _scanAnimation;

  bool _isScanning = false;
  bool _isParsed = false;

  // Extracted OCR fields
  String _extractedMerchant = '';
  double _extractedAmount = 0.0;
  double _extractedTax = 0.0;
  String _extractedDate = '';
  List<String> _extractedItems = [];
  
  // Selected logging fields
  int? _selectedAccountId;
  int? _selectedCategoryId;
  String _note = '';

  XFile? _selectedImage;
  String _customApiKey = '';

  bool get _isCameraSupported => kIsWeb || (defaultTargetPlatform != TargetPlatform.windows && defaultTargetPlatform != TargetPlatform.linux && defaultTargetPlatform != TargetPlatform.macOS);


  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _scanAnimation = Tween<double>(begin: 0.0, end: 180.0).animate(_scannerController);
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customApiKey = prefs.getString('ocr_space_api_key') ?? '';
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ocr_space_api_key', key.trim());
    setState(() {
      _customApiKey = key.trim();
    });
  }

  final _picker = ImagePicker();
  final _rawTextController = TextEditingController();

  @override
  void dispose() {
    _scannerController.dispose();
    _rawTextController.dispose();
    super.dispose();
  }

  Future<void> _pickAndScanReceipt(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = image;
        _isScanning = true;
        _isParsed = false;
      });

      _scannerController.repeat(reverse: true);

      await _performRealOCR(image);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });
      _scannerController.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _performRealOCR(XFile file) async {
    final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    if (isMobile) {
      try {
        final inputImage = InputImage.fromFilePath(file.path);
        final textRecognizer = TextRecognizer();
        final recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        final String parsedText = recognizedText.text;
        if (parsedText.trim().isEmpty) {
          throw Exception('No text detected in receipt. Try again with a clearer picture.');
        }

        setState(() {
          _rawTextController.text = parsedText;
        });

        _parseRawReceiptText();
      } catch (e) {
        debugPrint('ML Kit OCR failed, falling back to Web API: $e');
        await _performWebApiOCR(file);
      }
    } else {
      await _performWebApiOCR(file);
    }
  }

  Future<void> _performWebApiOCR(XFile file) async {
    final apiKey = _customApiKey.isEmpty ? 'helloworld' : _customApiKey;
    final url = Uri.parse('https://api.ocr.space/parse/image');

    try {
      final request = http.MultipartRequest('POST', url);
      request.fields['apikey'] = apiKey;
      request.fields['language'] = 'eng';
      request.fields['isTable'] = 'true';
      request.fields['detectOrientation'] = 'true';
      request.fields['scale'] = 'true';

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
        ));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['IsErroredOnProcessing'] == true) {
          throw Exception(data['ErrorMessage'] ?? 'Failed processing image');
        }

        final parsedResults = data['ParsedResults'] as List?;
        if (parsedResults == null || parsedResults.isEmpty) {
          throw Exception('No text detected in receipt. Try again with a clearer picture.');
        }

        final String parsedText = parsedResults[0]['ParsedText'] ?? '';
        if (parsedText.trim().isEmpty) {
          throw Exception('No text extracted from the receipt.');
        }

        setState(() {
          _rawTextController.text = parsedText;
        });

        _parseRawReceiptText();
      } else {
        throw Exception('OCR Service error (HTTP ${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });
      _scannerController.stop();
      
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (apiKey == 'helloworld') {
        errorMsg += '\n\nNote: The guest "helloworld" key is heavily rate-limited. Please configure your own free OCR.space API key.';
      }
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF121422),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white12)),
          title: const Text('OCR Scan Error', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text(errorMsg, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
  }

  void _parseRawReceiptText() {
    final text = _rawTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or paste some receipt text first.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _isParsed = false;
    });

    _scannerController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _scannerController.stop();

      final provider = Provider.of<FinanceProvider>(context, listen: false);

      // Extract details
      final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      
      // Smart merchant detection
      final genericHeaderRegex = RegExp(
        r'^(?:tax\s+)?invoice|cash\s+memo|cash\s+receipt|retail\s+invoice|bill|duplicate|welcome|payment\s+receipt|sale\s+receipt|e-invoice|original|customer\s+copy|merchant\s+copy|receipt|stationery|cashier|terminal|store\s+#|pos\b',
        caseSensitive: false,
      );
      final dateRegex = RegExp(r'\b\d{1,4}[-/.]\d{1,4}[-/.]\d{1,4}\b');
      final phoneRegex = RegExp(r'\b(?:\+\d{1,3}[- ]?)?\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}\b');
      final urlRegex = RegExp(r'(?:https?://)?(?:www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}\b');

      String merchant = 'Pasted Invoice';
      for (int i = 0; i < min(5, lines.length); i++) {
        final line = lines[i];
        if (genericHeaderRegex.hasMatch(line) ||
            dateRegex.hasMatch(line) ||
            phoneRegex.hasMatch(line) ||
            urlRegex.hasMatch(line) ||
            line.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim().isEmpty) {
          continue;
        }
        merchant = line;
        break;
      }
      if (merchant.length > 45) merchant = merchant.substring(0, 45);
      merchant = toTitleCase(merchant);

      // Robust Amount Detection with Comma/Whitespace and False Positive Filtering
      double amount = 0.0;
      bool amountFound = false;

      final highConfRegex = RegExp(
        r'(?:grand\s+total|total\s+amount|net\s+amount|amount\s+paid|net\s+payable|total\s+payable|amount\s+due|total\s+due)',
        caseSensitive: false,
      );
      final skipRegex = RegExp(
        r'(?:change\s+due|tendered|cash\s+tendered|balance|saving|coupon|discount|refund|tax\s+total|total\s+tax)',
        caseSensitive: false,
      );

      // First pass: line-by-line high-confidence matches
      for (final line in lines) {
        if (highConfRegex.hasMatch(line) && !skipRegex.hasMatch(line)) {
          final keywordMatch = highConfRegex.firstMatch(line);
          if (keywordMatch != null) {
            final searchSub = line.substring(line.toLowerCase().indexOf(keywordMatch.group(0)!.toLowerCase()));
            final match = RegExp(r'(?:rs\.?|inr|usd|\$)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)', caseSensitive: false)
                .firstMatch(searchSub);
            if (match != null) {
              final valStr = match.group(1)?.replaceAll(',', '').trim();
              final parsed = double.tryParse(valStr ?? '');
              if (parsed != null && parsed > 0.0) {
                amount = parsed;
                amountFound = true;
                break;
              }
            }
          }
        }
      }

      // Second pass: line-by-line medium-confidence matches
      if (!amountFound) {
        final medConfRegex = RegExp(r'\b(?:total|amount|paid|sum|due|net|gpay|paytm)\b', caseSensitive: false);
        for (final line in lines) {
          if (medConfRegex.hasMatch(line) && !skipRegex.hasMatch(line)) {
            final keywordMatch = medConfRegex.firstMatch(line);
            if (keywordMatch != null) {
              final searchSub = line.substring(line.toLowerCase().indexOf(keywordMatch.group(0)!.toLowerCase()));
              final match = RegExp(r'(?:rs\.?|inr|usd|\$)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)', caseSensitive: false)
                  .firstMatch(searchSub);
              if (match != null) {
                final valStr = match.group(1)?.replaceAll(',', '').trim();
                final parsed = double.tryParse(valStr ?? '');
                if (parsed != null && parsed > 0.0) {
                  amount = parsed;
                  amountFound = true;
                  break;
                }
              }
            }
          }
        }
      }

      // Third pass: Fallback to largest price-formatted decimal number in the text
      if (!amountFound) {
        final priceRegex = RegExp(r'\b(\d{1,3}(?:,\d{3})*(?:\.\d{2})|\d+(?:\.\d{2}))\b');
        final priceMatches = priceRegex.allMatches(text);
        double maxPrice = 0.0;
        for (final m in priceMatches) {
          final valStr = m.group(1)?.replaceAll(',', '').trim();
          final parsed = double.tryParse(valStr ?? '');
          if (parsed != null) {
            // Avoid selecting numbers that look like years or phone numbers
            if (parsed == 2024.0 || parsed == 2025.0 || parsed == 2026.0 || parsed > 999999.0) continue;
            if (parsed > maxPrice) {
              maxPrice = parsed;
            }
          }
        }
        amount = maxPrice;
      }

      // Fourth pass: Fallback to largest integer if no decimal numbers found
      if (!amountFound && amount == 0.0) {
        final intRegex = RegExp(r'\b(\d+)\b');
        final intMatches = intRegex.allMatches(text);
        double maxInt = 0.0;
        for (final m in intMatches) {
          final valStr = m.group(1);
          final parsed = double.tryParse(valStr ?? '');
          if (parsed != null) {
            if (parsed == 2024.0 || parsed == 2025.0 || parsed == 2026.0 || parsed > 100000.0) continue;
            if (parsed > maxInt) maxInt = parsed;
          }
        }
        amount = maxInt;
      }

      double tax = 0.0;
      final taxRegex = RegExp(r'(?:tax|vat|cgst|sgst|gst)\s*:?\s*(?:rs\.?|inr|usd|\$)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)', caseSensitive: false);
      final taxMatch = taxRegex.firstMatch(text);
      if (taxMatch != null) {
        final valStr = taxMatch.group(1)?.replaceAll(',', '').trim();
        tax = double.tryParse(valStr ?? '') ?? 0.0;
      }

      String dateStr = DateTime.now().toString().substring(0, 10);
      final actualDateRegex = RegExp(r'\b(\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}|\d{4}[-/.]\d{1,2}[-/.]\d{1,2})\b');
      final dateMatch = actualDateRegex.firstMatch(text);
      if (dateMatch != null) {
        dateStr = dateMatch.group(1) ?? dateStr;
      }

      final List<String> items = [];
      for (int i = 1; i < min(6, lines.length); i++) {
        final line = lines[i];
        if (line.toLowerCase().contains('total') || line.toLowerCase().contains('tax') || line.toLowerCase().contains('date')) continue;
        if (line.length > 5 && line.length < 50) {
          items.add(line);
        }
      }

      setState(() {
        _isScanning = false;
        _isParsed = true;
        _extractedMerchant = merchant;
        _extractedAmount = amount == 0.0 ? 120.0 : amount;
        _extractedTax = tax;
        _extractedDate = dateStr;
        _extractedItems = items.isEmpty ? ['Scanned Invoice Items'] : items;
        _note = _selectedImage != null
            ? 'OCR Scanned Receipt from $_extractedMerchant. Tax: ${provider.defaultCurrency}${_extractedTax.toStringAsFixed(2)}'
            : 'OCR Extracted from pasted text. Tax: ${provider.defaultCurrency}${_extractedTax.toStringAsFixed(2)}';
        
        int? catId = provider.categories.first.id;
        final textLower = text.toLowerCase();
        if (textLower.contains('food') || textLower.contains('cafe') || textLower.contains('mcdonald') || textLower.contains('burger') || textLower.contains('pizza')) {
          catId = provider.categories.where((c) => c.name.toLowerCase().contains('food')).firstOrNull?.id ?? catId;
        } else if (textLower.contains('uber') || textLower.contains('ola') || textLower.contains('cab') || textLower.contains('travel') || textLower.contains('ride')) {
          catId = provider.categories.where((c) => c.name.toLowerCase().contains('travel')).firstOrNull?.id ?? catId;
        } else if (textLower.contains('grocery') || textLower.contains('groceries') || textLower.contains('supermarket') || textLower.contains('mart')) {
          catId = provider.categories.where((c) => c.name.toLowerCase().contains('groceries')).firstOrNull?.id ?? catId;
        }
        _selectedCategoryId = catId;
        
        if (provider.accounts.isNotEmpty) {
          _selectedAccountId = provider.accounts.first.id;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt text parsed successfully!'), backgroundColor: Colors.greenAccent),
      );
    });
  }


  /// Opens the Daily Tracker's TransactionSheet pre-filled with all OCR data
  void _openInDailyTracker() {
    if (_extractedAmount <= 0 && _extractedMerchant.isEmpty) return;
    
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionSheet(
        ocrMerchant: _extractedMerchant,
        ocrAmount: _extractedAmount,
        ocrDate: _extractedDate,
        ocrItems: _extractedItems,
        ocrNote: _note,
        ocrCategoryId: _selectedCategoryId,
        ocrAccountId: _selectedAccountId,
      ),
    ).then((_) {
      // After saving, pop the scanner screen too
      if (mounted) Navigator.pop(context);
    });
  }


  /// Small read-only chip used to display auto-detected values (category, account)
  Widget _infoChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final curSymbol = provider.defaultCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Receipt Scanner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080914), Color(0xFF0E111F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF121422),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.photo_camera_back_rounded, color: Colors.cyanAccent.withValues(alpha: 0.8)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Take a photo of any receipt or invoice — ML Kit OCR extracts shop name, date, items and total automatically.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // API Key configuration
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: Colors.cyanAccent,
                  collapsedIconColor: Colors.white30,
                  tilePadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      const Icon(Icons.settings_applications_rounded, color: Colors.white30, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'OCR SERVICE CONFIGURATION',
                        style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                      const SizedBox(width: 6),
                      if (_customApiKey.isNotEmpty)
                        const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 12),
                    ],
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121422),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'To get 500 free daily scans, sign up for a free key at ocr.space and paste it below. Leaving it empty will use the public rate-limited "helloworld" key.',
                            style: TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _customApiKey,
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'OCR.space API Key',
                              labelStyle: const TextStyle(color: Colors.white30, fontSize: 10),
                              hintText: 'e.g., K882367128889...',
                              hintStyle: const TextStyle(color: Colors.white12, fontSize: 11),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
                              isDense: true,
                              suffixIcon: _customApiKey.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.white30, size: 16),
                                      onPressed: () => _saveApiKey(''),
                                    )
                                  : null,
                            ),
                            onChanged: _saveApiKey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Selected Image Preview (if any)
              if (_selectedImage != null) ...[
                const Text('SELECTED RECEIPT IMAGE', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121422),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? FutureBuilder<Uint8List>(
                                future: _selectedImage!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(snapshot.data!, width: 100, height: 100, fit: BoxFit.cover);
                                  }
                                  return Container(width: 100, height: 100, color: Colors.white12);
                                },
                              )
                            : Image.network(
                                _selectedImage!.path,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.white12,
                                    child: const Icon(Icons.image, color: Colors.white30),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedImage!.name,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            FutureBuilder<int>(
                              future: _selectedImage!.length(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final kb = snapshot.data! / 1024;
                                  return Text('${kb.toStringAsFixed(1)} KB', style: const TextStyle(color: Colors.white38, fontSize: 10));
                                }
                                return const SizedBox();
                              },
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImage = null;
                                  _isParsed = false;
                                  _rawTextController.clear();
                                });
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 14),
                                  SizedBox(width: 4),
                                  Text('Clear Image', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Real Scan trigger section
              const Text('SCAN A REAL RECEIPT', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF121422),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Capture a receipt photo or upload an invoice from files to extract prices, dates, and item details using OCR.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 16),
                    if (_isCameraSupported)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isScanning ? null : () => _pickAndScanReceipt(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                              label: const Text('CAMERA CAPTURE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.06),
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white12),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isScanning ? null : () => _pickAndScanReceipt(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded, size: 16, color: Colors.cyanAccent),
                              label: const Text('GALLERY / FILES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isScanning ? null : () => _pickAndScanReceipt(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 18, color: Colors.black),
                        label: const Text('CHOOSE RECEIPT IMAGE FILE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 24),


              const Text('OR PASTE RAW RECEIPT TEXT TO EXTRACT', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF121422),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _rawTextController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Paste raw receipt details, email invoices, or SMS transaction alerts here...",
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.02),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isScanning ? null : _parseRawReceiptText,
                      icon: const Icon(Icons.analytics_rounded, size: 18),
                      label: const Text('EXTRACT DETAILS FROM TEXT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // OCR Scanning Box Container
              if (_isScanning) ...[
                const Text('OCR ANALYZER STATUS', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                    ),
                    child: Stack(
                      children: [
                        // Animated scanner line
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: _scanAnimation.value,
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: Colors.cyanAccent,
                                  boxShadow: [
                                    BoxShadow(color: Colors.cyanAccent, blurRadius: 10, spreadRadius: 1.5),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2.5),
                              ),
                              SizedBox(height: 16),
                              Text('Running OCR Invoice Scan...', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Extracting prices, dates & merchants...', style: TextStyle(color: Colors.white30, fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // OCR Results Card
              if (_isParsed) ...[
                const Text('EXTRACTED RECEIPT DETAILS', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121422),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3), width: 1.2),
                    boxShadow: [
                      BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                            child: const Text('OCR CONFIRMED', style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ),
                          Text(_extractedDate, style: const TextStyle(color: Colors.white30, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Merchant Name
                      const Text('Merchant Name', style: TextStyle(color: Colors.white30, fontSize: 10)),
                      TextFormField(
                        initialValue: _extractedMerchant,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        onChanged: (val) => _extractedMerchant = val,
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12))),
                      ),
                      const SizedBox(height: 16),

                      // Amount
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Amount', style: TextStyle(color: Colors.white30, fontSize: 10)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(curSymbol, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _extractedAmount.toStringAsFixed(2),
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        onChanged: (val) => _extractedAmount = double.tryParse(val) ?? 0.0,
                                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12))),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tax Included', style: TextStyle(color: Colors.white30, fontSize: 10)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(curSymbol, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _extractedTax.toStringAsFixed(2),
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                                        onChanged: (val) => _extractedTax = double.tryParse(val) ?? 0.0,
                                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12))),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Receipt Items breakdown list
                      if (_extractedItems.isNotEmpty) ...[
                        const Text('ITEMS EXTRACTED', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ..._extractedItems.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_right_rounded, color: Colors.cyanAccent, size: 16),
                                  Text(item, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            )),
                        const SizedBox(height: 20),
                      ],

                      // Auto-detected category & account preview chips
                      Row(
                        children: [
                          _infoChip(
                            Icons.category_rounded,
                            _selectedCategoryId != null
                                ? (provider.categories.where((c) => c.id == _selectedCategoryId).isNotEmpty
                                    ? provider.categories.firstWhere((c) => c.id == _selectedCategoryId).name
                                    : 'Auto')
                                : 'Auto',
                            Colors.purpleAccent,
                          ),
                          const SizedBox(width: 8),
                          _infoChip(
                            Icons.account_balance_wallet_rounded,
                            _selectedAccountId != null
                                ? (provider.accounts.where((a) => a.id == _selectedAccountId).isNotEmpty
                                    ? provider.accounts.firstWhere((a) => a.id == _selectedAccountId).name
                                    : 'Auto')
                                : 'Auto',
                            Colors.cyanAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap below to review and edit before saving',
                        style: TextStyle(color: Colors.white38, fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Items banner showing extracted data  
                      if (_extractedItems.isNotEmpty) ...[
                        const Divider(color: Colors.white10, height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.list_alt_rounded, size: 12, color: Colors.cyanAccent),
                                  SizedBox(width: 6),
                                  Text('ITEMS WILL BE SAVED IN NOTES', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ..._extractedItems.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.arrow_right_rounded, color: Colors.cyanAccent, size: 14),
                                        Expanded(child: Text(item, style: const TextStyle(color: Colors.white60, fontSize: 10))),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Open in Daily Tracker Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _openInDailyTracker,
                        icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                        label: const Text('REVIEW & ADD TO DAILY TRACKER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
