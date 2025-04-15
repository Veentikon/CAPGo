// Stores and manages message cache, metadata
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';


/// This allows the ChatMetaData class to access private members in the generated file
/// The value for this is *.g.dart, where the start denotes the source file name
part 'chat_data.g.dart';

// Hold chat metadata
@JsonSerializable()
class ChatMetaData {
  final String id;
  final String title;
  DateTime lastActive;
  final int unreadCount;

  ChatMetaData(this.id, this.title, this.lastActive, this.unreadCount);

  /// A necessary factory constructor for creating a new ChatMetaData instance from a map.
  /// Pass the map to the generated '_$ChatMetaDataFromJson' constructor.
  /// The constructor is named after the source class
  factory ChatMetaData.fromJson(Map<String, dynamic> json) => _$ChatMetaDataFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$ChatMetaDataToJson`.
  Map<String, dynamic> toJson() => _$ChatMetaDataToJson(this);
}

@JsonSerializable()
class ChatData extends ChangeNotifier {
  final String id;
  final List<Message> messages;
  final List<String> participants;

  ChatData(this.id, this.messages, this.participants);

  factory ChatData.fromJson(Map<String, dynamic> json) => _$ChatDataFromJson(json);
  Map<String, dynamic> toJson() => _$ChatDataToJson(this);

  List<Message> getMessages() => List.unmodifiable(messages); // The returned list cannot be changed by receiver

  void addMessage(String senderId, String content, DateTime datetime) {
    Message msg = Message(senderId, content, datetime);
    messages.add(msg);
    notifyListeners();
  }

  void clearMessages() {
    messages.clear();
    notifyListeners();
  }
}

@JsonSerializable()
class Message {
  final String senderId; // Id of the sender
  final String content; // The message text // could extend to more complex objects (gifs, pictures, etc.)
  final DateTime timestamp; // Time when the message was either sent or recieved

  Message(this.senderId, this.content, this.timestamp);
  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}


// Need to define the folder structure and files on where to store the data
// Create folder Data, for each user create subfolder naming it with user ID
// In that folder create files for each type of data stored


// Run serialization code building command: dart run build_runner build --delete-conflicting-outputs
// or: dart run build_runner watch --delete-conflicting-outputs


/// For now I can leave ChatData alone, not converting it to Json for storage.
/// Simply on Chat data load, load ChatMetaData and create the corresponding objects.
/// This should work since the most important part of information from Chats is chat id
/// and the messages can be read from the server
/// 
/// Another point to consider is what to do with cached data if the user changes?
/// Store cached data linked to user Id, if the user Id changes, clean cache and
/// start recording chat data specific to the new user
/// Another approach is to keep track of all chat data cache, record this data for each user.
/// We do not want to make chatData from one user be accessible to another user.
/// Encrypt the data with user's password acting as a key. When user logs in and is successful
/// the relevant data for the user is decrypted and read/deserialized.
/// this approach requires generation of encryption keys and IV
/// 
/// How to make all communication encrypted, server only processes encrypted user messages.
/// messages are received, saved and sent in encrypted format and only users belonging to a
/// chatroom are able to read those messages.
/// 
/// These are all security features that can be implemented at a later time, for now, proof
/// of concept or MVP is good enough.