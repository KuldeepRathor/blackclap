import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/chat_socket_event.dart';
import '../../models/message_model.dart';
import '../../repositories/chat_repository.dart';
import '../../services/chat_socket_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// Drives a single conversation thread: load + paginate history, send
/// optimistically and reconcile the server ack, merge live messages, read
/// receipts, and typing. One instance per open thread (disposed on pop).
class ChatBloc extends Bloc<ChatBlocEvent, ChatState> {
  final ChatRepository _repository;
  final String conversationId;
  final String currentUserId;

  StreamSubscription<ChatEvent>? _eventSub;

  // Discards stale history pages if the user opens/closes quickly.
  int _historyRequestId = 0;

  ChatBloc({
    required ChatRepository repository,
    required this.conversationId,
    required this.currentUserId,
  })  : _repository = repository,
        super(const ChatInitial()) {
    on<ChatHistoryLoadRequested>(_onHistoryLoad);
    on<ChatOlderMessagesRequested>(_onOlderMessages);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMessageRetryRequested>(_onMessageRetry);
    on<ChatMarkReadRequested>(_onMarkRead);
    on<ChatTypingChanged>(_onTypingChanged);
    on<ChatSocketEventReceived>(_onSocketEvent);

    _eventSub = _repository.events.listen(
      (event) => add(ChatSocketEventReceived(event)),
    );
  }

  @override
  Future<void> close() {
    _eventSub?.cancel();
    return super.close();
  }

  // --- Helpers ---

  /// Merge an incoming message into an ascending-by-time list, replacing any
  /// existing entry with the same clientId or server id (de-dup), then re-sort.
  List<MessageModel> _merge(List<MessageModel> current, MessageModel incoming) {
    final list = [...current];
    final idx = list.indexWhere((m) =>
        (incoming.clientId.isNotEmpty && m.clientId == incoming.clientId) ||
        (incoming.id.isNotEmpty && m.id == incoming.id));
    if (idx >= 0) {
      list[idx] = incoming;
    } else {
      list.add(incoming);
    }
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  String _uuidV4() {
    final r = Random();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).toList();
    return '${h[0]}${h[1]}${h[2]}${h[3]}-${h[4]}${h[5]}-${h[6]}${h[7]}'
        '-${h[8]}${h[9]}-${h[10]}${h[11]}${h[12]}${h[13]}${h[14]}${h[15]}';
  }

  // --- Handlers ---

