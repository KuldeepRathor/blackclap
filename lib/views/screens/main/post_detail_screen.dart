import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/posts/posts_bloc.dart';
import '../../../blocs/posts/posts_event.dart';
import '../../../constants/color_constants.dart';
import '../../../repositories/mock_data_service.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/comments_bottom_sheet.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Map<String, dynamic>? _post;

  @override
  void initState() {
    super.initState();
    _post = MockDataService.getPost(widget.postId);
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt is DateTime) {
      final diff = DateTime.now().difference(createdAt);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_post == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(child: Text('Post not found')),
      );
    }

    final post = _post!;
    final images = List<dynamic>.from(post['imageUrls'] ?? []);
    final comments = List<Map<String, dynamic>>.from(post['comments'] ?? []);
    final likes = List<dynamic>.from(post['likes'] ?? []);
    final authState = context.read<AuthBloc>().state;
    final currentUid = authState is AuthAuthenticated ? authState.user.uid : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // Header
          ListTile(
            leading: GestureDetector(
              onTap: () => context.push('/user/${post['uid']}'),
              child: UserAvatar(
                imageUrl: post['profileImageUrl'],
                fallbackName: post['fullName'] ?? 'U',
                radius: 20,
              ),
            ),
            title: GestureDetector(
              onTap: () => context.push('/user/${post['uid']}'),
              child: Text(
                post['fullName'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: Text('@${post['username'] ?? 'unknown'}'),
            trailing: Text(
              _formatTime(post['createdAt']),
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ),

          // Image carousel
          if (images.isNotEmpty)
            Column(
              children: [
                SizedBox(
                  height: 360,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (ctx, i) => Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (i) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == 0
                                ? AppColors.accent
                                : AppColors.neutral300,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          // Actions
          Row(
            children: [
              BlocBuilder<PostsBloc, dynamic>(
                builder: (context, state) {
                  final freshPost =
                      MockDataService.getPost(widget.postId) ?? post;
                  final freshLikes =
                      List<dynamic>.from(freshPost['likes'] ?? []);
                  final isLiked = freshLikes.contains(currentUid);
                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_outline,
                          color: isLiked ? AppColors.like : AppColors.onSurface,
                        ),
                        onPressed: () {
                          context.read<PostsBloc>().add(PostsLikeToggled(
                              postId: post['id'], userId: currentUid));
                          setState(() {
                            _post = MockDataService.getPost(widget.postId);
                          });
                        },
                      ),
                      if (freshLikes.isNotEmpty)
                        Text(
                          '${freshLikes.length}',
                          style: const TextStyle(fontSize: 13),
                        ),
                    ],
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
              Text('${comments.length}', style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.send_outlined),
                onPressed: () {},
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_outline),
                onPressed: () {},
              ),
            ],
          ),

          // Likes count
          if (likes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${likes.length} ${likes.length == 1 ? 'like' : 'likes'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

          // Caption
          if (post['caption'] != null && (post['caption'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: RichText(
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
            ),

          if (post['location'] != null &&
              (post['location'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    post['location'],
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 13),
                  ),
                ],
              ),
            ),

          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Comments (${comments.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // All comments
          if (comments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No comments yet. Be the first!',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            )
          else
            ...comments.map((comment) => ListTile(
                  leading: UserAvatar(
                    imageUrl: comment['profileImageUrl'],
                    fallbackName: comment['username'] ?? 'U',
                    radius: 18,
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          color: AppColors.onSurface, fontSize: 14),
                      children: [
                        TextSpan(
                          text: '${comment['username']} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: comment['comment']),
                      ],
                    ),
                  ),
                  subtitle: Text(
                    _formatTime(comment['createdAt']),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 11),
                  ),
                )),

          // Add comment button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CommentsBottomSheet(postId: post['id']),
                ).then((_) {
                  setState(() {
                    _post = MockDataService.getPost(widget.postId);
                  });
                });
              },
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: const Text('Add a comment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
