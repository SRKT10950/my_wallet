import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/db/db_base_fields.dart';
import '../../../core/models/base_model.dart';
import '../../../core/services/database_service.dart';
import '../models/user_model.dart';

/// Result type for auth operations.
class AuthResult {
  final bool success;
  final UserModel? user;
  final String? error;

  const AuthResult({required this.success, this.user, this.error});
}

/// Handles login, registration, session management, and soft-delete.
///
/// All DB writes use [DbBaseFields] helpers to ensure every record
/// includes the full set of standardized audit/control fields.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _db = DatabaseService.instance;

  // ── Password Hashing ───────────────────────────────────────────────
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ── Login ──────────────────────────────────────────────────────────
  Future<AuthResult> login(String email, String password) async {
    final hash = _hashPassword(password);
    final normalizedEmail = email.trim().toLowerCase();

    // Only match active, non-deleted users
    final result = await _db.query(
      '''SELECT * FROM users
         WHERE email = ?
           AND password_hash = ?
           AND ${DbBaseFields.notDeleted}
           AND status = '${BaseModelStatus.active}'
         LIMIT 1''',
      [normalizedEmail, hash],
    );

    if (!result.success) {
      return AuthResult(success: false, error: result.error);
    }

    if (result.isEmpty) {
      return const AuthResult(
        success: false,
        error: 'Invalid email or password.',
      );
    }

    final user = UserModel.fromMap(result.rows.first);
    final now = DateTime.now().toUtc().toIso8601String();

    // Update last_login, updated_at, version (optimistic lock increment)
    final updateFields = {
      ...DbBaseFields.updatedRecord(
        updatedBy: user.id,
        currentVersion: user.version,
      ),
      'last_login': now,
    };
    final set = DbBaseFields.buildSetClause(updateFields);
    await _db.query(
      'UPDATE users SET ${set.clause} WHERE id = ?',
      [...set.params, user.id],
    );

    await _persistSession(user);
    return AuthResult(success: true, user: user);
  }

  // ── Register ───────────────────────────────────────────────────────
  Future<AuthResult> register(
      String name, String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Check for existing active account with same email
    final existing = await _db.query(
      '''SELECT id FROM users
         WHERE email = ?
           AND ${DbBaseFields.notDeleted}
         LIMIT 1''',
      [normalizedEmail],
    );

    if (!existing.success) {
      return AuthResult(success: false, error: existing.error);
    }

    if (existing.isNotEmpty) {
      return const AuthResult(
        success: false,
        error: 'An account with this email already exists.',
      );
    }

    final hash = _hashPassword(password);

    // Merge base fields + user-specific fields into one insert map
    final fields = {
      ...DbBaseFields.newRecord(), // all 13 base fields (no createdBy yet)
      'name': name.trim(),
      'email': normalizedEmail,
      'password_hash': hash,
      'last_login': null,
    };

    final insertResult = await _db.insertRecord('users', fields);

    if (!insertResult.success) {
      return AuthResult(success: false, error: insertResult.error);
    }

    // Fetch the newly created user by email
    final userResult = await _db.query(
      'SELECT * FROM users WHERE email = ? AND ${DbBaseFields.notDeleted} LIMIT 1',
      [normalizedEmail],
    );

    if (userResult.isNotEmpty) {
      final user = UserModel.fromMap(userResult.rows.first);

      // Now update created_by / updated_by with the new user's own ID
      final selfRef = DbBaseFields.buildSetClause({
        'created_by': user.id,
        'updated_by': user.id,
      });
      await _db.query(
        'UPDATE users SET ${selfRef.clause} WHERE id = ?',
        [...selfRef.params, user.id],
      );

      await _persistSession(user);
      return AuthResult(success: true, user: user);
    }

    return const AuthResult(success: true);
  }

  // ── Soft Delete ────────────────────────────────────────────────────

  /// Soft-deletes the user account. Does NOT physically remove the record.
  /// Sets is_deleted = 1, deleted_at, deleted_by, status = archived.
  Future<AuthResult> deleteAccount(UserModel user) async {
    final result = await _db.softDelete(
      'users',
      user.id,
      deletedBy: user.id,
      currentVersion: user.version,
    );

    if (!result.success) {
      return AuthResult(success: false, error: result.error);
    }

    await logout();
    return const AuthResult(success: true);
  }

  // ── Session ────────────────────────────────────────────────────────
  Future<void> _persistSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserId, user.id);
    await prefs.setString(AppConstants.keyUserName, user.name);
    await prefs.setString(AppConstants.keyUserEmail, user.email);
  }

  Future<UserModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(AppConstants.keyUserId);
    final name = prefs.getString(AppConstants.keyUserName);
    final email = prefs.getString(AppConstants.keyUserEmail);

    if (id != null && name != null && email != null) {
      final now = DateTime.now().toUtc().toIso8601String();
      return UserModel(
        id: id,
        name: name,
        email: email,
        passwordHash: '',
        createdAt: now,
        updatedAt: now,
      );
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserEmail);
  }

  Future<bool> isLoggedIn() async {
    final user = await getStoredUser();
    return user != null;
  }
}
