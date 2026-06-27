part of 'conversations_bloc.dart';

abstract class ConversationsBlocEvent extends Equatable {
  const ConversationsBlocEvent();

  @override
  List<Object?> get props => [];
}

class ConversationsLoadRequested extends ConversationsBlocEvent {
  const ConversationsLoadRequested();
}

class ConversationsRefreshRequested extends ConversationsBlocEvent {
  const ConversationsRefreshRequested();
}

class ConversationsMoreRequested extends ConversationsBlocEvent {
  const ConversationsMoreRequested();
}

class ConversationsSocketEventReceived extends ConversationsBlocEvent {
  final ChatEvent event;
  const ConversationsSocketEventReceived(this.event);

  @override
  List<Object?> get props => [event];
}
