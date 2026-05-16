class Investment {
  final int? id;
  final String name;
  final String type; // FD, RD, Mutual Fund, Stock, SIP, PPF
  final double amount; // Principal (FD, MF, Stock) or Monthly Installment (RD, SIP, PPF)
  final double expectedRoi; // Annual ROI percentage
  final int tenureMonths; // Total duration in months
  final String startDate; // ISO 8601 string

  Investment({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.expectedRoi,
    required this.tenureMonths,
    required this.startDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'amount': amount,
      'expectedRoi': expectedRoi,
      'tenureMonths': tenureMonths,
      'startDate': startDate,
    };
  }

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      expectedRoi: (map['expectedRoi'] ?? 0.0).toDouble(),
      tenureMonths: map['tenureMonths'] ?? 0,
      startDate: map['startDate'] ?? DateTime.now().toIso8601String(),
    );
  }
}
