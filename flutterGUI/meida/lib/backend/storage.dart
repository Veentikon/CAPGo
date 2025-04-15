// Abstracts read/write methods to local storage (SharedPreferences, file I/O, etc.)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'chat_data.dart';


Future<Directory> getUserDataDirectory(String userId) async {
  final baseDir = await getApplicationSupportDirectory(); // Or getApplicationDocumentsDirectory()
  final userDir = Directory('${baseDir.path}/chatapp/users/$userId');

  if (!(await userDir.exists())) {
    await userDir.create(recursive: true);
  }

  return userDir;
}

Future<void> saveChatMetaData(String userId, List<ChatMetaData> chats) async {
  final userDir = await getUserDataDirectory(userId);
  final file = File('${userDir.path}/metadata.json');

  final jsonList = chats.map((chat) => chat.toJson()).toList();
  await file.writeAsString(jsonEncode(jsonList));
}

Future<List<ChatMetaData>> loadChatMetaData(String userId) async {
  final userDir = await getUserDataDirectory(userId);
  final file = File('${userDir.path}/metadata.json');

  if (!(await file.exists())) {
    return [];
  }

  final contents = await file.readAsString();
  final List<dynamic> jsonList = jsonDecode(contents);
  return jsonList.map((json) => ChatMetaData.fromJson(json)).toList();
}

Future<void> saveChatData(String userId, List<ChatData> chatData) async {
  final baseDir = await getUserDataDirectory(userId);
  final file = File('${baseDir.path}/chatdata.json');

  final jsonMap = chatData.map((chat) => chat.toJson()).toList();
  await file.writeAsString(jsonEncode(jsonMap));
}

Future<List<ChatData>> loadChatData(String userId) async {
  final baseDir = await getUserDataDirectory(userId);
  final file = File('${baseDir.path}/chatdata.json');

  if (!(await file.exists())) {
    return [];
  }

  final contents = await file.readAsString();
  final List<dynamic> jsonList = jsonDecode(contents);
  return jsonList.map((json) => ChatData.fromJson(json)).toList();
}


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