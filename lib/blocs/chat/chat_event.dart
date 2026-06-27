part of 'chat_bloc.dart';

/// Base class for ChatBloc events. Named `ChatBlocEvent` to avoid colliding
/// with the socket-domain `ChatEvent` imported from chat_socket_event.dart.
abstract class ChatBlocEvent extends Equatable {
  const ChatBlocEvent();

  @override
  List<Object?> get props => [];
}

class ChatHistoryLoadRequested extends ChatBlocEvent {
  const ChatHistoryLoadRequested();
}

class ChatOlderMessagesRequested extends ChatBlocEvent {
  const ChatOlderMessagesRequested();
}

class ChatMessageSent extends ChatBlocEvent {
  final String text;
  const ChatMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

class ChatMessageRetryRequested extends ChatBlocEvent {
  final String clientId;
  const ChatMessageRetryRequested(this.clientId);

  @override
  List<Object?> get props => [clientId];
}

class ChatMarkReadRequested extends ChatBlocEvent {
  const ChatMarkReadRequested();
}

class ChatTypingChanged extends ChatBlocEvent {
  final bool isTyping;
  const ChatTypingChanged(this.isTyping);

  @override
  List<Object?> get props => [isTyping];
}

/// Internal: a live socket event was received (forwarded into the bloc).
class ChatSocketEventReceived extends ChatBlocEvent {
  final ChatEvent event;
  const ChatSocketEventReceived(this.event);

  @override
  List<Object?> get props => [event];
}
