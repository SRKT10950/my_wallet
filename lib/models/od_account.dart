class OdAccount {
  final int? id;
  final String name;
  final double limit;
  final double interestRate;
  final int billingDay; // 1-31

  OdAccount({
    this.id,
    required this.name,
    required this.limit,
    required this.interestRate,
    required this.billingDay,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'limit': limit,
      'interestRate': interestRate,
      'billingDay': billingDay,
    };
  }

  factory OdAccount.fromMap(Map<String, dynamic> map) {
    return OdAccount(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      name: map['name'],
      limit: (map['limit'] ?? 0.0).toDouble(),
      interestRate: (map['interestRate'] ?? 0.0).toDouble(),
      billingDay: map['billingDay'] ?? 1,
    );
  }
}

class OdTransaction {
  final int? id;
  final int odAccountId;
  final double amount;
  final String type; // 'Debit' or 'Credit'
  final String date; // ISO 8601

  OdTransaction({
    this.id,
    required this.odAccountId,
    required this.amount,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'odAccountId': odAccountId,
      'amount': amount,
      'type': type,
      'date': date,
    };
  }

  factory OdTransaction.fromMap(Map<String, dynamic> map) {
    return OdTransaction(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      odAccountId: map['odAccountId'] is int ? map['odAccountId'] : int.parse(map['odAccountId'].toString()),
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'],
      date: map['date'],
    );
  }
}
