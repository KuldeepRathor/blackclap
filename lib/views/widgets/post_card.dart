import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../blocs/posts/posts_bloc.dart';
import '../../../blocs/posts/posts_event.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../constants/color_constants.dart';
import 'comments_bottom_sheet.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isSaved;
  final VoidCallback? onSaveToggle;

  const PostCard({
    super.key,
    required this.post,
    this.isSaved = false,
    this.onSaveToggle,
  });

  String _formatTime(dynamic createdAt) {
    if (createdAt is DateTime) {
      final now = DateTime.now();
      final difference = now.difference(createdAt);
      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
    }
    return '';
  }

  void _showPostOptions(BuildContext context, String currentUid) {
    final isOwn = post['uid'] == currentUid;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isOwn) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  context
                      .read<PostsBloc>()
                      .add(PostsDeleteRequested(postId: post['id']));
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archive'),
                onTap: () => Navigator.pop(ctx),
              ),
            ] else ...[
              ListTile(
                leading:
                    const Icon(Icons.flag_outlined, color: AppColors.error),
                title: const Text('Report'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.not_interested_outlined),
                title: const Text('Not Interested'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy Link'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
            leading: GestureDetector(
              onTap: () => context.push('/user/${post['uid']}'),
              child: CircleAvatar(
                backgroundImage: post['profileImageUrl'] != null &&
                        (post['profileImageUrl'] as String).isNotEmpty
                    ? NetworkImage(post['profileImageUrl'])
                    : null,
                backgroundColor: AppColors.accent,
                child: post['profileImageUrl'] == null ||
                        (post['profileImageUrl'] as String).isEmpty
                    ? Text(
                        (post['fullName'] as String? ?? 'U').isNotEmpty
                            ? (post['fullName'] as String)[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnAccent,
                        ),
                      )
                    : null,
              ),
            ),
            title: GestureDetector(
              onTap: () => context.push('/user/${post['uid']}'),
              child: Text(
                post['fullName'] ?? 'Unknown User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: Text('@${post['username'] ?? 'unknown'}'),
            trailing: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final currentUid =
                    authState is AuthAuthenticated ? authState.user.uid : '';
                return IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showPostOptions(context, currentUid),
                );
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
                  return GestureDetector(
                    onDoubleTap: () {
                      final authState = context.read<AuthBloc>().state;
                      if (authState is AuthAuthenticated) {
                        context.read<PostsBloc>().add(PostsLikeToggled(
                              postId: post['id'],
                              userId: authState.user.uid,
                            ));
                      }
                    },
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.imagePlaceholder,
                        child: const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.accent, strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.imagePlaceholder,
                        child: const Icon(Icons.image_not_supported,
                            size: 50, color: AppColors.neutral400),
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
                  final currentUserId =
                      authState is AuthAuthenticated ? authState.user.uid : '';
                  final isLiked =
                      (post['likes'] as List).contains(currentUserId);
                  return IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_outline,
                      color: isLiked ? AppColors.like : AppColors.onSurface,
                    ),
                    onPressed: () {
                      context.read<PostsBloc>().add(PostsLikeToggled(
                            postId: post['id'],
                            userId: currentUserId,
                          ));
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CommentsBottomSheet(postId: post['id']),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.send_outlined),
                onPressed: () {},
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  color: isSaved ? AppColors.save : AppColors.onSurface,
                ),
                onPressed: onSaveToggle,
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
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => context.push('/post/${post['id']}'),
                  child: Text(
                    (post['comments'] as List).isNotEmpty
                        ? 'View all ${(post['comments'] as List).length} comments'
                        : 'Add a comment...',
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(post['createdAt']),
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
