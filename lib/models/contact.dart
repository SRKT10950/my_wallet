import '../utils/string_utils.dart';

class Contact {
  final int? id;
  final String name;
  final String mobile;
  final String place;
  final String occupation;
  final String businessName;
  final bool transactionNotification;
  final String notificationMethod; // 'WhatsApp' or 'SMS'
  final bool active;
  final bool deleted;

  Contact({
    this.id,
    required String name,
    String mobile = '',
    String place = '',
    String occupation = '',
    String businessName = '',
    this.transactionNotification = true,
    this.notificationMethod = 'WhatsApp',
    this.active = true,
    this.deleted = false,
  })  : name = toTitleCase(name),
        mobile = mobile,
        place = toTitleCase(place),
        occupation = toTitleCase(occupation),
        businessName = toTitleCase(businessName);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'place': place,
      'occupation': occupation,
      'businessName': businessName,
      'transactionNotification': transactionNotification ? 1 : 0,
      'notificationMethod': notificationMethod,
      'active': active ? 1 : 0,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    final rawNotification = map['transactionNotification'] ?? map['transaction_notification'];
    return Contact(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      name: toTitleCase(map['name'] ?? ''),
      mobile: map['mobile'] ?? '',
      place: toTitleCase(map['place'] ?? ''),
      occupation: toTitleCase(map['occupation'] ?? ''),
      businessName: toTitleCase(map['businessName'] ?? map['business_name'] ?? ''),
      transactionNotification: rawNotification == null || rawNotification == 1 || rawNotification == true || rawNotification == 'true',
      notificationMethod: (map['notificationMethod'] ?? map['notification_method'] ?? 'WhatsApp').toString(),
      active: map['active'] == 1 || map['active'] == true || map['active'] == 'true',
      deleted: map['deleted'] == 1 || map['deleted'] == true || map['deleted'] == 'true',
    );
  }

  Contact copyWith({
    int? id,
    String? name,
    String? mobile,
    String? place,
    String? occupation,
    String? businessName,
    bool? transactionNotification,
    String? notificationMethod,
    bool? active,
    bool? deleted,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name != null ? toTitleCase(name) : this.name,
      mobile: mobile ?? this.mobile,
      place: place != null ? toTitleCase(place) : this.place,
      occupation: occupation != null ? toTitleCase(occupation) : this.occupation,
      businessName: businessName != null ? toTitleCase(businessName) : this.businessName,
      transactionNotification: transactionNotification ?? this.transactionNotification,
      notificationMethod: notificationMethod ?? this.notificationMethod,
      active: active ?? this.active,
      deleted: deleted ?? this.deleted,
    );
  }
}
