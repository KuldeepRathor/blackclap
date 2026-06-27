import 'api_service.dart';

class InteractionApiService {
  final ApiService _api;
  InteractionApiService(ApiService api) : _api = api;

  Future<Map<String, dynamic>> toggleLike(String postId) =>
      _api.post('/posts/$postId/like', {});

  Future<Map<String, dynamic>> toggleSave(String postId) =>
      _api.post('/posts/$postId/save', {});

  Future<Map<String, dynamic>> getComments(
    String postId, {
    int limit = 20,
    String? afterCursor,
  }) {
    final params = 'limit=$limit${afterCursor != null ? '&after_cursor=${Uri.encodeComponent(afterCursor)}' : ''}';
    return _api.get('/posts/$postId/comments?$params');
  }

  Future<Map<String, dynamic>> getReplies(
    String postId,
    String commentId, {
    int limit = 10,
    String? afterCursor,
  }) {
    final params = 'limit=$limit${afterCursor != null ? '&after_cursor=${Uri.encodeComponent(afterCursor)}' : ''}';
    return _api.get('/posts/$postId/comments/$commentId/replies?$params');
  }

  Future<Map<String, dynamic>> addComment(String postId, String content,
          {String? parentId}) =>
      _api.post('/posts/$postId/comments', {
        'content': content,
        if (parentId != null) 'parent_id': parentId,
      });

  Future<void> deleteComment(String postId, String commentId) =>
      _api.delete('/posts/$postId/comments/$commentId');
}
