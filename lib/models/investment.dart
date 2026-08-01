class Investment {
  final int? id;
  final String name;
  final String type; // FD, RD, Mutual Fund, Stock, SIP, PPF
  final double amount; // Principal (FD, MF, Stock) or Monthly Installment (RD, SIP, PPF)
  final double expectedRoi; // Annual ROI percentage
  final int tenureMonths; // Total duration in months
  final String startDate; // ISO 8601 string
  final bool deleted;

  Investment({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.expectedRoi,
    required this.tenureMonths,
    required this.startDate,
    this.deleted = false,
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
      'deleted': deleted ? 1 : 0,
    };
  }

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      name: map['name'],
      type: map['type'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      expectedRoi: (map['expectedRoi'] ?? 0.0).toDouble(),
      tenureMonths: (map['tenureMonths'] ?? 0) is int ? map['tenureMonths'] : (int.tryParse(map['tenureMonths']?.toString() ?? '') ?? 0),
      startDate: map['startDate'] ?? DateTime.now().toIso8601String(),
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  Investment copyWith({
    int? id,
    String? name,
    String? type,
    double? amount,
    double? expectedRoi,
    int? tenureMonths,
    String? startDate,
    bool? deleted,
  }) {
    return Investment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      expectedRoi: expectedRoi ?? this.expectedRoi,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      startDate: startDate ?? this.startDate,
      deleted: deleted ?? this.deleted,
    );
  }
}

