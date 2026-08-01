import 'dart:convert';

class SplitBill {
  final int? id;
  final String title;
  final double totalAmount;
  final String paidBy; // 'You' or a friend's name
  final List<String> participants; // Friends sharing this bill, e.g. ['You', 'Rahul', 'Priya']
  final Map<String, double> shares; // name -> amount they owe/share (not including what they paid, just their share)
  final String date;
  final bool deleted;

  SplitBill({
    this.id,
    required this.title,
    required this.totalAmount,
    required this.paidBy,
    required this.participants,
    required this.shares,
    required this.date,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'totalAmount': totalAmount,
      'paidBy': paidBy,
      'participants': participants,
      'shares': jsonEncode(shares),
      'date': date,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory SplitBill.fromMap(Map<String, dynamic> map) {
    Map<String, double> parsedShares = {};
    if (map['shares'] != null) {
      try {
        final Map<String, dynamic> decoded = map['shares'] is String
            ? jsonDecode(map['shares'])
            : map['shares'];
        decoded.forEach((key, value) {
          parsedShares[key] = (value ?? 0.0).toDouble();
        });
      } catch (_) {}
    }
    List<String> parsedParticipants = [];
    if (map['participants'] != null) {
      if (map['participants'] is List) {
        parsedParticipants = List<String>.from(map['participants']);
      } else if (map['participants'] is String) {
        final str = map['participants'].toString().trim();
        parsedParticipants = str.isEmpty ? [] : str.split(',');
      }
    }
    return SplitBill(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      title: map['title'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      paidBy: map['paidBy'] ?? 'You',
      participants: parsedParticipants,
      shares: parsedShares,
      date: map['date'] ?? DateTime.now().toIso8601String(),
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  SplitBill copyWith({
    int? id,
    String? title,
    double? totalAmount,
    String? paidBy,
    List<String>? participants,
    Map<String, double>? shares,
    String? date,
    bool? deleted,
  }) {
    return SplitBill(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      paidBy: paidBy ?? this.paidBy,
      participants: participants ?? this.participants,
      shares: shares ?? this.shares,
      date: date ?? this.date,
      deleted: deleted ?? this.deleted,
    );
  }
}

