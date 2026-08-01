import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';
import '../models/wallet_account.dart';
import '../utils/string_utils.dart';
import 'dart:math';

class UpiPaymentScreen extends StatefulWidget {
  const UpiPaymentScreen({super.key});

  @override
  State<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends State<UpiPaymentScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  // Use TextEditingControllers so QR data updates live in the form
  final _vpaController = TextEditingController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _qrUrlController = TextEditingController();

  int? _selectedAccountId;

  // Payment step tracking
  String _activeStep = 'setup'; // 'setup' | 'awaiting_confirm' | 'success' | 'cancelled'
  String _refId = '';
  bool _paymentLaunched = false; // true while waiting for user to return from UPI app

  // QR scanner
  bool _qrScannerActive = false;
  MobileScannerController? _qrController;

  // Recent contacts (session-scoped)
  final List<Map<String, String>> _savedContacts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _vpaController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    _qrUrlController.dispose();
    _qrController?.dispose();
    super.dispose();
  }

  // ── App Lifecycle: detect return from UPI app ─────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _paymentLaunched) {
      _paymentLaunched = false;
      // Give a moment for the UI to settle, then ask confirmation
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _showPaymentConfirmDialog();
      });
    }
  }

  void _showPaymentConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121422),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: const Text(
          'Payment Status',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Did your UPI payment to ${_nameController.text.isEmpty ? _vpaController.text : _nameController.text} complete successfully?',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Amount: ${_getSymbol()}${_amountController.text}\nUPI ID: ${_vpaController.text}\nRef: $_refId',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _logTransaction(confirmed: false);
              setState(() => _activeStep = 'cancelled');
            },
            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
            label: const Text('No, Failed', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _logTransaction(confirmed: true);
              setState(() => _activeStep = 'success');
            },
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('Yes, Paid!', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  String _getSymbol() {
    if (!mounted) return '₹';
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    return provider.defaultCurrency;
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool _validateForm() {
    if (_vpaController.text.isEmpty || !_vpaController.text.contains('@')) {
      _snack('Enter a valid UPI ID (e.g. name@ybl)', Colors.redAccent);
      return false;
    }
    if ((double.tryParse(_amountController.text) ?? 0) <= 0) {
      _snack('Enter a valid amount greater than 0', Colors.redAccent);
      return false;
    }
    if (_selectedAccountId == null) {
      _snack('Select a wallet account to debit', Colors.redAccent);
      return false;
    }
    return true;
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ── UPI Launch ────────────────────────────────────────────────────────────

  static const _platform = MethodChannel('com.example.my_wallet/upi');

  Future<List<Map<String, String>>> _getInstalledUpiApps() async {
    try {
      final List<dynamic>? result = await _platform.invokeMethod('getInstalledUpiApps');
      if (result != null) {
        return result.map((item) => Map<String, String>.from(item as Map)).toList();
      }
    } catch (e) {
      debugPrint('Error checking installed UPI apps: $e');
    }
    return [];
  }

  Future<String?> _launchDirectUpi(String uriString, String? packageName) async {
    try {
      final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;
      if (isAndroid && !kIsWeb) {
        final String? response = await _platform.invokeMethod<String>('launchUpiApp', {
          'uri': uriString,
          'packageName': packageName,
        });
        _saveRecentContact(_nameController.text.trim(), _vpaController.text.trim());
        return response;
      } else {
        final launched = await launchUrl(
          Uri.parse(uriString),
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          _saveRecentContact(_nameController.text.trim(), _vpaController.text.trim());
          return 'status=launched_external';
        } else {
          return 'status=failed';
        }
      }
    } catch (e) {
      debugPrint('Error launching UPI app: $e');
      return 'status=failed&error=${Uri.encodeComponent(e.toString())}';
    }
  }

  void _handleUpiResponse(String response) {
    debugPrint('Received UPI payment response: $response');
    
    final Map<String, String> params = {};
    try {
      final pairs = response.split('&');
      for (final pair in pairs) {
        final idx = pair.indexOf('=');
        if (idx != -1) {
          final key = pair.substring(0, idx).toLowerCase().trim();
          final val = pair.substring(idx + 1).trim();
          params[key] = val;
        }
      }
    } catch (e) {
      debugPrint('Error parsing UPI response: $e');
    }

    final status = (params['status'] ?? '').toLowerCase();
    final responseCode = params['responsecode'] ?? '';

    // '00' is the standard successful transaction response code for UPI
    final bool isSuccess = status == 'success' || responseCode == '00';
    final bool isCancelled = status == 'cancelled' || responseCode == '92';

    if (isSuccess) {
      _logTransaction(confirmed: true);
      setState(() {
        _activeStep = 'success';
      });
      _snack('Payment Completed Successfully!', const Color(0xFF10B981));
    } else {
      _logTransaction(confirmed: false);
      setState(() {
        _activeStep = 'cancelled';
      });
      if (isCancelled) {
        _snack('Payment Cancelled by User', Colors.orangeAccent);
      } else {
        _snack('Payment Failed: ${params['status'] ?? 'declined'}', Colors.redAccent);
      }
    }
  }

  void _saveRecentContact(String name, String vpa) {
    if (name.isNotEmpty && vpa.isNotEmpty) {
      setState(() {
        _savedContacts.removeWhere((c) => c['vpa'] == vpa);
        _savedContacts.insert(0, {'name': name, 'vpa': vpa});
        if (_savedContacts.length > 10) _savedContacts.removeLast();
      });
    }
  }

  Future<void> _launchUPI() async {
    if (!_validateForm()) return;

    final vpa = _vpaController.text.trim();
    final name = _nameController.text.trim();
    final amount = _amountController.text.trim();
    final remarks = _remarksController.text.trim();

    final cleanName = Uri.encodeComponent(name.isEmpty ? 'Payee' : name);
    final cleanRemarks = Uri.encodeComponent(remarks.isEmpty ? 'My Wallet Transfer' : remarks);
    _refId = List.generate(12, (_) => Random().nextInt(10).toString()).join();

    final bool isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;

    // On iOS, BHIM app deep links use the bhim://upi/pay format, whereas standard UPI uses upi://pay
    final String upiUriString = isIos
        ? 'bhim://upi/pay?pa=$vpa&pn=$cleanName&am=$amount&cu=INR&tn=$cleanRemarks&tr=$_refId'
        : 'upi://pay?pa=$vpa&pn=$cleanName&am=$amount&cu=INR&tn=$cleanRemarks&tr=$_refId';

    // Check if BHIM app is installed on Android
    List<Map<String, String>> installedApps = [];
    try {
      if (isAndroid) {
        installedApps = await _getInstalledUpiApps();
      }
    } catch (_) {}

    final bool hasBhim = installedApps.any((app) => app['packageName'] == 'in.org.npci.upiapp');

    if (!hasBhim && isAndroid) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF121422),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: const Text('BHIM App Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'To execute this transaction, the official BHIM app is required. Please install it from Google Play Store.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final playStoreUrl = 'https://play.google.com/store/apps/details?id=in.org.npci.upiapp';
                try {
                  await launchUrl(Uri.parse(playStoreUrl), mode: LaunchMode.externalApplication);
                } catch (e) {
                  debugPrint('Failed to open play store: $e');
                }
              },
              child: const Text('Install', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
      return;
    }

    _snack('Launching BHIM app for payment...', const Color(0xFF6366F1));
    final String? response = await _launchDirectUpi(upiUriString, 'in.org.npci.upiapp');
    
    if (response != null) {
      if (response == 'status=launched_external') {
        _paymentLaunched = true;
        if (kIsWeb) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _paymentLaunched) {
              _paymentLaunched = false;
              _showPaymentConfirmDialog();
            }
          });
        }
      } else {
        _handleUpiResponse(response);
      }
    } else {
      _logTransaction(confirmed: false);
      setState(() {
        _activeStep = 'cancelled';
      });
      _snack('Payment process aborted or no response received.', Colors.redAccent);
    }
  }

  Future<void> _logTransaction({required bool confirmed}) async {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final vpa = _vpaController.text.trim();
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final remarks = _remarksController.text.trim();

    int categoryId = provider.categories.isNotEmpty ? provider.categories.first.id! : 1;
    final lp = name.toLowerCase();
    for (final cat in provider.categories) {
      final cn = cat.name.toLowerCase();
      if ((lp.contains('food') || lp.contains('cafe') || lp.contains('restaurant')) &&
          (cn.contains('food') || cn.contains('dining'))) {
        categoryId = cat.id!;
        break;
      } else if ((lp.contains('shop') || lp.contains('store') || lp.contains('mart')) &&
          (cn.contains('shop') || cn.contains('retail'))) {
        categoryId = cat.id!;
        break;
      } else if ((lp.contains('rent') || lp.contains('bill') || lp.contains('elect')) &&
          (cn.contains('bill') || cn.contains('util'))) {
        categoryId = cat.id!;
        break;
      }
    }

    final tx = DailyTransaction(
      date: DateTime.now().toIso8601String(),
      categoryId: categoryId,
      itemService: name.isEmpty ? 'UPI: $vpa' : name,
      cost: amount,
      paidAmount: confirmed ? amount : 0.0,
      cleared: confirmed,
      accountId: _selectedAccountId,
      transactionType: 'Expense',
      tags: ['upi', if (confirmed) 'upi-success' else 'upi-failed', vpa.split('@').last],
      note: '${remarks.isEmpty ? 'UPI Payment' : remarks} | UPI: $vpa | Ref: $_refId | ${confirmed ? 'CONFIRMED' : 'CANCELLED'}',
    );
    await provider.addTransaction(tx);
  }

  // ── QR Parsing ────────────────────────────────────────────────────────────

  void _parseQrString(String text) {
    final t = text.trim();
    if (t.isEmpty) { _snack('QR data is empty', Colors.redAccent); return; }

    final lower = t.toLowerCase();
    if (!lower.startsWith('upi://') && !lower.contains('pa=')) {
      _snack('Not a valid UPI QR. Must contain pa=...', Colors.redAccent);
      return;
    }

    try {
      final raw = lower.startsWith('upi://')
          ? t.replaceAll(' ', '%20')
          : 'upi://pay?${t.replaceAll(' ', '%20')}';
      final uri = Uri.parse(raw);
      final params = uri.queryParameters;

      String get(String k) => params.entries
          .where((e) => e.key.toLowerCase() == k)
          .map((e) => e.value)
          .firstOrNull ?? '';

      final pa = get('pa');
      if (pa.isEmpty) throw Exception('Missing payee address (pa=...)');

      // Update controllers — this immediately reflects in TextFormFields
      setState(() {
        _vpaController.text = pa;
        _nameController.text = toTitleCase(get('pn').isEmpty ? 'UPI Merchant' : get('pn'));
        final am = get('am');
        if (am.isNotEmpty && double.tryParse(am) != null && double.parse(am) > 0) {
          _amountController.text = double.parse(am).toStringAsFixed(2);
        }
        final tn = get('tn');
        if (tn.isNotEmpty) _remarksController.text = tn;

        // Stop scanner
        _qrScannerActive = false;
        _qrController?.stop();
        _qrController?.dispose();
        _qrController = null;
      });

      // Switch to Send tab
      _tabController.animateTo(0);
      _snack('✅ QR scanned — ${_nameController.text} | ${_vpaController.text}', Colors.greenAccent);
    } catch (e) {
      _snack('Failed to parse QR: $e', Colors.redAccent);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final curSymbol = provider.defaultCurrency;
    final bankAccounts = provider.accounts
        .where((a) => a.type == 'Bank Account' || a.type == 'Credit Card')
        .toList();

    if (_selectedAccountId == null && provider.accounts.isNotEmpty) {
      _selectedAccountId = provider.accounts.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Pay',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'Send', icon: Icon(Icons.send_rounded, size: 18)),
            Tab(text: 'Scan QR', icon: Icon(Icons.qr_code_scanner_rounded, size: 18)),
            Tab(text: 'Accounts', icon: Icon(Icons.account_balance_rounded, size: 18)),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080914), Color(0xFF0E111F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSendTab(bankAccounts, curSymbol, provider),
            _buildScanQrTab(),
            _buildAccountsTab(bankAccounts, curSymbol, provider),
          ],
        ),
      ),
    );
  }

  // ── TAB 1: Send ───────────────────────────────────────────────────────────

  Widget _buildSendTab(List<WalletAccount> bankAccounts, String curSymbol, FinanceProvider provider) {
    if (_activeStep == 'success') return _buildResultView(success: true, curSymbol: curSymbol);
    if (_activeStep == 'cancelled') return _buildResultView(success: false, curSymbol: curSymbol);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tapping PAY opens PhonePe / GPay / Paytm with details pre-filled. App tracks if payment completed.',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Recipient card
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('RECIPIENT'),
                const SizedBox(height: 10),
                _textField(
                  controller: _nameController,
                  label: 'Name / Merchant (optional)',
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _vpaController,
                  label: 'UPI ID  (e.g. name@ybl)',
                  color: Colors.cyanAccent,
                  keyboard: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Amount card
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('AMOUNT & NOTE'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(curSymbol,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(color: Colors.white12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                _textField(controller: _remarksController, label: 'Remarks (optional)'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Account selector
          if (bankAccounts.isNotEmpty) ...[
            _label('DEBIT FROM'),
            const SizedBox(height: 6),
            _card(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedAccountId,
                  dropdownColor: const Color(0xFF121422),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                  isExpanded: true,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  items: bankAccounts.map((acc) {
                    final bal = provider.getAccountBalance(acc);
                    return DropdownMenuItem<int>(
                      value: acc.id,
                      child: Text('${acc.name}  ($curSymbol${bal.toStringAsFixed(0)})'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                ),
              ),
            ),
          ] else
            _card(
              child: const Text(
                'No Bank Account configured. Add one in Wallet Accounts.',
                style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 20),

          // PAY button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _launchUPI,
            icon: const Icon(Icons.payments_rounded, size: 22),
            label: const Text('PAY VIA UPI APP',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),

          // Prefilled from QR indicator
          if (_vpaController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_rounded, color: Colors.cyanAccent, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Pre-filled from QR: ${_vpaController.text}',
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Recent contacts
          if (_savedContacts.isNotEmpty) ...[
            _label('RECENT CONTACTS'),
            const SizedBox(height: 8),
            ..._savedContacts.map(_contactTile),
          ],
        ],
      ),
    );
  }

  Widget _contactTile(Map<String, String> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121422),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
          child: Text(c['name']![0],
              style: const TextStyle(
                  color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
        ),
        title: Text(c['name']!,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(c['vpa']!,
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white30, size: 14),
        onTap: () {
          setState(() {
            _nameController.text = c['name']!;
            _vpaController.text = c['vpa']!;
            _amountController.clear();
          });
          _tabController.animateTo(0);
        },
      ),
    );
  }

  // ── TAB 2: Scan QR ────────────────────────────────────────────────────────

  Widget _buildScanQrTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('SCAN UPI QR CODE WITH CAMERA'),
          const SizedBox(height: 12),

          // Camera box
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: _qrScannerActive
                        ? Colors.greenAccent
                        : const Color(0xFF6366F1),
                    width: 2.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: _qrScannerActive && _qrController != null
                    ? MobileScanner(
                        controller: _qrController!,
                        onDetect: (capture) {
                          final barcode = capture.barcodes.firstOrNull;
                          if (barcode?.rawValue != null) {
                            _parseQrString(barcode!.rawValue!);
                          }
                        },
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2_rounded,
                              size: 90,
                              color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 12),
                          const Text('Tap below to start camera',
                              style:
                                  TextStyle(color: Colors.white30, fontSize: 12)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Start / Stop
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _qrScannerActive ? Colors.redAccent : const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              setState(() {
                if (_qrScannerActive) {
                  _qrController?.stop();
                  _qrController?.dispose();
                  _qrController = null;
                  _qrScannerActive = false;
                } else {
                  _qrController = MobileScannerController(
                    detectionSpeed: DetectionSpeed.normal,
                    facing: CameraFacing.back,
                  );
                  _qrScannerActive = true;
                }
              });
            },
            icon: Icon(
                _qrScannerActive
                    ? Icons.stop_rounded
                    : Icons.qr_code_scanner_rounded,
                size: 20),
            label: Text(
                _qrScannerActive ? 'STOP SCANNER' : 'START CAMERA SCANNER',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          ),

          // Scanned result preview
          if (_vpaController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                      SizedBox(width: 6),
                      Text('QR Scanned Successfully',
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _resultRow('Merchant', _nameController.text),
                  const SizedBox(height: 4),
                  _resultRow('UPI ID', _vpaController.text),
                  if (_amountController.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _resultRow('Amount', '${_getSymbol()}${_amountController.text}'),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _tabController.animateTo(0),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('GO TO SEND & PAY',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          _label('OR PASTE UPI QR TEXT / URL'),
          const SizedBox(height: 10),
          _card(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qrUrlController,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Paste  upi://pay?pa=...&pn=...&am=...',
                      hintStyle:
                          const TextStyle(color: Colors.white24, fontSize: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _parseQrString(_qrUrlController.text),
                  child: const Text('PARSE',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Tip: Long-press a UPI QR image → "Copy QR content", or use any QR reader app → copy text → paste here.',
              style: TextStyle(color: Colors.white30, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(
                color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // ── TAB 3: Accounts ───────────────────────────────────────────────────────

  Widget _buildAccountsTab(List<WalletAccount> bankAccounts, String curSymbol, FinanceProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('YOUR WALLET BALANCES'),
          const SizedBox(height: 10),
          if (bankAccounts.isEmpty)
            _card(
              child: const Center(
                child: Text(
                  'No bank accounts configured yet.\nAdd one via Wallet Accounts in the menu.',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...bankAccounts.map((acc) {
              final bal = provider.getAccountBalance(acc);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF121422),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_rounded,
                          color: Color(0xFF6366F1), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(acc.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          Text(acc.type,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 10)),
                        ],
                      ),
                    ),
                    Text(
                      '$curSymbol${bal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 16),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Result screens ────────────────────────────────────────────────────────

  Widget _buildResultView({required bool success, required String curSymbol}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor:
                  success ? Colors.greenAccent : Colors.redAccent,
              child: Icon(
                  success
                      ? Icons.check_rounded
                      : Icons.cancel_rounded,
                  color: Colors.black,
                  size: 52),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            success ? 'Payment Confirmed ✓' : 'Payment Cancelled / Failed',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$curSymbol${_amountController.text} to ${_nameController.text.isEmpty ? _vpaController.text : _nameController.text}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _card(
            child: Column(
              children: [
                _infoRow('UPI VPA', _vpaController.text),
                const SizedBox(height: 8),
                _infoRow('Transaction Ref', _refId),
                const SizedBox(height: 8),
                _infoRow('Date & Time', DateTime.now().toString().substring(0, 19)),
                const SizedBox(height: 8),
                _infoRow('Status', success ? '✅ Logged as Expense' : '❌ Logged as Cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => setState(() {
              _vpaController.clear();
              _nameController.clear();
              _amountController.clear();
              _remarksController.clear();
              _activeStep = 'setup';
            }),
            child: const Text('NEW PAYMENT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── UI Helpers ────────────────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) =>
      Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121422),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: child,
      );

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: Colors.white38,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2));

  Widget _textField({
    required TextEditingController controller,
    required String label,
    Color color = Colors.white,
    TextInputType? keyboard,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboard,
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white30, fontSize: 11),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white12)),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6366F1))),
        ),
      );

  Widget _infoRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white30, fontSize: 11)),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}