  Future<void> _onHistoryLoad(
    ChatHistoryLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    final reqId = ++_historyRequestId;
    emit(const ChatLoading());
    try {
      final result = await _repository.getMessages(conversationId);
      if (reqId != _historyRequestId) return;
      // API returns newest-first; store ascending (oldest -> newest).
      final messages = result.messages.reversed.toList();
      emit(ChatLoaded(
        messages: messages,
        olderCursor: result.nextCursor,
        hasMoreOlder: result.nextCursor != null,
        connectionStatus: _repository.currentStatus,
      ));
      add(const ChatMarkReadRequested());
    } catch (e) {
      if (reqId != _historyRequestId) return;
      emit(ChatError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onOlderMessages(
    ChatOlderMessagesRequested event,
    Emitter<ChatState> emit,
  ) async {
    final s = state;
    if (s is! ChatLoaded ||
        s.isLoadingOlder ||
        !s.hasMoreOlder ||
        s.olderCursor == null) {
      return;
    }
    emit(s.copyWith(isLoadingOlder: true));
    try {
      final result =
          await _repository.getMessages(conversationId, cursor: s.olderCursor);
      final older = result.messages.reversed.toList(); // ascending
      final merged = [...older, ...s.messages]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      emit(s.copyWith(
        messages: merged,
        olderCursor: result.nextCursor,
        clearOlderCursor: result.nextCursor == null,
        hasMoreOlder: result.nextCursor != null,
        isLoadingOlder: false,
      ));
    } catch (_) {
      emit(s.copyWith(isLoadingOlder: false));
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final s = state;
    if (s is! ChatLoaded) return;
    final text = event.text.trim();
    if (text.isEmpty) return;

    final clientId = _uuidV4();
    final optimistic = MessageModel(
      id: '',
      clientId: clientId,
      conversationId: conversationId,
      senderId: currentUserId,
      type: MessageType.text,
      text: text,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );
    emit(s.copyWith(messages: _merge(s.messages, optimistic)));
    await _deliver(clientId, text, emit);
  }

  Future<void> _onMessageRetry(
    ChatMessageRetryRequested event,
    Emitter<ChatState> emit,
  ) async {
    final s = state;
    if (s is! ChatLoaded) return;
    final idx = s.messages.indexWhere((m) => m.clientId == event.clientId);
    if (idx < 0) return;
    final msg = s.messages[idx];
    final retried = msg.copyWith(status: MessageStatus.sending);
    emit(s.copyWith(messages: _merge(s.messages, retried)));
    await _deliver(event.clientId, msg.text, emit);
  }

  Future<void> _deliver(
    String clientId,
    String text,
    Emitter<ChatState> emit,
  ) async {
    try {
      final saved = await _repository.sendMessage(
        conversationId: conversationId,
        clientMessageId: clientId,
        content: text,
      );
      final s = state;
      if (s is! ChatLoaded) return;
      emit(s.copyWith(
        messages: _merge(s.messages, saved.copyWith(status: MessageStatus.sent)),
      ));
    } catch (_) {
      final s = state;
      if (s is! ChatLoaded) return;
      final idx = s.messages.indexWhere((m) => m.clientId == clientId);
      if (idx < 0) return;
      final failed = s.messages[idx].copyWith(status: MessageStatus.failed);
      final list = [...s.messages]..[idx] = failed;
      emit(s.copyWith(messages: list));
    }
  }

  Future<void> _onMarkRead(
    ChatMarkReadRequested event,
    Emitter<ChatState> emit,
  ) async {
    final s = state;
    if (s is! ChatLoaded) return;
    // Newest message that has a server id (skip pending optimistic ones).
    String? targetId;
    for (final m in s.messages.reversed) {
      if (m.id.isNotEmpty) {
        targetId = m.id;
        break;
      }
    }
    if (targetId == null) return;
    try {
      await _repository.markRead(conversationId, targetId);
    } catch (_) {
      // Best-effort.
    }
  }

  void _onTypingChanged(
    ChatTypingChanged event,
    Emitter<ChatState> emit,
  ) {
    _repository.sendTyping(conversationId, event.isTyping);
  }

  void _onSocketEvent(
    ChatSocketEventReceived event,
    Emitter<ChatState> emit,
  ) {
    final domain = event.event;
    final s = state;

    if (domain is NewMessageEvent) {
      if (domain.message.conversationId != conversationId) return;
      if (s is! ChatLoaded) return;
      emit(s.copyWith(messages: _merge(s.messages, domain.message)));
      if (!domain.message.isMine(currentUserId)) {
        add(const ChatMarkReadRequested());
      }
    } else if (domain is ReadReceiptEvent) {
      if (domain.conversationId != conversationId) return;
      if (domain.readerId == currentUserId) return; // my own read
      if (s is! ChatLoaded) return;
      final readAt = domain.readAt ?? DateTime.now();
      final list = s.messages.map((m) {
        if (m.isMine(currentUserId) &&
            m.status != MessageStatus.read &&
            !m.createdAt.isAfter(readAt)) {
          return m.copyWith(status: MessageStatus.read, readAt: readAt);
        }
        return m;
      }).toList();
      emit(s.copyWith(messages: list));
    } else if (domain is TypingEvent) {
      if (domain.conversationId != conversationId) return;
      if (domain.userId == currentUserId) return;
      if (s is! ChatLoaded) return;
      emit(s.copyWith(otherTyping: domain.isTyping));
    }
  }
}
