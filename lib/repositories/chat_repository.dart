import '../models/chat_socket_event.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/chat_api_service.dart';
import '../services/chat_socket_service.dart';

/// Single dependency for the chat BLoCs. Owns one REST service and one socket,
/// and is the only place that knows both transports exist.
class ChatRepository {
  final ChatApiService _api;
  final ChatSocketService _socket;

  ChatRepository({ChatApiService? api, ChatSocketService? socket})
      : _api = api ?? ChatApiService(ApiService()),
        _socket = socket ?? ChatSocketService();

  // --- Socket lifecycle / streams ---

  Stream<ChatEvent> get events => _socket.events;
  Stream<SocketStatus> get connectionStatus => _socket.status;
  SocketStatus get currentStatus => _socket.currentStatus;

  Future<void> connectSocket() => _socket.connect();
  Future<void> disconnectSocket() => _socket.disconnect();

  void sendTyping(String conversationId, bool isTyping) =>
      _socket.sendTyping(conversationId, isTyping);
  void sendReadReceiptWs(String conversationId, String messageId) =>
      _socket.sendReadReceipt(conversationId, messageId);

  // --- REST ---

  Future<ConversationModel> openOrCreateDm(String otherUserId) async {
    final data = await _api.createConversation(otherUserId);
    return ConversationModel.fromApiResponse(data);
  }

  Future<({List<ConversationModel> conversations, String? nextCursor})>
      getConversations({String? cursor}) async {
    final data = await _api.getConversations(cursor: cursor);
    final raw = (data['conversations'] as List?) ?? const [];
    final conversations = raw
        .whereType<Map<String, dynamic>>()
        .map(ConversationModel.fromApiResponse)
        .toList();
    return (conversations: conversations, nextCursor: data['next_cursor']?.toString());
  }

  Future<({List<MessageModel> messages, String? nextCursor})> getMessages(
    String conversationId, {
    String? cursor,
  }) async {
    final data = await _api.getMessages(conversationId, cursor: cursor);
    final raw = (data['messages'] as List?) ?? const [];
    final messages = raw
        .whereType<Map<String, dynamic>>()
        .map(MessageModel.fromApiResponse)
        .toList();
    return (messages: messages, nextCursor: data['next_cursor']?.toString());
  }

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String clientMessageId,
    required String content,
  }) async {
    final data = await _api.sendMessage(
      conversationId: conversationId,
      clientMessageId: clientMessageId,
      content: content,
    );
    return MessageModel.fromApiResponse(data);
  }

  Future<void> markRead(String conversationId, String lastReadMessageId) =>
      _api.markRead(conversationId, lastReadMessageId);

  Future<int> unreadTotal() async {
    final data = await _api.unreadCount();
    return (data['total_unread'] as num?)?.toInt() ?? 0;
  }

  void dispose() => _socket.dispose();
}
