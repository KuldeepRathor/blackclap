part of 'conversations_bloc.dart';

abstract class ConversationsState extends Equatable {
  const ConversationsState();

  @override
  List<Object?> get props => [];
}

class ConversationsInitial extends ConversationsState {
  const ConversationsInitial();
}

class ConversationsLoading extends ConversationsState {
  const ConversationsLoading();
}

class ConversationsError extends ConversationsState {
  final String message;
  const ConversationsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ConversationsLoaded extends ConversationsState {
  final List<ConversationModel> conversations;
  final String? nextCursor;
  final bool isLoadingMore;
  final bool hasMore;

  const ConversationsLoaded({
    required this.conversations,
    this.nextCursor,
    this.isLoadingMore = false,
    this.hasMore = false,
  });

  int get totalUnread =>
      conversations.fold(0, (sum, c) => sum + c.unreadCount);

  ConversationsLoaded copyWith({
    List<ConversationModel>? conversations,
    String? nextCursor,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return ConversationsLoaded(
      conversations: conversations ?? this.conversations,
      nextCursor: nextCursor ?? this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props =>
      [conversations, nextCursor, isLoadingMore, hasMore];
}
