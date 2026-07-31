import '../../../core/models/base_model.dart';

/// Represents an authenticated user in My Wallet.
///
/// Extends [BaseModel] to inherit all 13 standardized audit/control fields.
/// User-specific fields are: [name], [mobile], [passwordHash], [isVerified],
/// [otpCode], [otpExpiresAt], [lastLogin].
class UserModel extends BaseModel {
  // ── User-specific fields ──────────────────────────────────────────
  final String name;
  final String mobile;

  /// SHA-256 hashed password — never store or log plain-text.
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
    return UserModel(
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
      // User-specific fields
      name: map['name']?.toString() ?? '',
      mobile: map['mobile']?.toString() ?? '',
      passwordHash: map['password_hash']?.toString() ?? '',
      isVerified: (map['is_verified'] as num?)?.toInt() == 1 ||
          map['is_verified'] == true,
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
        'password_hash': passwordHash,
        'is_verified': isVerified ? 1 : 0,
        'otp_code': otpCode,
        'otp_expires_at': otpExpiresAt,
        'last_login': lastLogin,
      };

  // ── Display helpers ───────────────────────────────────────────────

  /// Returns the user's first name from [name].
  String get firstName => name.trim().split(' ').first;

  /// Returns initials (up to 2 letters) from [name].
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Formatted mobile number for display (e.g. `+91 98765 43210`)
  String get formattedMobile {
    if (mobile.length == 10) {
      return '+91 ${mobile.substring(0, 5)} ${mobile.substring(5)}';
    }
    return mobile;
  }
}
