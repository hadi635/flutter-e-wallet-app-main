import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthService {
  static const String _sessionKey = 'admin_session_active';
  static const String _userHash =
      '6975655e534ab824b12ef07c85c741e2c586ec413aca11d5e97da7269987ac44';
  static const String _passwordHash =
      'a421a3eced7fa3dfef33949dae4a5107fdd6ec15841fc5596d54e4f02f883212';

  String _hash(String value) {
    return sha256.convert(utf8.encode(value.trim())).toString();
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final valid =
        _hash(username) == _userHash && _hash(password) == _passwordHash;
    if (!valid) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);
    return true;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionKey) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
