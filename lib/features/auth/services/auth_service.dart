import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/database_service.dart';
import '../models/user_model.dart';

/// Result type for auth operations.
class AuthResult {
  final bool success;
  final UserModel? user;
  final String? error;

  const AuthResult({required this.success, this.user, this.error});
}

/// Handles login, registration, and session management.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _db = DatabaseService.instance;

  // ── Hashing ────────────────────────────────────────────────────────
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ── Login ──────────────────────────────────────────────────────────
  Future<AuthResult> login(String email, String password) async {
    final hash = _hashPassword(password);
    final result = await _db.query(
      'SELECT * FROM users WHERE email = ? AND password_hash = ? LIMIT 1',
      [email.trim().toLowerCase(), hash],
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

    // Update last_login timestamp
    await _db.query(
      'UPDATE users SET last_login = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), user.id],
    );

    await _persistSession(user);
    return AuthResult(success: true, user: user);
  }

  // ── Register ───────────────────────────────────────────────────────
  Future<AuthResult> register(
      String name, String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Check if email already exists
    final existing = await _db.query(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
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
    final now = DateTime.now().toIso8601String();

    final insertResult = await _db.query(
      'INSERT INTO users (name, email, password_hash, created_at) VALUES (?, ?, ?, ?)',
      [name.trim(), normalizedEmail, hash, now],
    );

    if (!insertResult.success) {
      return AuthResult(success: false, error: insertResult.error);
    }

    // Fetch the created user
    final userResult = await _db.query(
      'SELECT * FROM users WHERE email = ? LIMIT 1',
      [normalizedEmail],
    );

    if (userResult.isNotEmpty) {
      final user = UserModel.fromMap(userResult.rows.first);
      await _persistSession(user);
      return AuthResult(success: true, user: user);
    }

    return const AuthResult(
      success: true,
      error: null,
    );
  }

  // ── Session ────────────────────────────────────────────────────────
  Future<void> _persistSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyUserId, user.id);
    await prefs.setString(AppConstants.keyUserName, user.name);
    await prefs.setString(AppConstants.keyUserEmail, user.email);
  }

  Future<UserModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(AppConstants.keyUserId);
    final name = prefs.getString(AppConstants.keyUserName);
    final email = prefs.getString(AppConstants.keyUserEmail);

    if (id != null && name != null && email != null) {
      return UserModel(
        id: id,
        name: name,
        email: email,
        createdAt: '',
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
