import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/posts/posts_bloc.dart';
import '../../../blocs/posts/posts_event.dart';
import '../../../blocs/posts/posts_state.dart';
import '../../../constants/color_constants.dart';
import '../../../models/post_model.dart';
import '../../../services/api_service.dart';
import '../../../services/interaction_api_service.dart';
import '../../widgets/comments_sheet.dart';

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
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Blackclap',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline, color: AppColors.onSurface),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, state) {
          if (state is PostsLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          if (state is PostsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.neutral400),
                  const SizedBox(height: 16),
                  const Text('Error loading posts',
                      style: TextStyle(fontSize: 18, color: AppColors.onSurface)),
                  const SizedBox(height: 8),
                  Text(state.message,
                      style: const TextStyle(fontSize: 14, color: AppColors.neutral200),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<PostsBloc>().add(PostsLoadRequested()),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
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
                    Icon(Icons.photo_library_outlined, size: 64, color: AppColors.neutral400),
                    SizedBox(height: 16),
                    Text('No posts yet', style: TextStyle(fontSize: 18, color: AppColors.onSurface)),
                  ],
                ),
              );
            }

            return BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final currentUserId =
                    authState is AuthAuthenticated ? authState.user.uid : '';
                final currentUsername =
                    authState is AuthAuthenticated ? authState.user.username : '';
                final currentAvatar =
                    authState is AuthAuthenticated ? authState.user.profileImageUrl : '';

                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async =>
                      context.read<PostsBloc>().add(PostsRefreshRequested()),
                  child: ListView.builder(
                    itemCount: state.posts.length,
                    itemBuilder: (context, index) {
                      final raw = state.posts[index];
                      return _FeedPostCard(
                        key: ValueKey(raw['id'] ?? index),
                        post: raw,
                        currentUserId: currentUserId,
                        currentUsername: currentUsername,
                        currentAvatar: currentAvatar,
                      );
                    },
                  ),
                );
              },
            );
          }

          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        },
      ),
    );
  }
}

// ── Feed Post Card ───────────────────────────────────────────────────────────

