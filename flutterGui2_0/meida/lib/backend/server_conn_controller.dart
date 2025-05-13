import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
// import 'package:dart_ping/dart_ping.dart';
import 'package:http/http.dart' as http;


final logger = Logger();
Map<String, Completer> _pendingRequests = {}; // For now at least isolate it to this file


/// Manage connetion to server.
/// Manage disconnections and interrupts.
/// Manage and propagate errors.
/// Createa a StatusController which contains connection status, when a client needs to connect, they 
/// Create a MessageController that acts as a buffer for messages from server
/// Parts of the program can subscribe to Message and Status controllers to listen for specific inputs / signals. 
/// call connect() and listen for the status. Where to put timeout? I think here, that would make login logic simpler
/// Set max number of reconnects, after which a connection failed status is sent to the stream
/// Put connection timeout in the controller, upon x number of connection attempts, return fail signal.
/// The party that called connect would listen on StatusStream for either connected or fail signals and react appropriately.
/// The messageController broadcast stream is subscribed to by _channel aka out Server WebSocket
/// We can subscribe other listeners to the broadcast stream that will read the stream for messages of interest, but in general
/// we in the case of a messenger we want to call a message handler that will deal with formatting and will process the server message.
/// When subscribing for a stream we can provide an optional function that will be executed when stream emits Done signal
/// In the case of Done signal and stream connected to a SocketConnection, it would indicate that the socket has closed aka interruption.
/// 
/// How to deal with disconnects?
/// Try to reconnect with a set limit, once limit reached, emit fail signal on StatusStream
/// There is a nuance, need to set delays between reconnects
/// A simple approach would be to create a handleReconnect method that would call connect a set number of times with delay between the calls
enum ConnectionStatus { connected, disconnected, fail }

class PersistentWebSocketManager {
  final Uri endpoint = Uri.parse("ws://localhost:8080/ws"); // Hardcoded server address
  final Duration reconnectDelay;
  final int reconnectLimit;

  int _reconnectCount = 0;
  bool _connecting = false;
  bool _connected = false;
  bool _shouldReconnect = true; // Flag to control whether the reconnects should happen.

  bool get isConnected => _connected;
  bool get isConnecting => _connecting;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription; // StreamSubscription object returned by listening on _channel.stream

  // late StreamController<ConnectionStatus>? _statusController; // Stream of connection status messages
  final _statusController = StreamController<ConnectionStatus>.broadcast(); // Initialize Status controller right away, it won't be reset as long as app is running
  Stream<ConnectionStatus> get onStatusChange => _statusController.stream;

  late StreamController<String>? _messageController; // encapsulate communication over websocket in a broadcast stream
  Stream<String> get onMessage => _messageController!.stream; // enable subscribing to the server communication stream

  PersistentWebSocketManager({ // This is a constructor class
    this.reconnectDelay = const Duration(seconds: 2), // define delay between reconnections
    this.reconnectLimit = 5, // define the limit of reconnect attempts that can be made before failure
  }) {
    _messageController = StreamController<String>.broadcast();
    // initializeControllers();
  }
  
  void initializeControllers() {
    if (_messageController == null || _messageController!.isClosed) {
      _messageController = StreamController<String>.broadcast();
    }
  }

