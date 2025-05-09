// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMetaData _$ChatMetaDataFromJson(Map<String, dynamic> json) => ChatMetaData(
      json['id'] as String,
      json['title'] as String,
      DateTime.parse(json['lastActive'] as String),
      (json['unreadCount'] as num).toInt(),
    );

Map<String, dynamic> _$ChatMetaDataToJson(ChatMetaData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'lastActive': instance.lastActive.toIso8601String(),
      'unreadCount': instance.unreadCount,
    };

ChatData _$ChatDataFromJson(Map<String, dynamic> json) => ChatData(
      json['id'] as String,
      (json['messages'] as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['participants'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ChatDataToJson(ChatData instance) => <String, dynamic>{
      'id': instance.id,
      'messages': instance.messages,
      'participants': instance.participants,
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      json['senderId'] as String,
      json['content'] as String,
      DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'senderId': instance.senderId,
      'content': instance.content,
      'timestamp': instance.timestamp.toIso8601String(),
    };
