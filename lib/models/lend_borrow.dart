class LendBorrow {
  final int? id;
  final String name;
  final String type; // 'Lend' or 'Borrow'
  final String date;
  final int tenure; // in months
  final double principal;
  final String returnDate; // auto-calculated
  final double settled; // auto-calculated
  final double diff; // auto-calculated
  final String status; // 'Active' or 'Settled'

  LendBorrow({
    this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.tenure,
    required this.principal,
    this.returnDate = '',
    this.settled = 0.0,
    this.diff = 0.0,
    this.status = 'Active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'date': date,
      'tenure': tenure,
      'principal': principal,
      'returnDate': returnDate,
      'settled': settled,
      'diff': diff,
      'status': status,
    };
  }

  factory LendBorrow.fromMap(Map<String, dynamic> map) {
    return LendBorrow(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      date: map['date'],
      tenure: map['tenure'],
      principal: map['principal'],
      returnDate: map['returnDate'] ?? '',
      settled: map['settled'] ?? 0.0,
      diff: map['diff'] ?? 0.0,
      status: map['status'] ?? 'Active',
    );
  }
}

class Repayment {
  final int? id;
  final int lendBorrowId;
  final String name;
  final String paymentDate;
  final double amount;
  final String method; // 'Cash', 'UPI', 'Bank Transfer'

  Repayment({
    this.id,
    required this.lendBorrowId,
    required this.name,
    required this.paymentDate,
    required this.amount,
    required this.method,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lendBorrowId': lendBorrowId,
      'name': name,
      'paymentDate': paymentDate,
      'amount': amount,
      'method': method,
    };
  }

  factory Repayment.fromMap(Map<String, dynamic> map) {
    return Repayment(
      id: map['id'],
      lendBorrowId: map['lendBorrowId'],
      name: map['name'],
      paymentDate: map['paymentDate'],
      amount: map['amount'],
      method: map['method'],
    );
  }
}
