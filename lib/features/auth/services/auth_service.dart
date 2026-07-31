import 'dart:convert';
import 'dart:math';
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
  final bool requiresOtp;
  final UserModel? user;
  final String? otpCode; // Exposed for testing/demo display
  final String? error;

  const AuthResult({
    required this.success,
    this.requiresOtp = false,
    this.user,
    this.otpCode,
    this.error,
  });
}

/// Handles login, registration, OTP verification, session management, and soft-delete.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _db = DatabaseService.instance;

  // ── Password Hashing ───────────────────────────────────────────────
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ── OTP Generator ──────────────────────────────────────────────────
  String _generateOtp() {
    final random = Random();
    final otp = 100000 + random.nextInt(900000);
    return otp.toString();
  }

  // ── Login ──────────────────────────────────────────────────────────
  Future<AuthResult> login(String mobile, String password) async {
    final hash = _hashPassword(password);
    final cleanMobile = mobile.trim();

    // Query non-deleted user matching mobile & password hash
    final result = await _db.query(
      '''SELECT * FROM users
         WHERE mobile = ?
           AND password_hash = ?
           AND ${DbBaseFields.notDeleted}
         LIMIT 1''',
      [cleanMobile, hash],
    );

    if (!result.success) {
      return AuthResult(success: false, error: result.error);
    }

    if (result.isEmpty) {
      return const AuthResult(
        success: false,
        error: 'Invalid mobile number or password.',
      );
    }

    final user = UserModel.fromMap(result.rows.first);

    // Check if account is verified
    if (!user.isVerified) {
      // Re-generate fresh OTP for verification if needed
      final otp = _generateOtp();
      final expiresAt =
          DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String();

      await _db.query(
        '''UPDATE users
           SET otp_code = ?, otp_expires_at = ?, updated_at = ?
           WHERE id = ?''',
        [otp, expiresAt, DateTime.now().toUtc().toIso8601String(), user.id],
      );

      return AuthResult(
        success: false,
        requiresOtp: true,
        user: user,
        otpCode: otp,
        error: 'Please complete OTP verification to activate your account.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();

    // Update last_login, updated_at, version
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
      String name, String mobile, String password) async {
    final cleanMobile = mobile.trim();

    // Check for existing user with same mobile number
    final existing = await _db.query(
      '''SELECT id, is_verified FROM users
         WHERE mobile = ?
           AND ${DbBaseFields.notDeleted}
         LIMIT 1''',
      [cleanMobile],
    );

    if (!existing.success) {
      return AuthResult(success: false, error: existing.error);
    }

    if (existing.isNotEmpty) {
      final isVerified =
          (existing.rows.first['is_verified'] as num?)?.toInt() == 1;
      if (isVerified) {
        return const AuthResult(
          success: false,
          error: 'An account with this mobile number already exists.',
        );
      }
    }

    final hash = _hashPassword(password);
    final otp = _generateOtp();
    final expiresAt =
        DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String();

    if (existing.isNotEmpty) {
      // Update existing pending user with new password & OTP
      final existingId = existing.rows.first['id'].toString();
      await _db.query(
        '''UPDATE users
           SET name = ?, password_hash = ?, otp_code = ?, otp_expires_at = ?, updated_at = ?
           WHERE id = ?''',
        [
          name.trim(),
          hash,
          otp,
          expiresAt,
          DateTime.now().toUtc().toIso8601String(),
          existingId
        ],
      );
    } else {
      // Create new pending user
      final fields = {
        ...DbBaseFields.newRecord(),
        'name': name.trim(),
        'mobile': cleanMobile,
        'password_hash': hash,
        'otp_code': otp,
        'otp_expires_at': expiresAt,
        'is_verified': 0,
        'status': BaseModelStatus.pending,
        'last_login': null,
      };

      final insertResult = await _db.insertRecord('users', fields);
      if (!insertResult.success) {
        return AuthResult(success: false, error: insertResult.error);
      }
    }

    // Fetch newly inserted/updated user
    final userResult = await _db.query(
      'SELECT * FROM users WHERE mobile = ? AND ${DbBaseFields.notDeleted} LIMIT 1',
      [cleanMobile],
    );

    if (userResult.isNotEmpty) {
      final user = UserModel.fromMap(userResult.rows.first);

      // Self-reference created_by / updated_by
      if (user.createdBy == null || user.createdBy!.isEmpty) {
        final selfRef = DbBaseFields.buildSetClause({
          'created_by': user.id,
          'updated_by': user.id,
        });
        await _db.query(
          'UPDATE users SET ${selfRef.clause} WHERE id = ?',
          [...selfRef.params, user.id],
        );
      }

      return AuthResult(
        success: true,
        requiresOtp: true,
        user: user,
        otpCode: otp,
      );
    }

    return const AuthResult(success: true);
  }

  // ── Verify OTP ─────────────────────────────────────────────────────
  Future<AuthResult> verifyOtp(String mobile, String inputOtp) async {
    final cleanMobile = mobile.trim();
    final cleanOtp = inputOtp.trim();

    final result = await _db.query(
      'SELECT * FROM users WHERE mobile = ? AND ${DbBaseFields.notDeleted} LIMIT 1',
      [cleanMobile],
    );

    if (!result.success || result.isEmpty) {
      return const AuthResult(
        success: false,
        error: 'User not found. Please register again.',
      );
    }

    final user = UserModel.fromMap(result.rows.first);

    if (user.otpCode == null || user.otpCode != cleanOtp) {
      return const AuthResult(
        success: false,
        error: 'Invalid OTP. Please check the code and try again.',
      );
    }

    if (user.otpExpiresAt != null) {
      final expires = DateTime.parse(user.otpExpiresAt!);
      if (DateTime.now().toUtc().isAfter(expires)) {
        return const AuthResult(
          success: false,
          error: 'OTP has expired. Please request a new OTP.',
        );
      }
    }

    final now = DateTime.now().toUtc().toIso8601String();

    // Mark as verified & active
    final updateFields = {
      ...DbBaseFields.updatedRecord(
        updatedBy: user.id,
        currentVersion: user.version,
      ),
      'is_verified': 1,
      'status': BaseModelStatus.active,
      'otp_code': null,
      'otp_expires_at': null,
      'last_login': now,
    };

    final set = DbBaseFields.buildSetClause(updateFields);
    await _db.query(
      'UPDATE users SET ${set.clause} WHERE id = ?',
      [...set.params, user.id],
    );

    final updatedUser = UserModel.fromMap({
      ...user.toMap(),
      ...updateFields,
    });

    await _persistSession(updatedUser);
    return AuthResult(success: true, user: updatedUser);
  }

  // ── Resend OTP ─────────────────────────────────────────────────────
  Future<AuthResult> resendOtp(String mobile) async {
    final cleanMobile = mobile.trim();
    final result = await _db.query(
      'SELECT * FROM users WHERE mobile = ? AND ${DbBaseFields.notDeleted} LIMIT 1',
      [cleanMobile],
    );

    if (!result.success || result.isEmpty) {
      return const AuthResult(
        success: false,
        error: 'User not found.',
      );
    }

    final user = UserModel.fromMap(result.rows.first);
    final newOtp = _generateOtp();
    final expiresAt =
        DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String();

    await _db.query(
      '''UPDATE users
         SET otp_code = ?, otp_expires_at = ?, updated_at = ?
         WHERE id = ?''',
      [newOtp, expiresAt, DateTime.now().toUtc().toIso8601String(), user.id],
    );

    return AuthResult(
      success: true,
      otpCode: newOtp,
      user: user,
    );
  }

  // ── Soft Delete ────────────────────────────────────────────────────
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

  // ── Session Management ─────────────────────────────────────────────
  Future<void> _persistSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserId, user.id);
    await prefs.setString(AppConstants.keyUserName, user.name);
    await prefs.setString(AppConstants.keyUserMobile, user.mobile);
  }

  Future<UserModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(AppConstants.keyUserId);
    final name = prefs.getString(AppConstants.keyUserName);
    final mobile = prefs.getString(AppConstants.keyUserMobile);

    if (id != null && name != null && mobile != null) {
      final now = DateTime.now().toUtc().toIso8601String();
      return UserModel(
        id: id,
        name: name,
        mobile: mobile,
        passwordHash: '',
        isVerified: true,
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
    await prefs.remove(AppConstants.keyUserMobile);
  }

  Future<bool> isLoggedIn() async {
    final user = await getStoredUser();
    return user != null;
  }
}
