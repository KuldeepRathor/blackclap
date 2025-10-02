import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../blocs/posts/posts_bloc.dart';
import '../../../blocs/posts/posts_event.dart';
import '../../../blocs/posts/posts_state.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../constants/color_constants.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PostsBloc>().add(PostsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Blackclap',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            onPressed: () {
              // Navigate to activity/notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              // Navigate to messages
            },
          ),
        ],
      ),
      body: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, state) {
          if (state is PostsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (state is PostsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.neutral400),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading posts',
                    style: const TextStyle(fontSize: 18, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: const TextStyle(fontSize: 14, color: AppColors.neutral200),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PostsBloc>().add(PostsLoadRequested());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is PostsLoaded) {
            if (state.posts.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: AppColors.neutral400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No posts yet',
                      style: TextStyle(fontSize: 18, color: AppColors.onSurface),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async {
                context.read<PostsBloc>().add(PostsRefreshRequested());
              },
              child: ListView.builder(
                itemCount: state.posts.length,
                itemBuilder: (context, index) {
                  final post = state.posts[index];
                  return _PostWidget(post: post);
                },
              ),
            );
          }

          return const Center(child: Text('Loading...'));
        },
      ),
    );
  }
}

class _PostWidget extends StatelessWidget {
  final dynamic post; // Using dynamic for now since we're dealing with Map data

  const _PostWidget({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  post['profileImageUrl'] != null &&
                      post['profileImageUrl'].isNotEmpty
                  ? CachedNetworkImageProvider(post['profileImageUrl'])
                  : null,
              child:
                  post['profileImageUrl'] == null ||
                      post['profileImageUrl'].isEmpty
                  ? Text(
                      (post['fullName'] as String).isNotEmpty
                          ? (post['fullName'] as String)[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            title: Text(
              post['fullName'] ?? 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('@${post['username'] ?? 'unknown'}'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show post options
              },
            ),
          ),

          // Post Images
          if (post['imageUrls'] != null &&
              (post['imageUrls'] as List).isNotEmpty)
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: (post['imageUrls'] as List).length,
                itemBuilder: (context, imageIndex) {
                  final imageUrl = (post['imageUrls'] as List)[imageIndex];
                  return CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.neutral600,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.neutral600,
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: AppColors.neutral400,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Post Actions
          Row(
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final currentUserId = authState is AuthAuthenticated
                      ? authState.user.uid
                      : '';
                  final isLiked = (post['likes'] as List).contains(
                    currentUserId,
                  );

                  return IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_outline,
                      color: isLiked ? AppColors.like : AppColors.onSurface,
                    ),
                    onPressed: () {
                      context.read<PostsBloc>().add(
                        PostsLikeToggled(
                          postId: post['id'],
                          userId: currentUserId,
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  // Show comments
                },
              ),
              IconButton(
                icon: const Icon(Icons.send_outlined),
                onPressed: () {
                  // Share post
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_outline),
                onPressed: () {
                  // Save post
                },
              ),
            ],
          ),

          // Post Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((post['likes'] as List).isNotEmpty)
                  Text(
                    '${(post['likes'] as List).length} ${(post['likes'] as List).length == 1 ? 'like' : 'likes'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 4),
                if (post['caption'] != null &&
                    (post['caption'] as String).isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.onSurface),
                      children: [
                        TextSpan(
                          text: '${post['username']} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: post['caption']),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                if (post['location'] != null &&
                    (post['location'] as String).isNotEmpty)
                  Text(
                    post['location'],
                    style: const TextStyle(color: AppColors.neutral200, fontSize: 12),
                  ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(post['createdAt']),
                  style: const TextStyle(color: AppColors.neutral200, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt is DateTime) {
      final now = DateTime.now();
      final difference = now.difference(createdAt);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    }
    return '';
  }
}
