import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/chat_socket_event.dart';
import '../../models/conversation_model.dart';
import '../../repositories/chat_repository.dart';

part 'conversations_event.dart';
part 'conversations_state.dart';

/// App-level BLoC for the conversation list. Lives as long as the
/// MessagesScreen is in the persistent nav (stateManagement: true), which means
/// it keeps receiving socket events and updating unread counts even when the
/// user is on a different tab.
class ConversationsBloc
    extends Bloc<ConversationsBlocEvent, ConversationsState> {
  final ChatRepository _repository;
  final String _currentUserId;

  StreamSubscription<ChatEvent>? _eventSub;

  ConversationsBloc({
    required ChatRepository repository,
    required String currentUserId,
  })  : _repository = repository,
        _currentUserId = currentUserId,
        super(const ConversationsInitial()) {
    on<ConversationsLoadRequested>(_onLoad);
    on<ConversationsRefreshRequested>(_onRefresh);
    on<ConversationsMoreRequested>(_onMore);
    on<ConversationsSocketEventReceived>(_onSocketEvent);

    _eventSub = _repository.events.listen(
      (event) => add(ConversationsSocketEventReceived(event)),
    );
  }

  @override
  Future<void> close() {
    _eventSub?.cancel();
    return super.close();
  }

  Future<void> _onLoad(
    ConversationsLoadRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    if (state is ConversationsLoaded) return; // already loaded — use refresh
    emit(const ConversationsLoading());
    try {
      final result = await _repository.getConversations();
      emit(ConversationsLoaded(
        conversations: result.conversations,
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
      ));
    } catch (e) {
      emit(ConversationsError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRefresh(
    ConversationsRefreshRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      final result = await _repository.getConversations();
      emit(ConversationsLoaded(
        conversations: result.conversations,
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
      ));
    } catch (_) {
      // Keep existing state on pull-to-refresh failure.
    }
  }

  Future<void> _onMore(
    ConversationsMoreRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    final s = state;
    if (s is! ConversationsLoaded ||
        s.isLoadingMore ||
        !s.hasMore ||
        s.nextCursor == null) {
      return;
    }
    emit(s.copyWith(isLoadingMore: true));
    try {
      final result =
          await _repository.getConversations(cursor: s.nextCursor);
      emit(s.copyWith(
        conversations: [...s.conversations, ...result.conversations],
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(s.copyWith(isLoadingMore: false));
    }
  }

  void _onSocketEvent(
    ConversationsSocketEventReceived event,
    Emitter<ConversationsState> emit,
  ) {
    final s = state;
    if (s is! ConversationsLoaded) return;

    final domain = event.event;

    if (domain is NewMessageEvent) {
      final msg = domain.message;
      final list = [...s.conversations];
      final idx = list.indexWhere((c) => c.id == msg.conversationId);

      if (idx < 0) { return; } // unknown conversation — refresh will pick it up

      final existing = list[idx];
      final isMine = msg.senderId == _currentUserId;
      final updated = existing.copyWith(
        lastMessage: msg,
        lastMessagePreview: msg.text.isNotEmpty ? msg.text : null,
        unreadCount: isMine ? existing.unreadCount : existing.unreadCount + 1,
        updatedAt: msg.createdAt,
      );
      list
        ..removeAt(idx)
        ..insert(0, updated);
      emit(s.copyWith(conversations: list));
    } else if (domain is ReadReceiptEvent) {
      // My own read receipt (sent from this device or another) — zero unread.
      if (domain.readerId != _currentUserId) return;
      final list = s.conversations.map((c) {
        if (c.id == domain.conversationId) return c.copyWith(unreadCount: 0);
        return c;
      }).toList();
      emit(s.copyWith(conversations: list));
    }
  }
}
