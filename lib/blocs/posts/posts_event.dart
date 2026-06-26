import 'package:equatable/equatable.dart';

abstract class PostsEvent extends Equatable {
  const PostsEvent();

  @override
  List<Object?> get props => [];
}

class PostsLoadRequested extends PostsEvent {}

class PostsRefreshRequested extends PostsEvent {}

class PostsLikeToggled extends PostsEvent {
  final String postId;
  final String userId;

  const PostsLikeToggled({required this.postId, required this.userId});

  @override
  List<Object?> get props => [postId, userId];
}

class PostsCreateRequested extends PostsEvent {
  /// Absolute file paths for selected media (images or single video).
  final List<String> filePaths;
  final String caption;
  final String? location;

  /// 'image', 'video', or 'text'
  final String mediaType;

  /// Absolute path to the generated thumbnail (video posts only).
  final String? thumbnailPath;

  const PostsCreateRequested({
    required this.filePaths,
    required this.caption,
    this.location,
    this.mediaType = 'image',
    this.thumbnailPath,
  });

  @override
  List<Object?> get props => [filePaths, caption, location, mediaType, thumbnailPath];
}
