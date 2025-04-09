import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import '/backend/server_conn_controller.dart';
import './backend/chat_data.dart';


class MyAppState extends ChangeNotifier { // it extends ChangeNotifier that allowes to notify others about it's changes
  var current = WordPair.random(); // Deprecated functionality

  final Map<String, ChatData> _chats = {};
  final Map<String, ChatMetaData> _chatList = {};

  var currentUser = "123"; // Id of the logged-in user
  bool isLoading = false;
  // String? errorMessage;

  // Server 
  late ServerConnController server;
  // late WebSocketChannel socket;
  bool _connected = false;
  bool get isConnected => _connected; // Getter for _connected

  // Temporarily hardcoded creds replace with server login request ===========================================
  var username = "admin";
  var password = "password";

  // Account login status
  var loggedInAsUser = false;
  var loggedInAsGuest = false;
  var guestUsername = "";

  MyAppState() {
    server = ServerConnController();
    _initializeChats(); // Load from disk or stub with test data
  }

  Future<void> _initializeChats() async {
    // // Load from file or initialize empty/default values
    // chatCache = await ChatStorage.loadChatCache();
    // chatList = await ChatStorage.loadChatMetadata();
    // notifyListeners();

    // Generate some dummy data
    for (int n = 0; n <= 3; n ++) {
      ChatData chatData = ChatData([], []);
      for (int k = 0; k <= 2; k ++) {
        chatData.addMessage(n.toString(), "Hello", DateTime.now());
      }
      _chats[n.toString()] = chatData;
      ChatMetaData metaData = ChatMetaData(n.toString(), "someting wont", DateTime.now(), n);
      _chatList[n.toString()] = metaData;
    }
  }

  ChatData getChat(String chatId) {
    return _chats.putIfAbsent(chatId, () => ChatData([], []));
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

  Future<void> connectToServer() async {
    try {
      await server.connect();
      _connected = true;
      notifyListeners();
    } catch (e) {
    logger.w("Failed to connect: $e");
    }
  }

  void disconnectFromServer() {
    server.disconnect();
    _connected = false;
    notifyListeners();
  }

  // Next button handler
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  // Guest login that requires only username
  void logInGuest(String name) async { // What is better, to return the value, or 
    isLoading = true;
    notifyListeners();

    int res = await server.sendGuestLoginRequest(name);
    isLoading = false;
    
    if (res == 0) {
      loggedInAsGuest = true;
      guestUsername = name;
      notifyListeners();
    }
  }

  // Login as a user
  Future<bool> logIn(String name, String passwrd) async { // Refactor function and its dependants
    // if (name == username && passwrd == password){
      isLoading = true;
      notifyListeners();

      int res = await server.sendLoginRequest(name, passwrd); // Send login request to the server, How do I wait for response?

      isLoading = false;

      if (res == 0){
        loggedInAsUser = true;
        // errorMessage = null;
        notifyListeners();
        return true;
      } else {
        // errorMessage = "Login failed";
        notifyListeners();
        logger.i("Login failed");
        return false;
      }
    // }
    // return false;
  }

  // Login as a user
  Future<bool> signUp(String name, String passwrd, String email) async { // Refactor function and its dependants
    // if (name == username && passwrd == password){
    isLoading = true;
    notifyListeners();

    int res = await server.sendSignUpRequest(name, passwrd, email); // Send login request to the server, How do I wait for response?
    isLoading = false;

    if (res == 0){
      return true;
    } else {
      // errorMessage = "Login failed";
      notifyListeners();
      logger.i("Sign up failed");
      return false;
    }
  }

  // Logout both, user and guest
  void logOut() {
    loggedInAsUser = false;
    loggedInAsGuest = false;
    server.sendLogoutRequest(currentUser); // We are not going to wait for response
    server.disconnect();
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
