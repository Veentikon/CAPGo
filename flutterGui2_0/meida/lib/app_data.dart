import 'dart:io';

import 'package:flutter/material.dart';
import 'package:meida/backend/server_conn_controller.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// import '/backend/server_conn_controller.dart';
import '/backend/chat_data.dart';
// import 'backend/storage.dart';


class MyAppState extends ChangeNotifier { // it extends ChangeNotifier that allows to notify others about it's changes
  PersistentWebSocketManager socketManager = PersistentWebSocketManager();
  final Map<String, ChatData> _chats = {};
  final Map<String, ChatMetaData> _chatList = {};


  Color color1 = Color.fromRGBO(247, 55, 79, 1.0);
  Color color1Accent = Color.fromRGBO(230, 67, 86, 1);
  Color color2 = Color.fromRGBO(136, 48, 78, 1.0);
  Color color2Accent = Color.fromRGBO(97, 37, 57, 1);
  Color color3 = Color.fromRGBO(82, 37, 70, 1.0);
  Color color3Accent = Color.fromRGBO(145, 63, 123, 1);
  Color color4 = Color.fromRGBO(44, 44, 44, 1.0);
  Color color4Accent = Color.fromRGBO(61, 61, 61, 1);

  bool isLoading = false;
  bool loggedIn = false; // Reset to false when done testing

  // Hadrcoded temporary credentials
  var currentUser = "";

  var testUser = "";
  var testPassword = "password";

  late ServerConnController server;
  late WebSocketChannel socket;
  bool _connected = false;
  bool get isConnected => _connected; // Getter for _connected

  // Account login status
  // var loggedInAsUser = false;
  // var loggedInAsGuest = false;
  // var guestUsername = "";

  MyAppState() { // Should be triggered only on login
    server = ServerConnController(socketManager);
  }

  void setNotLoading() {
    isLoading = false;
    notifyListeners();
  }

  // /// this can have two parts, load from local cache and load from DB
  // Future<void> _initializeChats() async {
  //   // Load Chat data from user data cache
  //   var chatDataList = await loadChatData(currentUser);
  //   _chats.addEntries(chatDataList.map((data) => MapEntry(data.id, data)));
  //   // Load Chat meta data from user data cache
  //   var chatMetaDataList = await loadChatMetaData(currentUser);
  //   _chatList.addEntries(chatMetaDataList.map((data) => MapEntry(data.id, data)));
  //   notifyListeners();
  // }

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

  void disconnectFromServer() {
    socketManager.disconnect();
    _connected = false;
    notifyListeners();
  }

  Future<void> ensureConnectedOrThrow(PersistentWebSocketManager manager) async {
  if (manager.isConnected) return;

  final statusFuture = manager.onStatusChange
      .firstWhere((s) =>
          s == ConnectionStatus.connected || s == ConnectionStatus.fail)
      .timeout(const Duration(seconds: 10), onTimeout: () {
    return ConnectionStatus.fail;
  });

  await manager.connect();

  final status = await statusFuture;

  if (status != ConnectionStatus.connected) {
    throw SocketException("Connection failed or timed out.");
  }
}

  // // Guest login that requires only username
  // void logInGuest(String name) async { // What is better, to return the value, or 
  //   if (isLoading) return;
  //   socketManager.connect();

  //   isLoading = true;
  //   notifyListeners();
    
  //   try {
  //     var res = await server.sendGuestLoginRequest(name);
  //     isLoading = false;
  //     notifyListeners();

  //     if (res == 0) {
  //       loggedInAsGuest = true;
  //       guestUsername = name;
  //       notifyListeners();
  //     }
  //   } catch (e) {
  //     isLoading = false;
  //     notifyListeners();
  //     logger.w(e);
  //     return;
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  //   return;
  // }

  // Login as a user
  Future<String> logIn(String name, String passwrd) async {
    if (isLoading) return "A related task is working, cannot login";

    isLoading = true;
    notifyListeners();

    try {
      // Testing override
      if (testUser != "") {
        if (name == testUser && passwrd == testPassword) {
          await Future.delayed(const Duration(seconds: 1));
          loggedIn = true;
          currentUser = "123";
          return "";
        } else {
          return "fail";
        }
      }

      // Ensure socket is connected
      await ensureConnectedOrThrow(socketManager);

      // Attempt login
      var (res, id) = await server.sendLoginRequest(name, passwrd);
      logger.i("Login request sent, response code: $res, user id: $id");

      if (res == 0) {
        loggedIn = true;
        currentUser = id!;
        return "";
      } else if (res == -1) {
        return "$id!";
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
    return "Unexpected fail";
  }


  Future<String> signUp(String name, String passwrd, String email) async { // Refactor function and its dependants
    if (isLoading) return "A related task is working, cannot login";

    isLoading = true;
    notifyListeners();

    try {
      await ensureConnectedOrThrow(socketManager);

      var (res, msg) = await server.sendSignUpRequest(name, passwrd, email); // Send login request to the server, How do I wait for response?
      isLoading = false;

      if (res == 0){
        return "Success";
      } else {
        // errorMessage = "Sign up failed";
        notifyListeners();
        logger.i("Sign up failed");
        return "$msg";
      }
    } catch (e) {
      if (e is SocketException) {
        logger.w("Server is unreachable.");
        return "Server is down or unreachable.";
      }
      logger.w(e.toString()); // In this case the source of error needs to be logged but may not be reported to the user
      return "Sign up failed";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Logout both, user and guest
  void logOut() async {

    isLoading = true;
    loggedIn = false;

    // Wait for confirmation of successfull logout before clean up
    await server.sendLogoutRequest(currentUser); // We are not going to wait for response

    // saveChatData(currentUser, _chats.values.toList()); // Convert Map<String ChatData> to List<ChatData>
    // saveChatMetaData(currentUser, _chatList.values.toList()); // Convert Map<String ChatMetaData> to List<ChatMetaData>

    socketManager.dispose(); // Dispose of the connection
    isLoading = false;
    notifyListeners();
  }
}