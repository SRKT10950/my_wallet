import '../../../core/models/base_model.dart';

/// Represents an authenticated user in My Wallet.
class UserModel extends BaseModel {
  // ── User-specific fields ──────────────────────────────────────────
  final String name;
  final String mobile;

  /// SHA-256 hashed password or legacy PIN.
  final String passwordHash;

  /// Whether the user has completed OTP verification.
  final bool isVerified;

  /// Active OTP code (null when verified).
  final String? otpCode;

  /// Expiration timestamp for the current OTP code.
  final String? otpExpiresAt;

  /// ISO 8601 timestamp of the user's last successful login.
  final String? lastLogin;

  const UserModel({
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
    // User-specific fields
    required this.name,
    required this.mobile,
    required this.passwordHash,
    this.isVerified = false,
    this.otpCode,
    this.otpExpiresAt,
    this.lastLogin,
  });

  // ── Deserialisation ───────────────────────────────────────────────

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final base = BaseModel.baseFromMap(map);
    final mobileVal =
        map['mobile']?.toString() ?? map['mobile_number']?.toString() ?? '';
    final passVal =
        map['password_hash']?.toString() ?? map['pin']?.toString() ?? '';
    final isVer = (map['is_verified'] as num?)?.toInt() == 1 ||
        map['is_verified'] == true ||
        map['pin'] != null;

    final idVal = (base['id'] as String).isNotEmpty
        ? (base['id'] as String)
        : (mobileVal.isNotEmpty ? mobileVal : BaseModel.newId());

    return UserModel(
      // Base fields
      id: idVal,
      createdAt: (base['created_at'] as String).isNotEmpty
          ? (base['created_at'] as String)
          : DateTime.now().toUtc().toIso8601String(),
      updatedAt: (base['updated_at'] as String).isNotEmpty
          ? (base['updated_at'] as String)
          : DateTime.now().toUtc().toIso8601String(),
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
      // User-specific fields
      name: map['name']?.toString() ?? '',
      mobile: mobileVal,
      passwordHash: passVal,
      isVerified: isVer,
      otpCode: map['otp_code']?.toString(),
      otpExpiresAt: map['otp_expires_at']?.toString(),
      lastLogin: map['last_login']?.toString(),
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────

  @override
  Map<String, dynamic> toMap() => {
        ...baseToMap(),
        'name': name,
        'mobile': mobile,
        'mobile_number': mobile,
        'password_hash': passwordHash,
        'is_verified': isVerified ? 1 : 0,
        'otp_code': otpCode,
        'otp_expires_at': otpExpiresAt,
        'last_login': lastLogin,
      };

  // ── Display helpers ───────────────────────────────────────────────

  String get firstName => name.trim().split(' ').first;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get formattedMobile {
    if (mobile.length >= 10) {
      final last10 = mobile.substring(mobile.length - 10);
      return '+91 ${last10.substring(0, 5)} ${last10.substring(5)}';
    }
    return mobile;
  }
}