  Future<bool> isServerLive(String url) async {
    logger.i("Checking if server is running");
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> connect() async { // Try to connect to server
    // delay to ensure status listeners are ready.
    // await Future.delayed(Duration(seconds: 2));

    if (_connecting || _connected) return;

    // _cleanupSocket();
    initializeControllers(); // === Issue here? =======================================================================================================

    // final isLive = await isServerLive("http://172.18.0.1:8080/health");
    // if (!isLive) {
    //   logger.w("Server not running");
    //   _connecting = false;
    //   _connected = false;
    //   _statusController!.add(ConnectionStatus.fail);
    //   return;
    // }
    logger.i("Attempting connection");
    if (_connecting || _connected) return;
    _connecting = true;
    if (_reconnectCount >= reconnectLimit) { // First test whether we reached the limit of reconnects
      logger.i("Reconnect limit reached");
      _connecting = false;
      _connected = false;
      _statusController.add(ConnectionStatus.fail); // failed to connect after reconnect limit reached.
      return;
    }
    try { // If reconnects limits has not been reached, try to connect to server via WebSocket
      // _statusController!.add(ConnectionStatus.connecting); // Add connecting event to stream
      _channel = WebSocketChannel.connect(endpoint);
      logger.i("Connection made");
      _subscription = _channel!.stream.listen(
        (event) {
          try {
            _messageController?.add(event);
          } catch (e) {
            logger.w("Failed to add message to stream: $e");
          }
        },
        onDone: _handleDisconnect, // If done this indicates a closed socket connection, in this case we can call a disconnect handler function
        onError: (_) => _handleError(),
        cancelOnError: true, // Cancel read if we receive error
      );
      _connected = true; 
      _statusController.add(ConnectionStatus.connected);
      return;
    } catch (e) {
      logger.e("Exception occured while trying to connect to server: $e");
      _connected = false;
      _statusController.add(ConnectionStatus.fail);
      return;
    } finally {
      // _reconnects += 1;
      _connecting = false;
    }
  }

  // This supposed to handle the case when the connection failed, the server not responding
  // Possible to trigger reconnects, but for now just finish and dispose of the connection.
  void _handleError() {
    logger.w("Error occured while listening on socket channel");
    _statusController.add(ConnectionStatus.fail);
    _connected = false;
    _connecting = false;
    _reconnectCount = 0;
    // _messageController.close(); // Get rid of the messageController, initiate one when a connect is attempted?
    _cleanupSocket();
    dispose();
    // _handleDisconnect();
    logger.i("Socket connection loss error handled");
    return;
  }

  void _handleDisconnect() async {
    logger.w("Handling disconnect"); // ===============================================
    _cleanupSocket();
    // If this method is called, it means the first reconnect should be schaduled and the reconnects count is reset
    _statusController!.add(ConnectionStatus.disconnected);
    _subscription?.cancel(); // Cancel previous subscription so that it does not hang

    try {
      await _channel?.sink.close(); // close previous channel to free up the resources
    } catch (e) {
      logger.w("Attempted to close an already closed socket");
    }
    _reconnectCount = 0; // First reconnect, reset the counter
    _connected = false;
    _connecting = false;
    logger.i("Reconnecting ...");
    while (!_connected && _reconnectCount < reconnectLimit && _shouldReconnect) {
      // _statusController.add(ConnectionStatus.disconnected);
      // Future.delayed(reconnectDelay, connect); // Delay reconnection
      await connect();
      if (_connected) break;
      await Future.delayed(reconnectDelay);
      _reconnectCount ++;
    }
    logger.i("Disconnect handled");
  }
  

  void send(String data) {
    if (_channel == null || !_connected) {
      logger.w("Cannot send: WebSocket not connected.");
      return;
    }
    try {
      _channel?.sink.add(data);
      logger.i("Request sent");
    } catch (_) {
      logger.w("Cannot send: not connected.");
    }
  }

  void _cleanupSocket() { // Clean up existing socket connection and socket channel
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;

    // Clear pending requests to avoid them hanging forever
    for (var completer in _pendingRequests.values) {
      completer.completeError("Connection lost before response");
    }
    _pendingRequests.clear();
    logger.i("socket cleaned up");
    return;
  }

  void disconnect({bool force = false}) {
    _shouldReconnect = !force;
    logger.i("Client disconnected${force ? " (forced)" : ""}.");
    _cleanupSocket();
    _statusController!.add(ConnectionStatus.disconnected);
    _connecting = false;
    _connected = false;

    if (force) {
      _reconnectCount = 0;
      // Optionally cancel timers or clean up pending reconnects
    }
  }

  void dispose() {
    disconnect();
    // _statusController.close();
    _messageController!.close(); // The problem is we are closing
    // _statusController = null;
    _messageController = null; // Keep it persistent for now, handle edge cases later.
  }
}

class ServerConnController {
  final PersistentWebSocketManager? _ws;
  // Map<String, Completer> pendingRequests = {}; // Moved initialization to global scope

  final uuid = Uuid(); // Unique Id generator
  // WebSocketChannel? get channel => _channel;

  ServerConnController(this._ws) {
    _ws?.onMessage.listen(_handleMessage); // Add _handleMessae as a listener on broadcast message stream piped to a WebSocket connection to server
  }

