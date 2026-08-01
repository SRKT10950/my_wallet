import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';
import '../utils/string_utils.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SmsParserScreen extends StatefulWidget {
  const SmsParserScreen({super.key});

  @override
  State<SmsParserScreen> createState() => _SmsParserScreenState();
}

class _SmsParserScreenState extends State<SmsParserScreen> {
  final TextEditingController _smsController = TextEditingController();
  
  // Parsed fields
  double? _parsedAmount;
  String _parsedType = 'Expense'; // 'Expense' or 'Income'
  String _parsedPayee = '';
  String _parsedRef = '';
  String _parsedBank = '';
  
  // Selected logging fields
  int? _selectedAccountId;
  int? _selectedCategoryId;
  String _note = '';
  final List<String> _tags = ['sms-parsed'];

  bool _isParsed = false;

  final List<Map<String, String>> _templates = [
    {
      'title': 'HDFC Debit (UPI)',
      'body': 'Alert: Your A/c no. XX4321 has been debited by Rs. 750.00 on 08-Jun-26 by transfer to Starbucks. UPI Ref 382910. Not done by you? Call HDFC Bank.',
    },
    {
      'title': 'Salary Credit',
      'body': 'Dear Customer, your Acct XX8899 has been Credited with INR 45,000.00 on 01/06/2026 by Salary. Info: Acme Corp. Balance: INR 52,340.00.',
    },
    {
      'title': 'Credit Card Spent',
      'body': 'Your HDFC Bank Credit Card ending 9988 spent Rs 1,450.00 at Amazon.in on 2026-06-08. Bal: Rs 12,000. Avail Lmt: Rs 1,50,000.',
    },
    {
      'title': 'ICICI Bank Transfer',
      'body': 'ICICI Bank Acct XX7766 debited Rs. 2,500.00; towards Rent. Ref: UTR908231.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _smsController.addListener(_autoParse);
  }

  @override
  void dispose() {
    _smsController.removeListener(_autoParse);
    _smsController.dispose();
    super.dispose();
  }

  void _autoParse() {
    final text = _smsController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _isParsed = false;
        _clearParsed();
      });
      return;
    }

    // Amount regex: search for Rs. X, Rs X, INR X, Rs.X etc.
    final amountRegex = RegExp(
      r'(?:rs\.?|inr|amt)\s*([0-9,]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );
    final amountMatch = amountRegex.firstMatch(text);
    double? amount;
    if (amountMatch != null) {
      final amtStr = amountMatch.group(1)?.replaceAll(',', '') ?? '';
      amount = double.tryParse(amtStr);
    }

    // Transaction Type regex
    final isCredit = RegExp(
      r'(?:credited|received|deposited|salary|added)',
      caseSensitive: false,
    ).hasMatch(text);
    final transactionType = isCredit ? 'Income' : 'Expense';

    // Account / Card number regex
    final accountRegex = RegExp(
      r'(?:a/c|acct|acc|card|ending)\s*(?:no\.?)?\s*(?:xx|x+|\b)?(\d{4})',
      caseSensitive: false,
    );
    final accountMatch = accountRegex.firstMatch(text);
    final accNum = accountMatch != null ? accountMatch.group(1) ?? '' : '';

    // Payee / Merchant / Towards regex
    final payeeRegex = RegExp(
      r'(?:transfer to|towards|spent at|paid to|info:|to)\s+([a-zA-Z0-9.\-_&]+(?:\s+[a-zA-Z0-9.\-_&]+){0,2})',
      caseSensitive: false,
    );
    final payeeMatch = payeeRegex.firstMatch(text);
    String payee = payeeMatch != null ? payeeMatch.group(1)?.trim() ?? '' : '';
    // Clean up ending punctuation from payee
    if (payee.endsWith('.')) payee = payee.substring(0, payee.length - 1);

    // Ref/UTR number regex
    final refRegex = RegExp(
      r'(?:ref|utr|txn|ref\s*no\.?)\s*(?:no\.?)?\s*([0-9a-zA-Z]+)',
      caseSensitive: false,
    );
    final refMatch = refRegex.firstMatch(text);
    final ref = refMatch != null ? refMatch.group(1) ?? '' : '';

    // Bank detection
    final bankRegex = RegExp(
      r'(hdfc|sbi|icici|axis|kotak|paytm|idfc|citi|hsbc)',
      caseSensitive: false,
    );
    final bankMatch = bankRegex.firstMatch(text);
    final bank = bankMatch != null ? bankMatch.group(1)?.toUpperCase() ?? '' : 'BANK';

    setState(() {
      _parsedAmount = amount;
      _parsedType = transactionType;
      _parsedPayee = toTitleCase(payee.isNotEmpty ? payee : (isCredit ? 'Cash Inflow' : 'Retail Merchant'));
      _parsedRef = ref;
      _parsedBank = bank;
      _isParsed = true;
      _note = 'Parsed from SMS. Ref: $ref';

      // Pre-select account if match ending digits
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      if (accNum.isNotEmpty) {
        final match = provider.accounts.where((a) => a.name.contains(accNum)).firstOrNull;
        if (match != null) {
          _selectedAccountId = match.id;
        } else if (provider.accounts.isNotEmpty) {
          _selectedAccountId = provider.accounts.first.id;
        }
      } else if (provider.accounts.isNotEmpty && _selectedAccountId == null) {
        _selectedAccountId = provider.accounts.first.id;
      }

      // Pre-select category
      if (provider.categories.isNotEmpty && _selectedCategoryId == null) {
        // Try matching payee to categories
        final matchedCat = provider.categories.where((c) => 
          _parsedPayee.toLowerCase().contains(c.name.toLowerCase()) ||
          c.name.toLowerCase().contains(_parsedPayee.toLowerCase())
        ).firstOrNull;
        _selectedCategoryId = matchedCat?.id ?? provider.categories.first.id;
      }
    });
  }

  void _clearParsed() {
    _parsedAmount = null;
    _parsedType = 'Expense';
    _parsedPayee = '';
    _parsedRef = '';
    _parsedBank = '';
    _selectedAccountId = null;
    _selectedCategoryId = null;
    _note = '';
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    if (data?.text != null) {
      _smsController.text = data!.text!;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pasted from clipboard!'),
          backgroundColor: Color(0xFF6366F1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard is empty or doesn\'t contain text.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _readSmsInbox() async {
    if (kIsWeb) {
      _showSimulatedSmsDialog();
      return;
    }
    
    final status = await Permission.sms.status;
    if (status.isGranted) {
      await _loadSmsFromInbox();
    } else {
      final requestStatus = await Permission.sms.request();
      if (requestStatus.isGranted) {
        await _loadSmsFromInbox();
      } else {
        _showSimulatedSmsDialog(permissionDenied: true);
      }
    }
  }

  Future<void> _loadSmsFromInbox() async {
    try {
      final SmsQuery query = SmsQuery();
      final List<SmsMessage> messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 50,
      );

      final txKeywords = RegExp(r'(debited|credited|spent|received|rs\.?|inr|upi|balance|a/c|acct)', caseSensitive: false);
      final filtered = messages.where((msg) {
        final body = msg.body ?? '';
        return txKeywords.hasMatch(body);
      }).toList();

      if (filtered.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No transaction alerts found in inbox.'), backgroundColor: Colors.amber),
          );
        }
        return;
      }

      _showInboxSelectionDialog(filtered.map((m) => {
        'sender': m.sender ?? 'BANK',
        'body': m.body ?? '',
        'date': m.date != null ? m.date!.toIso8601String() : DateTime.now().toIso8601String(),
      }).toList());

    } catch (e) {
      _showSimulatedSmsDialog(errorMsg: e.toString());
    }
  }

  void _showInboxSelectionDialog(List<Map<String, String>> smsList) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121422),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: const Text(
            'Select SMS to Parse',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: smsList.length,
              itemBuilder: (context, idx) {
                final sms = smsList[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sms['sender']!,
                          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          sms['date']!.substring(0, 10),
                          style: const TextStyle(color: Colors.white30, fontSize: 10),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        sms['body']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                    onTap: () {
                      _smsController.text = sms['body']!;
                      Navigator.pop(ctx);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.white38)),
            ),
          ],
        );
      },
    );
  }

  void _showSimulatedSmsDialog({bool permissionDenied = false, String? errorMsg}) {
    final simulated = [
      {
        'sender': 'AD-HDFCBK',
        'body': 'Alert: Your A/c no. XX9988 has been debited by Rs. 1,200.00 on 08-Jun-26 by transfer to Netflix. UPI Ref 554109.',
        'date': DateTime.now().toIso8601String(),
      },
      {
        'sender': 'BP-SBIPAY',
        'body': 'Dear Customer, your Acct XX1212 has been Credited with INR 35,000.00 on 08/06/2026 by Salary. Info: TCS Corp.',
        'date': DateTime.now().toIso8601String(),
      },
      {
        'sender': 'VM-ICICIB',
        'body': 'ICICI Bank Acct XX5544 debited Rs. 450.00 towards Starbucks. Ref: TXN998273.',
        'date': DateTime.now().toIso8601String(),
      },
      {
        'sender': 'AM-AMAZON',
        'body': 'Your Credit Card ending 8080 spent Rs 2,999.00 at Amazon India on 2026-06-08.',
        'date': DateTime.now().toIso8601String(),
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121422),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SMS Sample Templates',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                permissionDenied
                    ? 'SMS permission denied. Showing sample templates to demonstrate parsing.'
                    : (errorMsg != null
                        ? 'Could not read SMS ($errorMsg). Showing sample templates.'
                        : 'Your device does not support SMS reading here. Paste an SMS manually or try these samples.'),
                style: const TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 280,
            child: ListView.builder(
              itemCount: simulated.length,
              itemBuilder: (context, idx) {
                final sms = simulated[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sms['sender']!,
                          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          sms['date']!.substring(0, 10),
                          style: const TextStyle(color: Colors.white30, fontSize: 10),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        sms['body']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                    onTap: () {
                      _smsController.text = sms['body']!;
                      Navigator.pop(ctx);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.white38)),
            ),
          ],
        );
      },
    );
  }

  void _saveTransaction() async {
    if (_parsedAmount == null || _parsedAmount! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid transaction amount'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Wallet Account'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Category'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final provider = Provider.of<FinanceProvider>(context, listen: false);
    
    // Add reference tag if exists
    final tagsToSave = List<String>.from(_tags);
    if (_parsedRef.isNotEmpty) {
      tagsToSave.add('ref-$_parsedRef');
    }
    if (_parsedBank.isNotEmpty) {
      tagsToSave.add(_parsedBank.toLowerCase());
    }

    final tx = DailyTransaction(
      date: DateTime.now().toIso8601String(),
      categoryId: _selectedCategoryId!,
      itemService: _parsedPayee,
      cost: _parsedAmount!,
      paidAmount: _parsedAmount!,
      cleared: true,
      accountId: _selectedAccountId,
      transactionType: _parsedType,
      tags: tagsToSave,
      note: _note,
    );

    try {
      await provider.addTransaction(tx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged $_parsedType: ${provider.defaultCurrency}${_parsedAmount!.toStringAsFixed(2)} to ${provider.accounts.firstWhere((a) => a.id == _selectedAccountId).name}'),
            backgroundColor: Colors.greenAccent,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final curSymbol = provider.defaultCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SMS Clipboard Parser',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5),
        ),
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
              // Intro Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF121422),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.security_outlined, color: Colors.cyanAccent, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '100% Offline & Private',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Paste bank SMS alerts to parse transaction details instantly on-device without internet.',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SMS Text Area
              const Text(
                'PASTE TRANSACTION ALERT',
                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF121422),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _smsController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Paste SMS text here (from HDFC, ICICI, SBI, UPI, etc.)...',
                        hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                        contentPadding: EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: _pasteFromClipboard,
                                icon: const Icon(Icons.paste_rounded, size: 16, color: Color(0xFF6366F1)),
                                label: const Text('PASTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                onPressed: _readSmsInbox,
                                icon: const Icon(Icons.sms_rounded, size: 16, color: Colors.cyanAccent),
                                label: const Text('SCAN INBOX', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                              ),
                            ],
                          ),
                          if (_smsController.text.isNotEmpty)
                            IconButton(
                              onPressed: () => _smsController.clear(),
                              icon: const Icon(Icons.clear, size: 16, color: Colors.white54),
                              tooltip: 'Clear input',
                            ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Templates Selector (Horizontal slider)
              const Text(
                'TAP A SAMPLE TEMPLATE TO TRY IT OUT',
                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _templates.length,
                  itemBuilder: (context, idx) {
                    final t = _templates[idx];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ActionChip(
                        backgroundColor: const Color(0xFF121422),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        label: Text(t['title']!, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _smsController.text = t['body']!;
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Parsed Preview Card
              if (_isParsed) ...[
                const Text(
                  'PARSED TRANSACTION PREVIEW',
                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFF121422),
                    border: Border.all(
                      color: _parsedType == 'Expense' 
                        ? Colors.redAccent.withValues(alpha: 0.4) 
                        : Colors.greenAccent.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _parsedType == 'Expense' 
                          ? Colors.redAccent.withValues(alpha: 0.03) 
                          : Colors.greenAccent.withValues(alpha: 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header showing parsed bank and amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _parsedBank.isNotEmpty ? '$_parsedBank ALERT' : 'SMS ALERT',
                              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                            ),
                          ),
                          // Transaction Type Toggle badge
                          InkWell(
                            onTap: () {
                              setState(() {
                                _parsedType = _parsedType == 'Expense' ? 'Income' : 'Expense';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _parsedType == 'Expense' 
                                  ? Colors.redAccent.withValues(alpha: 0.12) 
                                  : Colors.greenAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _parsedType == 'Expense' ? Colors.redAccent.withValues(alpha: 0.4) : Colors.greenAccent.withValues(alpha: 0.4)
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _parsedType == 'Expense' ? Icons.arrow_outward_rounded : Icons.call_received_rounded, 
                                    size: 14, 
                                    color: _parsedType == 'Expense' ? Colors.redAccent : Colors.greenAccent
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _parsedType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.w900, 
                                      color: _parsedType == 'Expense' ? Colors.redAccent : Colors.greenAccent
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Editable Parsed Payee
                      const Text('Merchant / Payee Name', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                      TextFormField(
                        initialValue: _parsedPayee,
                        onChanged: (val) => _parsedPayee = val,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Editable Parsed Amount
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Amount', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      curSymbol,
                                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _parsedAmount?.toStringAsFixed(2) ?? '0.00',
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) => _parsedAmount = double.tryParse(val) ?? 0.0,
                                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ref / UTR Number', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                                TextFormField(
                                  initialValue: _parsedRef,
                                  onChanged: (val) => _parsedRef = val,
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Account and Category Selectors
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('WALLET ACCOUNT', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _selectedAccountId,
                                      dropdownColor: const Color(0xFF121422),
                                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      isExpanded: true,
                                      items: provider.accounts.map((acc) {
                                        return DropdownMenuItem<int>(
                                          value: acc.id,
                                          child: Text(acc.name),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(() => _selectedAccountId = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CATEGORY', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _selectedCategoryId,
                                      dropdownColor: const Color(0xFF121422),
                                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      isExpanded: true,
                                      items: provider.categories.map((cat) {
                                        return DropdownMenuItem<int>(
                                          value: cat.id,
                                          child: Text(cat.name),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Notes Input
                      const Text('Transaction Notes', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                      TextFormField(
                        initialValue: _note,
                        onChanged: (val) => _note = val,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _parsedType == 'Expense' ? Colors.redAccent : Colors.greenAccent,
                          foregroundColor: Colors.black,
                          elevation: 8,
                          shadowColor: (_parsedType == 'Expense' ? Colors.redAccent : Colors.greenAccent).withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.black),
                        label: const Text(
                          'CONFIRM & LOG TRANSACTION',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                        ),
                        onPressed: _saveTransaction,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.query_stats_rounded, size: 56, color: Colors.white.withValues(alpha: 0.12)),
                      const SizedBox(height: 12),
                      Text(
                        'Awaiting SMS Input',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paste or tap a template above to generate details.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
