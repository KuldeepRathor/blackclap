import 'dart:io';

import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/post_api_service.dart';
import 'mock_data_service.dart';

abstract class PostRepositoryInterface {
  Future<List<PostModel>> getPosts();
  Future<List<PostModel>> getUserPosts(String uid);
  Future<PostModel?> getPost(String postId);
  Future<void> likePost(String postId, String userId);
  Future<void> unlikePost(String postId, String userId);
  Future<PostModel> createPost({
    required List<File> imageFiles,
    required String caption,
    String? location,
  });
  Future<PostModel> createVideoPost({
    required File videoFile,
    File? thumbnailFile,
    required String caption,
    String? location,
  });
}

class PostRepository implements PostRepositoryInterface {
  final PostApiService _postApiService = PostApiService(ApiService());

  @override
  Future<List<PostModel>> getPosts() async {
    final postData = MockDataService.getPosts();
    return postData.map((post) => PostModel.fromMap(post)).toList();
  }

  @override
  Future<List<PostModel>> getUserPosts(String uid) async {
    final rawPosts = await _postApiService.getUserPosts();
    return rawPosts.map((post) => PostModel.fromApiResponse(post)).toList();
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

  /// Uploads each image to Azure/local storage, then creates the post record.
  @override
  Future<PostModel> createPost({
    required List<File> imageFiles,
    required String caption,
    String? location,
  }) async {
    final mediaUrls = await Future.wait(
      imageFiles.map((file) => _postApiService.uploadImage(file)),
    );

    final response = await _postApiService.createPost(
      caption: caption,
      location: location,
      mediaType: imageFiles.isEmpty ? 'text' : 'image',
      mediaUrls: mediaUrls,
    );

    return PostModel.fromApiResponse(response);
  }

  /// Uploads video (and optional thumbnail), then creates the post record.
  @override
  Future<PostModel> createVideoPost({
    required File videoFile,
    File? thumbnailFile,
    required String caption,
    String? location,
  }) async {
    final videoUrl = await _postApiService.uploadVideo(videoFile);

    String? thumbnailUrl;
    if (thumbnailFile != null) {
      thumbnailUrl = await _postApiService.uploadThumbnail(thumbnailFile);
    }

    final response = await _postApiService.createPost(
      caption: caption,
      location: location,
      mediaType: 'video',
      mediaUrls: [videoUrl],
      thumbnailUrl: thumbnailUrl,
    );

    return PostModel.fromApiResponse(response);
  }
}
