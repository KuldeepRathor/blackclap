import 'package:equatable/equatable.dart';

import 'message_model.dart';

/// Inbound WebSocket event, parsed from `{ "type": "...", "data": {...} }`.
/// The `type` strings mirror app/core/websocket/events.py on the backend.
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];

  factory ChatEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};

    switch (type) {
      case 'message.new':
        final msg = data['message'];
        if (msg is Map<String, dynamic>) {
          return NewMessageEvent(MessageModel.fromApiResponse(msg));
        }
        return const UnknownEvent('message.new');
      case 'message.read':
        return ReadReceiptEvent(
          conversationId: data['conversation_id']?.toString() ?? '',
          readerId: data['reader_id']?.toString() ?? '',
          lastReadMessageId: data['last_read_message_id']?.toString(),
          readAt: DateTime.tryParse(data['read_at']?.toString() ?? ''),
        );
      case 'typing':
        return TypingEvent(
          conversationId: data['conversation_id']?.toString() ?? '',
          userId: data['user_id']?.toString() ?? '',
          isTyping: data['is_typing'] == true,
        );
      case 'presence':
        return PresenceEvent(
          userId: data['user_id']?.toString() ?? '',
          online: data['online'] == true,
          lastSeen: DateTime.tryParse(data['last_seen']?.toString() ?? ''),
        );
      case 'pong':
        return const PongEvent();
      default:
        return UnknownEvent(type);
    }
  }
}

class NewMessageEvent extends ChatEvent {
  final MessageModel message;
  const NewMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class ReadReceiptEvent extends ChatEvent {
  final String conversationId;
  final String readerId;
  final String? lastReadMessageId;
  final DateTime? readAt;

  const ReadReceiptEvent({
    required this.conversationId,
    required this.readerId,
    this.lastReadMessageId,
    this.readAt,
  });

  @override
  List<Object?> get props => [conversationId, readerId, lastReadMessageId, readAt];
}

class TypingEvent extends ChatEvent {
  final String conversationId;
  final String userId;
  final bool isTyping;

  const TypingEvent({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [conversationId, userId, isTyping];
}

class PresenceEvent extends ChatEvent {
  final String userId;
  final bool online;
  final DateTime? lastSeen;

  const PresenceEvent({
    required this.userId,
    required this.online,
    this.lastSeen,
  });

  @override
  List<Object?> get props => [userId, online, lastSeen];
}

class PongEvent extends ChatEvent {
  const PongEvent();
}

class UnknownEvent extends ChatEvent {
  final String rawType;
  const UnknownEvent(this.rawType);

  @override
  List<Object?> get props => [rawType];
}