  void _handleMessage(String response) {
    final decoded = jsonDecode(response);
    final requestId = decoded['request_id'];
    if (_pendingRequests.containsKey(requestId)) {
      _pendingRequests[requestId]!.complete(decoded);
      _pendingRequests.remove(requestId);
    } else {
      handleNotification(decoded);
    }
  }

  Future<Map<String, dynamic>> sendRequest(String requestId, Map<String, dynamic> request, {Duration timeout = const Duration(seconds: 10)}) {
    Completer<Map<String, dynamic>> completer = Completer();
    _pendingRequests[requestId] = completer;
    _ws?.send(jsonEncode(request));
    return completer.future.timeout(timeout, onTimeout: () {
      _pendingRequests.remove(requestId);
      throw TimeoutException("Request $requestId timed out");
    });
  }

  /* Process unsolicited, server initiated messages */
  void handleNotification(Map<String, dynamic> decodedMessage) {
    String type = decodedMessage['type'] ?? 'unknown';
    String requestId = decodedMessage['request_id'] ?? '';

    if (type == 'response') {
      if (_pendingRequests.containsKey(requestId)) {
        _pendingRequests[requestId]!.complete(decodedMessage); // Completes the Future
        _pendingRequests.remove(requestId);
      }
    } else if (type == 'new_message') {
      // Process a broadcast message or something unrelated to a specific request
      logger.i("New message: ${decodedMessage['content']}");
      // Update application state here
    } else if (type == 'error') {
      if (_pendingRequests.containsKey(requestId)) {
        _pendingRequests[requestId]!.completeError(decodedMessage['error']);
        _pendingRequests.remove(requestId);
      }
    } else {
      logger.w("Unhandled notification type: $type");
    }
  }

  // The following methods handle requests, they return int status code, -1 - failed request, 0 - successful request
  Future<(int, String?)> sendLoginRequest(username, password) async {
    logger.i("Creating login request");
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
      var response = await sendRequest(requestId, request);
      logger.i("Login request sent and response received.");
      if (response["type"] == "response") {
        if (response["status"] == "success") {
          logger.i("Login successful!");
          return (0, response["message"] as String);
        } else if (response["status"] == "fail") {
          logger.i("Login failed: ${response["message"]}");
          return (-1, response["message"] as String?);
        }
      }
      logger.w("Unexpected response format: $response");
      return (-1, null); // Fallback failure if the response type is unexpected
    } catch (error) {
      logger.w("Login failed $error");
      return (-1, "$error"); // Failure due to exception (e.g., network error)
    }
  }

