/// Simple PIN-based local auth. No network needed.
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../data/database.dart';

String hashPin(String pin) {
  final bytes = utf8.encode('adaptattend_salt_$pin');
  return sha256.convert(bytes).toString();
}

class AuthService {
  static const _keyUserId = 'current_user_id';
  static const _keyOrgId  = 'current_org_id';

  static AppUser? currentUser;
  static Org?     currentOrg;

  /// Attempt login. Returns the user on success, null on failure.
  static Future<AppUser?> login(String orgId, String username, String pin) async {
    final user = await db.getUserByUsername(orgId, username);
    if (user == null) return null;
    if (user.pinHash != hashPin(pin)) return null;
    if (!user.isActive) return null;

    currentUser = user;
    currentOrg  = await db.getFirstOrg(); // for demo single-org setup

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, user.id);
    await prefs.setString(_keyOrgId, orgId);
    return user;
  }

  /// Restore session on app restart.
  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    final orgId  = prefs.getString(_keyOrgId);
    if (userId == null || orgId == null) return false;

    final user = await db.getUserById(userId);
    if (user == null || !user.isActive) return false;

    currentUser = user;
    currentOrg  = await db.getFirstOrg();
    return true;
  }

  static Future<void> logout() async {
    currentUser = null;
    currentOrg  = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyOrgId);
  }

  static bool get isLoggedIn => currentUser != null;
  static bool get isManager  => currentUser?.role == 'manager';
}
