import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';


final logger = Logger();


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
enum ConnectionStatus { connected, disconnected, connecting, fail }

class PersistentWebSocketManager {
  final Uri endpoiont = Uri.parse("ws://localhost:8080/ws"); // Hardcoded server address

  final Duration reconnectDelay;
  final int reconnectLimit;
  int _reconnects = 0;
  bool _connecting = false;
  bool _connected = false;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  late StreamController<ConnectionStatus>? _statusController; // Stream of connection status messages
  late StreamController<String>? _messageController; // Stream of requests going to server?
  Stream<ConnectionStatus> get onStatusChange => _statusController!.stream;
  Stream<String> get onMessage => _messageController!.stream;
  bool get isConnected => _connected;

  PersistentWebSocketManager({ // This is a constructor class
    this.reconnectDelay = const Duration(seconds: 5), // Initialize field
    this.reconnectLimit = 10, // Initialize field
  }) {
    // initializeControllers();
    _statusController = StreamController<ConnectionStatus>.broadcast();
    _messageController = StreamController<String>.broadcast();
  }
  
  void initializeControllers() {
    // if (_messageController == null || _messageController!.isClosed) { // Don't tauch it for now
    //   _messageController = StreamController<String>.broadcast();
    // }
    if (_statusController == null || _statusController!.isClosed) {
      _statusController = StreamController<ConnectionStatus>.broadcast();
    }
  }


  Future<void> connect() async { // Try to connect to server
    _cleanupSocket();
    initializeControllers();
    // if (_statusController!.isClosed || _messageController!.isClosed) {
    //   initializeControllers();
    // }
    logger.i("Attempting connection");
    if (_connecting || _connected) return; // Problem, on logout the status has not been updated
    _connecting = true;
    if (_reconnects >= reconnectLimit) { // First test whether we reached the limit of reconnects
      logger.i("Reconnect limit reached");
      _connecting = false;
      _connected = false;
      _statusController!.add(ConnectionStatus.fail); // failed to connect after reconnect limit reached.
      return;
    }
    try { // If reconnects limits has not been reached, try to connect to server via WebSocket
      _statusController!.add(ConnectionStatus.connecting); // Add connecting event to stream
      _channel = WebSocketChannel.connect(endpoiont);
      logger.i("Connection made $_channel");
      _subscription = _channel!.stream.listen(
        (event) => _messageController!.add(event),
        onDone: _handleDisconnect, // If done this indicates a closed socket connection, in this case we can call a disconnect handler function
        onError: (_) => _handleError(),
        cancelOnError: true, // Cancel read if we receive error
      );
      _connected = true;
      _statusController!.add(ConnectionStatus.connected);
      logger.i("Supposedly connected and emitted the connected signal");
      return;
    } catch (e) {
      logger.e("Exception occured while trying to connect to server: $e");
      _connected = false;
      _statusController!.add(ConnectionStatus.fail);
      return;
    } finally {
      // _reconnects += 1;
      logger.i("Reset _connecting");
      _connecting = false;
    }
  }

  // This supposed to handle the case when the connection failed, the server not responding
  // Possible to trigger reconnects, but for now just finish and dispose of the connection.
  void _handleError() {
    _statusController!.add(ConnectionStatus.fail);
    _connected = false;
    _connecting = false;
    _reconnects = 0;
    // _messageController.close(); // Get rid of the messageController, initiate one when a connect is attempted?
    _cleanupSocket();
    return;
  }

  void _handleDisconnect() async {
    _cleanupSocket();
    // If this method is called, it means the first reconnect should be schaduled and the reconnects count is reset
    _statusController!.add(ConnectionStatus.disconnected);
    _subscription?.cancel(); // Cancel previous subscription so that it does not hang
    _channel?.sink.close(); // close previous channel to free up the resources
    _reconnects = 0; // First reconnect, reset the counter
    _connected = false;
    _connecting = false;
    while (!_connected && _reconnects < reconnectLimit) {
      // _statusController.add(ConnectionStatus.disconnected);
      // Future.delayed(reconnectDelay, connect); // Delay reconnection
      await connect();
      if (_connected) break;
      await Future.delayed(reconnectDelay);
      _reconnects ++;
    }
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
  }

  void disconnect() {
    logger.i("Client disconnected.");
    // _subscription?.cancel();
    // _channel?.sink.close();
    _cleanupSocket();
    _statusController!.add(ConnectionStatus.disconnected);
    _connecting = false;
    _connected = false;
  }

  void dispose() {
    disconnect();
    _statusController!.close();
    // _messageController!.close(); // The problem is we are closing
    _statusController = null;
    // _messageController = null; // Keep it persistent for now, handle edge cases later.
  }
}

class ServerConnController {
  final PersistentWebSocketManager? _ws;
  Map<String, Completer> pendingRequests = {};

  final uuid = Uuid(); // Unique Id generator
  // WebSocketChannel? get channel => _channel;

  ServerConnController(this._ws) {
    _ws?.onMessage.listen(_handleMessage); // Add _handleMessae as a listener on broadcast message stream piped to a WebSocket connection to server
  }

  void _handleMessage(String response) {
    final decoded = jsonDecode(response);
    final requestId = decoded['request_id'];
    if (pendingRequests.containsKey(requestId)) {
      pendingRequests[requestId]!.complete(decoded);
      pendingRequests.remove(requestId);
    } else {
      handleNotification(decoded);
    }
  }

  Future<Map<String, dynamic>> sendRequest(String requestId, Map<String, dynamic> request) {
    Completer<Map<String, dynamic>> completer = Completer();
    pendingRequests[requestId] = completer;
    _ws?.send(jsonEncode(request));
    return completer.future;
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
          return (-1, null);
        }
      }
      logger.w("Unexpected response format: $response");
      return (-1, null); // Fallback failure if the response type is unexpected
    } catch (error) {
      logger.w("Login failed $error");
      return (-1, null); // Failure due to exception (e.g., network error)
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

  Future<int> sendSignUpRequest(username, password, email) async { // Update to return the reason sign up failed (account exists, etc.)
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
