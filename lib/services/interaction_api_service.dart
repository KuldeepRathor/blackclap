import 'api_service.dart';

class InteractionApiService {
  final ApiService _api;
  InteractionApiService(ApiService api) : _api = api;

  Future<Map<String, dynamic>> toggleLike(String postId) =>
      _api.post('/posts/$postId/like', {});

  Future<Map<String, dynamic>> toggleSave(String postId) =>
      _api.post('/posts/$postId/save', {});

  Future<Map<String, dynamic>> getComments(String postId,
          {int limit = 20, int offset = 0}) =>
      _api.get('/posts/$postId/comments?limit=$limit&offset=$offset');

  Future<Map<String, dynamic>> addComment(String postId, String content,
          {String? parentId}) =>
      _api.post('/posts/$postId/comments', {
        'content': content,
        if (parentId != null) 'parent_id': parentId,
      });

  Future<void> deleteComment(String postId, String commentId) =>
      _api.delete('/posts/$postId/comments/$commentId');
}