  Future<(int, String?)> sendLogoutRequest(String userId) async {
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
          return (0, null);
        } else if (response["status"] == "fail") {
          logger.w("Logout failed");
          return (-1, "Logout failed");
        }
      }
      logger.w("Uexpected response format $response");
      return (-1, "Unexpected server response, try again");
    } catch (error) {
      logger.w("Logout failed: $error");
      return (-1, "Logout failed: $error");
    }
  }

  Future<(int, String?)> sendSignUpRequest(username, password, email) async { // Update to return the reason sign up failed (account exists, etc.)
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
          return (0, null);
        } else if (response["status"] == "fail") {
          logger.i("Sign up failed: ${response["message"]}");
          return (-1, response["message"] as String?);
        } 
      }
      logger.w("Unexpected response format: $response");
      return (-1, "Unexpected server response, try again"); // Fallback failure if the response type is unexpected
    } catch (error) {
      logger.w("Sign up failed: $error");
      return (-1, "Error");
    }
  }

  /// Guest account feature is put on hold, will implement it in the future once I have core functionalities working
  // Future<int> sendGuestLoginRequest(username) async {
  //   var requestId = uuid.v4();
  //   var request = {
  //     "action": "guest_login",
  //     "request_id": requestId,
  //     "data": {
  //       "username": username
  //     }
  //   };
  //   try {
  //     var response = await sendRequest(requestId, request);
  //     if (response["type"] == "response") {
  //       if (response["status"] == "success") {
  //         logger.i("Login successful!");
  //         return 0;
  //       } else if (response["status"] == "fail") {
  //         logger.i("Login failed: ${response["message"]}");
  //         return -1;
  //       }
  //     }
  //     logger.w("Unexpected response type");
  //     return -1;
  //   } catch (error) {
  //     logger.w("Error: $error");
  //     return -1;
  //   }
  // }

  Future<(int, String?)> sendDirectMessageRequest(senderId, recipientId, message) async {
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
          return (0, null);
        } else if (response["status"] == "fail") {
          logger.w("Message did not reach destinnation: ${response["message"]}");
          return (-1, "Message did not reach destination: ${response["message"]}");
        }
      }
      logger.w("Unexpected response format: $response");
      return (-1, "Received unexpected server response, try again");
    } catch (error) {
      logger.w("Error: $error");
      return (-1, "Error, $error");
    }
  }

  Future<(int, String?)> sendChatroomMessageRequest(senderId, roomId, message) async { // Need to know if successful?
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
          return (0, null);
        }
      } else if (response["status"] == "fail") {
        logger.w("Failed to deliver message: ${response["message"]}");
        return (-1, "Failed to deliver message");
      }
      logger.w("Unexpected response format: $response");
      return (-1, "Unexpected server response, please try again.");
    } catch (error) {
      logger.w("Error: $error");
      return (-1, "Error: $error");
    }
  }

  // Send request in non-blocking way from UI perspective, get and process server response
  Future<(int, String?)> sendJoinRoomRequest(roomId, userId) async {
    var requestId = uuid.v4();
    var request = {
      "action": "join_room",
      "request_id": requestId,
      "data": {
        "user_id": userId,
        "room_id": roomId,
      },
    };
    
    // return sendRequest(requestId, request).then((response) {
    try {
      var response = await sendRequest(requestId, request);
      if (response["type"] == "response" && response["status"] == "success") {
        logger.i("Successfully joined the room!");
        return (0, null);
      } else {
        logger.i("Failed to join the room: ${response["message"]}");
        return (-1, "Failed to join the room: ${response["message"]}");
      }
    } catch(error) {
      logger.w("Error joining room: $error");
      return (-1, "Error joining room: $error");
    }
  }

  Future<(int, String?)> sendGetMessagesRequest(roomId, limit) async {
    var requestId = uuid.v4();
    var request = {
      "action": "get_messages",
      "request_id": requestId,
      "data": {
        "room_id": roomId,
        "limit": limit,
      }
    };
    try {
      var response = await sendRequest(requestId, request);
      if (response["type"] == "response" && response["status"] == "success") {
        logger.i("Message delivered!");
        return (0, null);
      } else {
        logger.w("Message not delivered: ${response["message"]}");
        return (-1, "Message not deliverd ${response["message"]}");
      }
    } catch (error) {
      logger.w("Error sending message: $error");
      return (-1, "Error sending message: $error");
    }
  }

  Future<(int, String?)> sendLeaveRoomRequest(userId, roomId) async {
    var requestId = uuid.v4();
    var request = {
      "action": "leave_room",
      "request_id": requestId,
      "data": {
        "user_id": userId,
        "room_id": roomId,
      }
    };
    try {
      var response = await sendRequest(requestId, request);
      if (response["type"] == "response" && response["status"] == "success") {
        logger.i("Successfully left the room!");
        return (0, null);
      } else {
        logger.w("Failed to leave the room: ${response["message"]}");
        return (-1, "Failed to leave the room ${response["message"]}");
      }
    } catch (error) {
      logger.w("Error leaving room: $error");
      return (-1, "Error leaving rooom: $error");
    }
  }

  /// This is left here for reference purposes
  // Future<int> sendLeaveRoomRequest(userId, roomId) {
  //   var requestId = uuid.v4();
  //   var request = {
  //     "action": "leave_room",
  //     "request_id": requestId,
  //     "data": {
  //       "user_id": userId,
  //       "room_id": roomId,
  //     }
  //   };
  //   return sendRequest(requestId, request).then((response) {
  //     if (response["type"] == "response" && response["status"] == "success") {
  //       logger.i("Successfully left the room!");
  //       return 0;
  //     } else {
  //       logger.w("Failed to leave the room: ${response["message"]}");
  //       return -1;
  //     }
  //   }).catchError((error) {
  //     logger.w("Error leaving room: $error");
  //     return -1;
  //   });
  // }
}
