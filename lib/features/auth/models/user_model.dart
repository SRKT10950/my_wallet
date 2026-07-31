import '../../../core/models/base_model.dart';

/// Represents an authenticated user in My Wallet.
///
/// Extends [BaseModel] to inherit all 13 standardized audit/control fields.
/// User-specific fields are: [name], [email], [passwordHash], [lastLogin].
class UserModel extends BaseModel {
  // ── User-specific fields ──────────────────────────────────────────
  final String name;
  final String email;

  /// SHA-256 hashed password — never store or log plain-text.
  final String passwordHash;

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
    required this.email,
    required this.passwordHash,
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
      email: map['email']?.toString() ?? '',
      passwordHash: map['password_hash']?.toString() ?? '',
      lastLogin: map['last_login']?.toString(),
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────

  @override
  Map<String, dynamic> toMap() => {
        ...baseToMap(),
        'name': name,
        'email': email,
        'password_hash': passwordHash,
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
}
