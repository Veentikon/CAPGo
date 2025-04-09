import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';


final logger = Logger();


class ServerConnController {
  WebSocketChannel? _channel;
  Map<String, Completer> pendingRequests = {};

  // Unique Id request generation
  final uuid = Uuid();

  // Connection initialization
  Future<void> connect() async {
    if (_channel != null) return; // already connected
    // Connect to server running in docker container through exposed port 8080
    _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080/ws'));
    listenToServer();
  }

  // Connection or channel getter
  WebSocketChannel? get channel => _channel;

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  // Listen for server responses, match them with pending requests by Id and resolve them
  void listenToServer() {
    _channel!.stream.listen((response) {
       /* method is asynchronous but does not block the main thread
       sets up a listener that will process messages whenever they arrive. */
      final decodedResponse = jsonDecode(response);
      final requestId = decodedResponse['request_id'];
      
      if (pendingRequests.containsKey(requestId)) {
        pendingRequests[requestId]!.complete(decodedResponse);
        pendingRequests.remove(requestId);
      } else {
        // Handle unsolicited messages (like notifications, incoming messages)
        handleNotification(decodedResponse);
      }
    });
  }

  /* Process unsolicited, server initiated messages */
  void handleNotification(Map<String, dynamic> decodedMessage) {
    String type = decodedMessage['type'] ?? 'unknown';
    String requestId = decodedMessage['request_id'] ?? '';

    if (type == 'response') {
      if (pendingRequests.containsKey(requestId)) {
        pendingRequests[requestId]!.complete(decodedMessage); // Completes the Future
        pendingRequests.remove(requestId);
      }
    } else if (type == 'new_message') {
      // Process a broadcast message or something unrelated to a specific request
      logger.i("New message: ${decodedMessage['content']}");
      // Update application state here
    } else if (type == 'error') {
      if (pendingRequests.containsKey(requestId)) {
        pendingRequests[requestId]!.completeError(decodedMessage['error']);
        pendingRequests.remove(requestId);
      }
    } else {
      logger.w("Unhandled notification type: $type");
    }
  }

  /* Handle sending requests to the server */
  Future<Map<String, dynamic>> sendRequest(String requestId, Map<String, dynamic> request) {
    if (_channel == null) {
      return Future.error("Connection is not established. Please connect to the server first.");
    }

    Completer<Map<String, dynamic>> completer = Completer();
    pendingRequests[requestId] = completer;

    _channel!.sink.add(jsonEncode(request)); // Send request through web socket connection
    
    return completer.future; // Returns the Future that will be completed by handleNotification
  }

  // The following methods handle requests, they return int status code, -1 - failed request, 0 - successful request
  Future<int> sendLoginRequest(username, password) async {
    var requestId = uuid.v4();
    var request = {
      "action": "login",
      "request_id": requestId,
      "data": {
        "username": username,
        "password": password,
      }
    };
    try {
      print(request);
      var response = await sendRequest(requestId, request);
      if (response["type"] == "response") {
        if (response["status"] == "success") {
          logger.i("Login successful!");
          return 0;
        } else if (response["status"] == "fail") {
          logger.i("Login failed: ${response["message"]}");
          return -1;
        }
      }
      logger.w("Unexpected response format: $response");
      return -1; // Fallback failure if the response type is unexpected
    } catch (error) {
      logger.w("Login failed $error");
      return -1; // Failure due to exception (e.g., network error)
    }
  }

  Future<int> sendLogoutRequest(String userId) async {
    var requestId = uuid.v4();
    var request = {
      "action": "logout",
      "request_id": requestId,
      "data": {
        "user_id": userId,
      }
    };
    try {
      var response = await sendRequest(requestId, request);
      if (response["type"] == "response") {
        if (response["status"] == "success") {
          logger.i("Logout successful!");
          return 0;
        } else if (response["status"] == "fail") {
          logger.w("Logout failed");
          return -1;
        }
      }
      logger.w("Uexpected response format $response");
      return -1;
    } catch (error) {
      logger.w("Sign up failed: $error");
      return -1;
    }
  }

  Future<int> sendSignUpRequest(username, password, email) async {
    var requestId = uuid.v4();
    var request = {
      "action": "sign_up",
      "request_id": requestId,
      "data": {
        "username": username,
        "password": password,
        "email": email,
      }
    };
    try {
      var response = await sendRequest(requestId, request);
      if (response["type"] == "response") {
        if (response["status"] == 'success') {
          logger.i("Sign up successful!");
          return 0;
        } else if (response["status"] == "fail") {
          logger.i("Sign up failed: ${response["message"]}");
          return -1;
        } 
      }
      logger.w("Unexpected response format: $response");
      return -1; // Fallback failure if the response type is unexpected
    } catch (error) {
      logger.w("Sign up failed: $error");
      return -1;
    }
  }

