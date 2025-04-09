// Stores and manages message cache, metadata
import 'package:flutter/material.dart';

// Hold chat metadata
class ChatMetaData {
  final String id;
  final String title;
  DateTime lastActive;
  final int unreadCount;

  ChatMetaData(this.id, this.title, this.lastActive, this.unreadCount);
}

class ChatData extends ChangeNotifier {
  final List<Message> _messages;
  final List<String> participants;

  ChatData(this._messages, this.participants);

  List<Message> getMessages() => List.unmodifiable(_messages); // The returned list cannot be changed by receiver

  void addMessage(String senderId, String content, DateTime datetime) {
    Message msg = Message(senderId, content, datetime);
    _messages.add(msg);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}

class Message {
  final String senderId; // Id of the sender
  final String content; // The message text // could extend to more complex objects (gifs, pictures, etc.)
  final DateTime timestamp; // Time when the message was either sent or recieved

  Message(this.senderId, this.content, this.timestamp);
}
