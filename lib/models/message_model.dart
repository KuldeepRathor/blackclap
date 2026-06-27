import 'package:equatable/equatable.dart';

/// Delivery lifecycle of a message. `sending`/`failed` are client-only states
/// (the wire never carries them); the rest are derived from the server.
enum MessageStatus { sending, sent, delivered, read, failed }

enum MessageType { text, image, video, system }

class MessageModel extends Equatable {
  /// Server id. Empty string until the optimistic message is acknowledged.
  final String id;

  /// Locally-generated UUID, stable across the optimistic -> ack transition.
  /// Round-trips through the server (as `client_message_id`) so we can match a
  /// pending bubble to its persisted row and de-dupe our own WS echo.
  final String clientId;

  final String conversationId;
  final String senderId;
  final MessageType type;
  final String text;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? readAt;

  const MessageModel({
    required this.id,
    required this.clientId,
    required this.conversationId,
    required this.senderId,
    this.type = MessageType.text,
    this.text = '',
    this.mediaUrl,
    this.thumbnailUrl,
    this.status = MessageStatus.sent,
    required this.createdAt,
    this.readAt,
  });

  bool isMine(String currentUserId) => senderId == currentUserId;

  static MessageType _parseType(dynamic value) {
    switch (value?.toString()) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  /// Parse a backend MessageResponse (snake_case).
  factory MessageModel.fromApiResponse(Map<String, dynamic> map) {
    final readAtRaw = map['read_at'];
    final readAt = readAtRaw is String ? DateTime.tryParse(readAtRaw) : null;
    return MessageModel(
      id: map['id']?.toString() ?? '',
      clientId: map['client_message_id']?.toString() ??
          map['id']?.toString() ??
          '',
      conversationId: map['conversation_id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      type: _parseType(map['type']),
      text: map['content']?.toString() ?? map['text']?.toString() ?? '',
      mediaUrl: map['media_url']?.toString(),
      thumbnailUrl: map['thumbnail_url']?.toString(),
      status: readAt != null ? MessageStatus.read : MessageStatus.sent,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      readAt: readAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_message_id': clientId,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'type': type.name,
      'content': text,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? clientId,
    String? conversationId,
    String? senderId,
    MessageType? type,
    String? text,
    String? mediaUrl,
    String? thumbnailUrl,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        conversationId,
        senderId,
        type,
        text,
        mediaUrl,
        thumbnailUrl,
        status,
        createdAt,
        readAt,
      ];
}
