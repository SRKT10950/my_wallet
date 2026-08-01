class OdAccount {
  final int? id;
  final String name;
  final double limit;
  final double interestRate;
  final int billingDay; // 1-31
  final bool deleted;

  OdAccount({
    this.id,
    required this.name,
    required this.limit,
    required this.interestRate,
    required this.billingDay,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'limit': limit,
      'interestRate': interestRate,
      'billingDay': billingDay,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory OdAccount.fromMap(Map<String, dynamic> map) {
    return OdAccount(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      name: map['name'],
      limit: (map['limit'] ?? 0.0).toDouble(),
      interestRate: (map['interestRate'] ?? 0.0).toDouble(),
      billingDay: (map['billingDay'] ?? 1) is int ? map['billingDay'] : (int.tryParse(map['billingDay']?.toString() ?? '') ?? 1),
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  OdAccount copyWith({
    int? id,
    String? name,
    double? limit,
    double? interestRate,
    int? billingDay,
    bool? deleted,
  }) {
    return OdAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      limit: limit ?? this.limit,
      interestRate: interestRate ?? this.interestRate,
      billingDay: billingDay ?? this.billingDay,
      deleted: deleted ?? this.deleted,
    );
  }
}

class OdTransaction {
  final int? id;
  final int odAccountId;
  final double amount;
  final String type; // 'Debit' or 'Credit'
  final String date; // ISO 8601
  final bool deleted;

  OdTransaction({
    this.id,
    required this.odAccountId,
    required this.amount,
    required this.type,
    required this.date,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'odAccountId': odAccountId,
      'amount': amount,
      'type': type,
      'date': date,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory OdTransaction.fromMap(Map<String, dynamic> map) {
    return OdTransaction(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      odAccountId: map['odAccountId'] is int ? map['odAccountId'] : (int.tryParse(map['odAccountId']?.toString() ?? '') ?? 0),
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'],
      date: map['date'],
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  OdTransaction copyWith({
    int? id,
    int? odAccountId,
    double? amount,
    String? type,
    String? date,
    bool? deleted,
  }) {
    return OdTransaction(
      id: id ?? this.id,
      odAccountId: odAccountId ?? this.odAccountId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      deleted: deleted ?? this.deleted,
    );
  }
}