class _FeedPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String currentUserId;
  final String currentUsername;
  final String currentAvatar;

  const _FeedPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUsername,
    required this.currentAvatar,
  });

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late bool _isSaved;
  late int _likesCount;
  late int _commentsCount;
  bool _showHeart = false;

  late AnimationController _heartController;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;

  final InteractionApiService _service = InteractionApiService(ApiService());

  @override
  void initState() {
    super.initState();
    final likes = widget.post['likes'] as List? ?? [];
    _isLiked = likes.contains(widget.currentUserId);
    _isSaved = widget.post['is_saved'] as bool? ?? false;
    _likesCount = likes.length;
    _commentsCount =
        (widget.post['comments_count'] as int?) ??
        (widget.post['commentsCount'] as int?) ??
        (widget.post['comments'] as List?)?.length ??
        0;

    _heartController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _heartScale = Tween<double>(begin: 0.3, end: 1.3).animate(
        CurvedAnimation(
            parent: _heartController,
            curve: const Interval(0, 0.55, curve: Curves.elasticOut)));
    _heartOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartController);
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    HapticFeedback.lightImpact();
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    try {
      final postId = widget.post['id'] as String? ?? '';
      if (postId.isEmpty) return;
      final result = await _service.toggleLike(postId);
      if (!mounted) return;
      setState(() {
        _isLiked = result['is_liked'] as bool? ?? _isLiked;
        _likesCount = result['likes_count'] as int? ?? _likesCount;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLiked = wasLiked;
        _likesCount += wasLiked ? 1 : -1;
      });
    }
  }

  Future<void> _onDoubleTap() async {
    HapticFeedback.mediumImpact();
    setState(() => _showHeart = true);
    _heartController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 750));
    if (mounted) setState(() => _showHeart = false);
    if (!_isLiked) await _toggleLike();
  }

  Future<void> _toggleSave() async {
    HapticFeedback.lightImpact();
    final wasSaved = _isSaved;
    setState(() => _isSaved = !_isSaved);
    try {
      final postId = widget.post['id'] as String? ?? '';
      if (postId.isEmpty) return;
      final result = await _service.toggleSave(postId);
      if (mounted) setState(() => _isSaved = result['is_saved'] as bool? ?? _isSaved);
    } catch (_) {
      if (mounted) setState(() => _isSaved = wasSaved);
    }
  }

  void _openComments() {
    final post = PostModel.fromMap(widget.post);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(
        post: post,
        currentUserId: widget.currentUserId,
        currentUserAvatar: widget.currentAvatar,
        currentUsername: widget.currentUsername,
        onCommentAdded: () {
          if (mounted) setState(() => _commentsCount++);
        },
      ),
    );
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt is! DateTime) return '';
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final username = post['username'] as String? ?? post['fullName'] as String? ?? 'User';
    final profileUrl = post['profileImageUrl'] as String? ?? '';
    final imageUrls = (post['imageUrls'] as List?)?.cast<String>() ?? [];
    final caption = post['caption'] as String? ?? '';
    final location = post['location'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accent,
                backgroundImage: profileUrl.isNotEmpty
                    ? CachedNetworkImageProvider(profileUrl)
                    : null,
                child: profileUrl.isEmpty
                    ? Text(username.isNotEmpty ? username[0].toUpperCase() : 'U',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onAccent))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: AppColors.onSurface)),
                    if (location.isNotEmpty)
                      Text(location,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.neutral400)),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: AppColors.neutral400, size: 20),
            ],
          ),
        ),

        // ── Media ─────────────────────────────────────────────────────────
        if (imageUrls.isNotEmpty)
          GestureDetector(
            onDoubleTap: _onDoubleTap,
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: imageUrls.length == 1
                      ? CachedNetworkImage(
                          imageUrl: imageUrls[0],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: AppColors.neutral600,
                              child: const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.accent, strokeWidth: 2))),
                          errorWidget: (_, __, ___) => Container(
                              color: AppColors.neutral600,
                              child: const Icon(Icons.image_not_supported,
                                  color: AppColors.neutral400)),
                        )
                      : PageView.builder(
                          itemCount: imageUrls.length,
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: imageUrls[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AppColors.neutral600),
                            errorWidget: (_, __, ___) => Container(
                                color: AppColors.neutral600,
                                child: const Icon(Icons.image_not_supported,
                                    color: AppColors.neutral400)),
                          ),
                        ),
                ),
                Positioned.fill(
                  child: Visibility(
                    visible: _showHeart,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _heartController,
                        builder: (_, __) => Opacity(
                          opacity: _heartOpacity.value,
                          child: Transform.scale(
                            scale: _heartScale.value,
                            child: const Icon(Icons.favorite,
                                color: AppColors.like,
                                size: 90,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 24)
                                ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Actions ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              // Like
              GestureDetector(
                onTap: _toggleLike,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(
                        _isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _isLiked ? AppColors.like : AppColors.neutral200,
                        size: 26,
                      ),
                      if (_likesCount > 0) ...[
                        const SizedBox(width: 5),
                        Text('$_likesCount',
                            style: TextStyle(
                                color: _isLiked
                                    ? AppColors.like
                                    : AppColors.neutral200,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Comment
              GestureDetector(
                onTap: _openComments,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          color: AppColors.neutral200, size: 24),
                      if (_commentsCount > 0) ...[
                        const SizedBox(width: 5),
                        Text('$_commentsCount',
                            style: const TextStyle(
                                color: AppColors.neutral200,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.send_outlined, color: AppColors.neutral200, size: 24),
              const Spacer(),
              GestureDetector(
                onTap: _toggleSave,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: _isSaved ? AppColors.accent : AppColors.neutral200,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),

        // ── Details ───────────────────────────────────────────────────────
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: RichText(
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(
                    color: AppColors.onSurface, fontSize: 13.5, height: 1.4),
                children: [
                  TextSpan(
                      text: '$username ',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: caption),
                ],
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.only(left: 14, top: 6, bottom: 14),
          child: Text(
            _formatTime(post['createdAt']),
            style: const TextStyle(color: AppColors.neutral400, fontSize: 11),
          ),
        ),

        const Divider(color: AppColors.neutral600, height: 1),
      ],
    );
  }
}
