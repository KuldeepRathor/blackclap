import 'api_service.dart';

/// REST surface for chat, wrapping the shared ApiService (same pattern as
/// PostApiService / SearchApiService). Returns raw maps; the repository maps
/// them to models.
class ChatApiService {
  final ApiService _api;

  ChatApiService(this._api);

  /// Get-or-create a 1:1 DM with another user. Idempotent on the backend.
  Future<Map<String, dynamic>> createConversation(String participantId) async {
    return await _api.post('/chat/conversations', {
      'participant_id': participantId,
    });
  }

  /// Conversation list, newest activity first, cursor-paginated.
  Future<Map<String, dynamic>> getConversations({
    int limit = 30,
    String? cursor,
  }) async {
    final query = StringBuffer('?limit=$limit');
    if (cursor != null) query.write('&after_cursor=$cursor');
    return await _api.get('/chat/conversations$query');
  }

  /// Message history (newest first), cursor-paginated.
  Future<Map<String, dynamic>> getMessages(
    String conversationId, {
    int limit = 30,
    String? cursor,
  }) async {
    final query = StringBuffer('?limit=$limit');
    if (cursor != null) query.write('&after_cursor=$cursor');
    return await _api.get('/chat/conversations/$conversationId/messages$query');
  }

  /// Send a message. `clientMessageId` makes the send idempotent + lets the
  /// client reconcile its optimistic bubble with the persisted row.
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String clientMessageId,
    required String content,
    String type = 'text',
    String? mediaUrl,
  }) async {
    return await _api.post('/chat/conversations/$conversationId/messages', {
      'content': content,
      'client_message_id': clientMessageId,
      'type': type,
      if (mediaUrl != null) 'media_url': mediaUrl,
    });
  }

  /// Mark a conversation read up to a message.
  Future<void> markRead(String conversationId, String lastReadMessageId) async {
    await _api.post('/chat/conversations/$conversationId/read', {
      'last_read_message_id': lastReadMessageId,
    });
  }

  /// Total unread across all conversations (app badge).
  Future<Map<String, dynamic>> unreadCount() async {
    return await _api.get('/chat/unread-count');
  }
}
