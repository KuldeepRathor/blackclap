import 'dart:io';

import 'api_service.dart';

class PostApiService {
  final ApiService _api;

  PostApiService(this._api);

  /// Step 1: Ask the backend for a presigned upload URL.
  /// Returns the URL to PUT the file to and the final download URL.
  Future<({String uploadUrl, String downloadUrl})> _getPresignedUrl({
    required String fileName,
    required String fileType,
  }) async {
    final data = await _api.post('/media/presigned-url', {
      'file_name': fileName,
      'file_type': fileType,
      'purpose': 'post',
    });
    return (
      uploadUrl: data['upload_url'] as String,
      downloadUrl: data['download_url'] as String,
    );
  }

  /// Step 2: Upload a single image file. Returns the final download URL.
  Future<String> uploadImage(File file) async {
    final fileName = file.path.split('/').last;
    final ext = fileName.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final (:uploadUrl, :downloadUrl) = await _getPresignedUrl(
      fileName: fileName,
      fileType: contentType,
    );

    final bytes = await file.readAsBytes();
    await _api.putBytes(uploadUrl, bytes, contentType);

    return downloadUrl;
  }

  /// Upload a video file. Returns the final download URL.
  Future<String> uploadVideo(File file) async {
    final fileName = file.path.split('/').last;
    final ext = fileName.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      _ => 'video/mp4',
    };

    final (:uploadUrl, :downloadUrl) = await _getPresignedUrl(
      fileName: fileName,
      fileType: contentType,
    );

    final bytes = await file.readAsBytes();
    await _api.putBytes(uploadUrl, bytes, contentType);

    return downloadUrl;
  }

  /// Upload a thumbnail image (for video posts). Returns the final download URL.
  Future<String> uploadThumbnail(File file) async {
    final fileName = file.path.split('/').last;
    final ext = fileName.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final (:uploadUrl, :downloadUrl) = await _getPresignedUrl(
      fileName: fileName,
      fileType: contentType,
    );

    final bytes = await file.readAsBytes();
    await _api.putBytes(uploadUrl, bytes, contentType);

    return downloadUrl;
  }

  /// Fetch all posts for the currently authenticated user.
  Future<List<Map<String, dynamic>>> getUserPosts() async {
    final list = await _api.getList('/posts/me');
    return list.cast<Map<String, dynamic>>();
  }

  /// Fetch the current user's saved posts.
  Future<List<Map<String, dynamic>>> getSavedPosts() async {
    final list = await _api.getList('/users/me/saved-posts');
    return list.cast<Map<String, dynamic>>();
  }

  /// Step 3: Create the post record with the collected blob URLs.
  Future<Map<String, dynamic>> createPost({
    required String? caption,
    required String? location,
    required String mediaType,
    required List<String> mediaUrls,
    String? thumbnailUrl,
  }) async {
    return await _api.post('/posts', {
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      if (location != null && location.isNotEmpty) 'location': location,
      'media_type': mediaType,
      'media_urls': mediaUrls,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
    });
  }
}
