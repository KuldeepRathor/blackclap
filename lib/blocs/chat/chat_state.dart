part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Single rich loaded state. `messages` is ascending by createdAt (oldest
/// first); the thread renders it in a reverse ListView so newest sits at the
/// bottom and scroll-up loads older.
class ChatLoaded extends ChatState {
  final List<MessageModel> messages;
  final String? olderCursor;
  final bool isLoadingOlder;
  final bool hasMoreOlder;
  final bool otherTyping;
  final SocketStatus connectionStatus;

  const ChatLoaded({
    required this.messages,
    this.olderCursor,
    this.isLoadingOlder = false,
    this.hasMoreOlder = false,
    this.otherTyping = false,
    this.connectionStatus = SocketStatus.disconnected,
  });

  ChatLoaded copyWith({
    List<MessageModel>? messages,
    String? olderCursor,
    bool clearOlderCursor = false,
    bool? isLoadingOlder,
    bool? hasMoreOlder,
    bool? otherTyping,
    SocketStatus? connectionStatus,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      olderCursor: clearOlderCursor ? null : (olderCursor ?? this.olderCursor),
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      otherTyping: otherTyping ?? this.otherTyping,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        olderCursor,
        isLoadingOlder,
        hasMoreOlder,
        otherTyping,
        connectionStatus,
      ];
}
