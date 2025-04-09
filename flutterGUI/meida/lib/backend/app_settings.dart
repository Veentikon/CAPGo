// Handles app-level preferences (theme, server config, etc.)

import 'package:flutter/material.dart';
import './storage.dart';

class AppSettings extends ChangeNotifier {
  String _serverIP = '127.0.0.1';
  String get serverIP => _serverIP;
  
  ThemeData theme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent)
  );

  void updateServerIP(String ip) {
    _serverIP = ip;
    AppStorage.saveServerIP(ip);
    notifyListeners();
  }

  Future<void> loadSettings() async {
    _serverIP = await AppStorage.loadServerIP() ?? '127.0.0.0';
  }
}