  Future<int> sendGuestLoginRequest(username) async {
    var requestId = uuid.v4();
    var request = {
      "action": "guest_login",
      "request_id": requestId,
      "data": {
        "username": username
      }
    };
    try {
      var response = await sendRequest(requestId, request);
      if (response["type"] == "response") {
        if (response["status"] == "success") {
          logger.i("Login successful!");
          return 0;
        } else if (response["status"] == "fail") {
          logger.i("Login failed: ${response["message"]}");
          return -1;
        }
      }
      logger.w("Unexpected response type");
      return -1;
    } catch (error) {
      logger.w("Error: $error");
      return -1;
    }
  }

  Future<int> sendDirectMessageRequest(senderId, recipientId, message) async {
    var requestId = uuid.v4();
    var request = {
      "action": "guest_direct_message",
      "request_id": requestId,
      "data": {
        "sender": senderId,
        "recipient": recipientId,
        "message": message
      }
    };
    try {
      var response = await sendRequest(requestId, request);
      if (response["type"] == "response") {
        if (response["status"] == "success") {
          logger.i("Message send successfully");
          return 0;
        } else if (response["status"] == "fail") {
          logger.w("Message did not reach destinnation: ${response["message"]}");
          return -1;
        }
      }
      logger.w("Unexpected response format: $response");
      return -1;
    } catch (error) {
      logger.w("Error: $error");
      return -1;
    }
  }

  Future<int> sendChatroomMessageRequest(senderId, roomId, message) async { // Need to know if successful?
    var requestId = uuid.v4();
    var request = {
        "action": "send_room_message",
        "request_id": requestId,
        "data": {
          "sender": senderId,
          "room_id": roomId,
          "message": message
      }
    };
    try {
      var response = await sendRequest(requestId, request);
      if (response["type"] == "response") {
        if (response["status"] == "success") {
          logger.i("Message sent successfully!");
          return 0;
        }
      } else if (response["status"] == "fail") {
        logger.w("Failed to deliver message: ${response["message"]}");
        return -1;
      }
      logger.w("Unexpected response format: $response");
      return -1;
    } catch (error) {
      logger.w("Error: $error");
      return -1;
    }
  }

  // Send request in non-blocking way from UI perspective, get and process server response
  Future<int> sendJoinRoomRequest(roomId, userId) {
    var requestId = uuid.v4();
    var request = {
      "action": "join_room",
      "request_id": requestId,
      "data": {
        "user_id": userId,
        "room_id": roomId,
      },
    };
    
    return sendRequest(requestId, request).then((response) {
      if (response["type"] == "response" && response["status"] == "success") {
        logger.i("Successfully joined the room!");
        return 0;
      } else {
        logger.i("Failed to join the room: ${response["message"]}");
        return -1;
      }
    }).catchError((error) {
      logger.w("Error joining room: $error");
      return -1;
    });
  }

  Future<int> sendGetMessagesRequest(roomId, limit) {
    var requestId = uuid.v4();
    var request = {
      "action": "get_messages",
      "request_id": requestId,
      "data": {
        "room_id": roomId,
        "limit": limit,
      }
    };
    return sendRequest(requestId, request).then((response) {
      if (response["type"] == "response" && response["status"] == "success") {
        logger.i("Message delivered!");
        return 0;
      } else {
        logger.w("Message not delivered: ${response["message"]}");
        return -1;
      }
    }).catchError((error) {
      logger.w("Error sending message: $error");
      return -1;
    });
  }

  Future<int> sendLeaveRoomRequest(userId, roomId) {
    var requestId = uuid.v4();
    var request = {
      "action": "leave_room",
      "request_id": requestId,
      "data": {
        "user_id": userId,
        "room_id": roomId,
      }
    };
    return sendRequest(requestId, request).then((response) {
      if (response["type"] == "response" && response["status"] == "success") {
        logger.i("Successfully left the room!");
        return 0;
      } else {
        logger.w("Failed to leave the room: ${response["message"]}");
        return -1;
      }
    }).catchError((error) {
      logger.w("Error leaving room: $error");
      return -1;
    });
  }
}