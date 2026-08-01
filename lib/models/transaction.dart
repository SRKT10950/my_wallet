import '../utils/string_utils.dart';

class DailyTransaction {
  final int? id;
  final String date;
  final int categoryId;
  final String itemService;
  final double cost;
  final double paidAmount;
  final bool cleared;
  final int? accountId;
  final int? toAccountId; // For transfer transactions
  final String transactionType; // 'Expense', 'Income', 'Transfer'
  final List<String> tags;
  final String note;
  final String merchantName;
  final bool deleted;

  DailyTransaction({
    this.id,
    required this.date,
    required this.categoryId,
    required this.itemService,
    required this.cost,
    required this.paidAmount,
    required this.cleared,
    this.accountId,
    this.toAccountId,
    this.transactionType = 'Expense',
    this.tags = const [],
    this.note = '',
    this.merchantName = '',
    this.deleted = false,
  });

  double get remaining => cost - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'categoryId': categoryId,
      'itemService': itemService,
      'cost': cost,
      'paidAmount': paidAmount,
      'cleared': cleared ? 1 : 0,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'transactionType': transactionType,
      'tags': tags,
      'note': note,
      'merchantName': merchantName,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory DailyTransaction.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null) {
      if (map['tags'] is List) {
        parsedTags = List<String>.from(map['tags']);
      } else if (map['tags'] is String) {
        // Fallback for string list representation
        parsedTags = map['tags'].toString().split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      }
    }
    String mName = map['merchantName'] ?? '';
    if (mName.isEmpty) {
      for (var t in parsedTags) {
        if (t.startsWith('shop:')) {
          mName = t.substring(5).trim();
          break;
        }
      }
    }

    return DailyTransaction(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      date: map['date'],
      categoryId: map['categoryId'] is int ? map['categoryId'] : (int.tryParse(map['categoryId'].toString()) ?? 0),
      itemService: map['itemService'],
      cost: (map['cost'] ?? 0.0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      cleared: map['cleared'] == 1 || map['cleared'] == true,
      accountId: map['accountId'] is int ? map['accountId'] : int.tryParse(map['accountId']?.toString() ?? ''),
      toAccountId: map['toAccountId'] is int ? map['toAccountId'] : int.tryParse(map['toAccountId']?.toString() ?? ''),
      transactionType: map['transactionType'] ?? (map['toAccountId'] != null ? 'Transfer' : 'Expense'),
      tags: parsedTags,
      note: map['note'] ?? '',
      merchantName: toTitleCase(mName),
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  DailyTransaction copyWith({
    int? id,
    String? date,
    int? categoryId,
    String? itemService,
    double? cost,
    double? paidAmount,
    bool? cleared,
    int? accountId,
    int? toAccountId,
    String? transactionType,
    List<String>? tags,
    String? note,
    String? merchantName,
    bool? deleted,
  }) {
    return DailyTransaction(
      id: id ?? this.id,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      itemService: itemService ?? this.itemService,
      cost: cost ?? this.cost,
      paidAmount: paidAmount ?? this.paidAmount,
      cleared: cleared ?? this.cleared,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      transactionType: transactionType ?? this.transactionType,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      merchantName: merchantName ?? this.merchantName,
      deleted: deleted ?? this.deleted,
    );
  }
}


