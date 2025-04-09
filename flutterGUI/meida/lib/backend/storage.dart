// Abstracts read/write methods to local storage (SharedPreferences, file I/O, etc.)

import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  static Future<String?> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username'); 
  }

  static Future<void> saveServerIP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverIP', ip);
  }

  static Future<String?> loadServerIP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('serverIP');
  }

  /// Save JSON encoded message logs
  /// Save user token
  /// Save App theme preference
  /// Last connected server IP
}