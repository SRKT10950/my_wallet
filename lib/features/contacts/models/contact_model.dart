import '../../../core/models/base_model.dart';

/// Represents a contact directory entry in My Wallet.
///
/// Extends [BaseModel] to inherit all 13 standardized audit & control fields.
class ContactModel extends BaseModel {
  /// Person / Owner Name (Required)
  final String ownerName;

  /// Mobile Number (Required)
  final String mobileNumber;

  /// Business / Shop Name (Optional)
  final String? businessShopName;

  /// Place / City (Optional)
  final String? placeCity;

  /// Active status toggle (Active / Inactive)
  final bool isActiveStatus;

  /// Whether automated notifications are enabled
  final bool enableNotification;

  /// Preferred notification channel: 'SMS' or 'WhatsApp'
  final String notificationMethod;

  const ContactModel({
    // Base fields
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.createdBy,
    super.updatedBy,
    super.deletedAt,
    super.deletedBy,
    super.isDeleted,
    super.version,
    super.status,
    super.tenantId,
    super.remarks,
    super.metadata,
    // Contact fields
    required this.ownerName,
    required this.mobileNumber,
    this.businessShopName,
    this.placeCity,
    this.isActiveStatus = true,
    this.enableNotification = true,
    this.notificationMethod = NotificationMethod.whatsApp,
  });

  // ── Deserialisation ───────────────────────────────────────────────

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    final base = BaseModel.baseFromMap(map);
    return ContactModel(
      // Base fields
      id: base['id'] as String,
      createdAt: base['created_at'] as String,
      updatedAt: base['updated_at'] as String,
      createdBy: base['created_by'] as String?,
      updatedBy: base['updated_by'] as String?,
      deletedAt: base['deleted_at'] as String?,
      deletedBy: base['deleted_by'] as String?,
      isDeleted: base['is_deleted'] as bool,
      version: base['version'] as int,
      status: base['status'] as String,
      tenantId: base['tenant_id'] as String?,
      remarks: base['remarks'] as String?,
      metadata: base['metadata'] as String?,
      // Contact fields
      ownerName: map['owner_name']?.toString() ?? map['name']?.toString() ?? '',
      mobileNumber: map['mobile_number']?.toString() ?? map['mobile']?.toString() ?? '',
      businessShopName: map['business_shop_name']?.toString(),
      placeCity: map['place_city']?.toString(),
      isActiveStatus: (map['is_active'] as num?)?.toInt() == 1 ||
          map['is_active'] == true ||
          map['is_active'] == null,
      enableNotification: (map['enable_notification'] as num?)?.toInt() == 1 ||
          map['enable_notification'] == true ||
          map['enable_notification'] == null,
      notificationMethod:
          map['notification_method']?.toString() ?? NotificationMethod.whatsApp,
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────

  @override
  Map<String, dynamic> toMap() => {
        ...baseToMap(),
        'owner_name': ownerName,
        'mobile_number': mobileNumber,
        'business_shop_name': businessShopName,
        'place_city': placeCity,
        'is_active': isActiveStatus ? 1 : 0,
        'enable_notification': enableNotification ? 1 : 0,
        'notification_method': notificationMethod,
      };

  // ── Display Helpers ──────────────────────────────────────────────

  /// Formatted mobile number (e.g. `+91 98765 43210`)
  String get formattedMobile {
    final clean = mobileNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      return '+91 ${clean.substring(0, 5)} ${clean.substring(5)}';
    }
    return mobileNumber;
  }

  /// Contact initials (up to 2 characters)
  String get initials {
    final parts = ownerName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?';
  }
}

/// Constants for [ContactModel.notificationMethod].
class NotificationMethod {
  NotificationMethod._();
  static const String sms = 'SMS';
  static const String whatsApp = 'WhatsApp';
}
