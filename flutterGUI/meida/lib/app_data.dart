import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import '/backend/server_conn_controller.dart';
import '/backend/chat_data.dart';
import 'backend/storage.dart';


class MyAppState extends ChangeNotifier { // it extends ChangeNotifier that allowes to notify others about it's changes
  var current = WordPair.random(); // Deprecated functionality
  PersistentWebSocketManager socketManager = PersistentWebSocketManager();


  final Map<String, ChatData> _chats = {};
  final Map<String, ChatMetaData> _chatList = {};

  var currentUser = "";
  bool isLoading = false;
  // String? errorMessage;

  late ServerConnController server;
  // late WebSocketChannel socket;
  // bool _connected = false;
  // bool get isConnected => _connected; // Getter for _connected

  // Temporarily hardcoded creds replace with server login request ===========================================
  // Used for testing purposes
  var username = "admin";
  var password = "password";

  // Account login status
  var loggedInAsUser = false;
  var loggedInAsGuest = false;
  var guestUsername = "";

  MyAppState() {
    server = ServerConnController(socketManager);
    _initializeChats(); // Load from disk or stub with test data
  }

  void setNotLoading() {
    isLoading = false;
    notifyListeners();
  }

  /// this can have two parts, load from local cache and load from DB
  Future<void> _initializeChats() async {
    // Load Chat data from user data cache
    var chatDataList = await loadChatData(currentUser);
    _chats.addEntries(chatDataList.map((data) => MapEntry(data.id, data)));
    // Load Chat meta data from user data cache
    var chatMetaDataList = await loadChatMetaData(currentUser);
    _chatList.addEntries(chatMetaDataList.map((data) => MapEntry(data.id, data)));
    notifyListeners();
  }

  ChatData getChat(String chatId) {
    return _chats.putIfAbsent(chatId, () => ChatData(chatId, [], []));
  }

  ChatMetaData getChatMeta(String chatId) {
    return _chatList.putIfAbsent(chatId, () => ChatMetaData(chatId, "", DateTime.now(), 0));
  }

  void sendMessage(String chatId, String senderId, String content) {
    var time = DateTime.now();
    getChat(chatId).addMessage(senderId, content, time);
    _updateLastActive(chatId, time);

    server.sendChatroomMessageRequest(senderId, chatId, content); // May need to check whether the connection was live
    notifyListeners();
  }

  void _updateLastActive(String chatId, DateTime time) {
    final meta = getChatMeta(chatId);
    meta.lastActive = time;
    notifyListeners();
  }

  // void disconnectFromServer() {
  //   server.disconnect();
  //   _connected = false;
  //   notifyListeners();
  // }

  Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final status = await socketManager.onStatusChange
          .firstWhere((s) => s == ConnectionStatus.connected || s == ConnectionStatus.fail)
          .timeout(timeout);
      return status == ConnectionStatus.connected;
    } catch (_) {
      return false;
    }
  }


  // Guest login that requires only username
  void logInGuest(String name) async { // What is better, to return the value, or 
    if (isLoading) return;
    socketManager.connect();

    isLoading = true;
    notifyListeners();
    
    try {
      var res = await server.sendGuestLoginRequest(name);
      isLoading = false;
      notifyListeners();

      if (res == 0) {
        loggedInAsGuest = true;
        guestUsername = name;
        notifyListeners();
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      logger.w(e);
      return;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return;
  }

  // Login as a user
  Future<String> logIn(String name, String passwrd) async {
    if (isLoading) return "A related task is working, cannot login";

    isLoading = true;
    notifyListeners();

    try {
      // Trigger socket connection if not already connected
      await socketManager.connect(); // Will this work or should we call handle disconnect

      if (!socketManager.isConnected) {
        // Wait for either a successful or failed connection (in case there is a delay)
        final status = await socketManager.onStatusChange
          .firstWhere((s) =>
              s == ConnectionStatus.connected || s == ConnectionStatus.fail)
          .timeout(const Duration(seconds: 10), onTimeout: () {
            logger.w("Connection timed out.");
            return ConnectionStatus.fail;
          });

        if (status != ConnectionStatus.connected) {
          isLoading = false;
          notifyListeners(); // The UI must know that the connection failed
          return "Server is unreachable.";
        }
      }

      // Attempt login via server
      var (res, id) = await server.sendLoginRequest(name, passwrd); // This is where the second login gets stuck
      logger.i("Login request sent, result: $res");

      if (res == 0) {
        loggedInAsUser = true;
        currentUser = id!;
        _initializeChats(); // Load cached messages
        return "";
      } else {
        logger.i("Login failed with server response: $res");
        return "Invalid username or password.";
      }
    } catch (e) {
      if (e is SocketException) {
        logger.w("Server is unreachable.");
        return "Server is down or unreachable.";
      }
      logger.w("Unexpected error: $e");
      return "Login failed due to unexpected error.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<String> signUp(String name, String passwrd, String email) async { // Refactor function and its dependants
    if (isLoading) return "A related task is working, cannot login";
    socketManager.connect();

    isLoading = true;
    notifyListeners();

    try {
      int res = await server.sendSignUpRequest(name, passwrd, email); // Send login request to the server, How do I wait for response?
      isLoading = false;

      if (res == 0){
        return "";
      } else {
        // errorMessage = "Login failed";
        notifyListeners();
        logger.i("Sign up failed");
        return "Sign up failed";
      }
    } catch (e) {
      logger.w(e.toString());
      return "Sign up failed";
    }
  }

  // Logout both, user and guest
  void logOut() {
    isLoading = true;
    loggedInAsUser = false;
    loggedInAsGuest = false;
    server.sendLogoutRequest(currentUser); // We are not going to wait for response

    saveChatData(currentUser, _chats.values.toList()); // Convert Map<String ChatData> to List<ChatData>
    saveChatMetaData(currentUser, _chatList.values.toList()); // Convert Map<String ChatMetaData> to List<ChatMetaData>

    socketManager.dispose(); // Dispose of the connection
    isLoading = false;
    notifyListeners();
  }

  // Deprecated part of the code =====================================
  // Next button handler
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }
  var favorites = <WordPair>[]; // A list
  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}


/// When logging int as a guest, could make the session non-persitant in that the communication does not involve SQL db
/// Instead all communication is done through temporary chatrooms existing locally on server
/// Another option is to delete the chatroom automatically once the users leave.
/// Another option is to have guest creds in DB, but to not store messages there, users will only see local messages that
/// the other users send and that they send.
/// Video / Audio calls could be a nice feature
/// How to enable emojis, Gifs, Pictures, etc. how does that affect db
/// 
/// How to properly implement local caching? 
/// Serialization, converting and storing objects in the form of json