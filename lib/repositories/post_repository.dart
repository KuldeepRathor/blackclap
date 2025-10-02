import '../models/post_model.dart';
import 'mock_data_service.dart';

abstract class PostRepositoryInterface {
  Future<List<PostModel>> getPosts();
  Future<List<PostModel>> getUserPosts(String uid);
  Future<PostModel?> getPost(String postId);
  Future<void> likePost(String postId, String userId);
  Future<void> unlikePost(String postId, String userId);
  Future<void> createPost({
    required String uid,
    required String caption,
    required List<String> imageUrls,
  });
}

class PostRepository implements PostRepositoryInterface {

  @override
  Future<List<PostModel>> getPosts() async {
    final postData = MockDataService.getPosts();
    return postData.map((post) => PostModel.fromMap(post)).toList();
  }

  @override
  Future<List<PostModel>> getUserPosts(String uid) async {
    final postData = MockDataService.getUserPosts(uid);
    return postData.map((post) => PostModel.fromMap(post)).toList();
  }

  @override
  Future<PostModel?> getPost(String postId) async {
    final postData = MockDataService.getPost(postId);
    return postData != null ? PostModel.fromMap(postData) : null;
  }

  @override
  Future<void> likePost(String postId, String userId) async {
    await MockDataService.likePost(postId, userId);
  }

  @override
  Future<void> unlikePost(String postId, String userId) async {
    await MockDataService.unlikePost(postId, userId);
  }

  @override
  Future<void> createPost({
    required String uid,
    required String caption,
    required List<String> imageUrls,
  }) async {
    await MockDataService.createPost(
      uid: uid,
      caption: caption,
      imageUrls: imageUrls,
    );
  }
}