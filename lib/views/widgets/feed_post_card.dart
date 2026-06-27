import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../constants/color_constants.dart';
import '../../models/post_model.dart';
import '../../services/api_service.dart';
import '../../services/interaction_api_service.dart';
import '../../utils/theme_colors.dart';
import 'comments_sheet.dart';

/// Full-height feed post card that accepts raw API map data.
/// Used in feed, saved posts detail, and any other full-card context.
class FeedPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String currentUserId;
  final String currentUsername;
  final String currentAvatar;

  const FeedPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUsername,
    required this.currentAvatar,
  });

  /// Convenience constructor that reads auth state from the widget tree.
  /// Wrap in a BlocBuilder if you need to react to auth changes.
  static Widget fromContext({
    Key? key,
    required BuildContext context,
    required Map<String, dynamic> post,
  }) {
    final authState = BlocProvider.of<AuthBloc>(context, listen: false).state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.uid : '';
    final currentUsername = authState is AuthAuthenticated ? authState.user.username : '';
    final currentAvatar = authState is AuthAuthenticated ? authState.user.profileImageUrl : '';
    return FeedPostCard(
      key: key,
      post: post,
      currentUserId: currentUserId,
      currentUsername: currentUsername,
      currentAvatar: currentAvatar,
    );
  }

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard>
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
    _isLiked = widget.post['is_liked'] as bool? ?? false;
    _isSaved = widget.post['is_saved'] as bool? ?? false;
    _likesCount =
        widget.post['likes_count'] as int? ??
        (widget.post['likes'] as List?)?.length ??
        0;
    _commentsCount =
        widget.post['comments_count'] as int? ??
        widget.post['commentsCount'] as int? ??
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
    final username = post['username'] as String? ?? post['display_name'] as String? ?? 'User';
    final profileUrl = post['avatar_url'] as String? ?? post['profileImageUrl'] as String? ?? '';
    final imageUrls = (post['imageUrls'] as List?)?.cast<String>() ?? [];
    final videoUrls = (post['videoUrls'] as List?)?.cast<String>() ?? [];
    final thumbnailUrls = (post['thumbnailUrls'] as List?)?.cast<String>() ?? [];
    final mediaTypeStr = post['mediaType'] as String? ?? post['media_type'] as String? ?? 'text';
    final isVideo = mediaTypeStr == 'video' || videoUrls.isNotEmpty;
    final caption = post['caption'] as String? ?? '';
    final location = post['location'] as String? ?? '';
    final authorUserId = post['user_id'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        GestureDetector(
          onTap: () {
            if (username.isEmpty) return;
            if (authorUserId == widget.currentUserId) return;
            context.push('/profile/$username');
          },
          child: Padding(
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
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: context.primaryText)),
                      if (location.isNotEmpty)
                        Text(location,
                            style: TextStyle(
                                fontSize: 11, color: context.mutedText)),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz, color: context.iconColor, size: 20),
              ],
            ),
          ),
        ),

        // ── Media ─────────────────────────────────────────────────────────
        if (isVideo && videoUrls.isNotEmpty)
          GestureDetector(
            onDoubleTap: _onDoubleTap,
            child: Stack(
              children: [
                VideoPostPlayer(
                  videoUrl: videoUrls.first,
                  thumbnailUrl: thumbnailUrls.isNotEmpty ? thumbnailUrls.first : null,
                ),
                Positioned.fill(child: _heartOverlay()),
              ],
            ),
          )
        else if (imageUrls.isNotEmpty)
          GestureDetector(
            onDoubleTap: _onDoubleTap,
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ColoredBox(
                    color: Colors.black,
                    child: imageUrls.length == 1
                        ? CachedNetworkImage(
                            imageUrl: imageUrls[0],
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.accent, strokeWidth: 2)),
                            errorWidget: (_, __, ___) => const Icon(
                                Icons.image_not_supported,
                                color: AppColors.neutral400),
                          )
                        : PageView.builder(
                            itemCount: imageUrls.length,
                            itemBuilder: (_, i) => CachedNetworkImage(
                              imageUrl: imageUrls[i],
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const SizedBox.shrink(),
                              errorWidget: (_, __, ___) => const Icon(
                                  Icons.image_not_supported,
                                  color: AppColors.neutral400),
                            ),
                          ),
                  ),
                ),
                Positioned.fill(child: _heartOverlay()),
              ],
            ),
          ),

        // ── Actions ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
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
                        color: _isLiked ? AppColors.like : context.iconColor,
                        size: 26,
                      ),
                      if (_likesCount > 0) ...[
                        const SizedBox(width: 5),
                        Text('$_likesCount',
                            style: TextStyle(
                                color: _isLiked
                                    ? AppColors.like
                                    : context.iconColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _openComments,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: context.iconColor, size: 24),
                      if (_commentsCount > 0) ...[
                        const SizedBox(width: 5),
                        Text('$_commentsCount',
                            style: TextStyle(
                                color: context.iconColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.send_outlined, color: context.iconColor, size: 24),
              const Spacer(),
              GestureDetector(
                onTap: _toggleSave,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: _isSaved ? AppColors.accent : context.iconColor,
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
                style: TextStyle(
                    color: context.primaryText, fontSize: 13.5, height: 1.4),
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
            style: TextStyle(color: context.mutedText, fontSize: 11),
          ),
        ),

        Divider(color: context.dividerColor, height: 1),
      ],
    );
  }

  Widget _heartOverlay() {
    return Visibility(
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
                  shadows: [Shadow(color: Colors.black54, blurRadius: 24)]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Video Post Player ────────────────────────────────────────────────────────

class VideoPostPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const VideoPostPlayer({super.key, required this.videoUrl, this.thumbnailUrl});

  @override
  State<VideoPostPlayer> createState() => _VideoPostPlayerState();
}

class _VideoPostPlayerState extends State<VideoPostPlayer> {
  VideoPlayerController? _controller;
  bool _isInitializing = false;
  bool _isPlaying = false;

  Future<void> _initAndPlay() async {
    if (_controller != null) {
      if (_isPlaying) {
        _controller!.pause();
        setState(() => _isPlaying = false);
      } else {
        _controller!.play();
        setState(() => _isPlaying = true);
      }
      return;
    }

    setState(() => _isInitializing = true);
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      _controller = controller;
      await controller.play();
      setState(() {
        _isInitializing = false;
        _isPlaying = true;
      });
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return AspectRatio(
      aspectRatio: controller != null && controller.value.isInitialized
          ? controller.value.aspectRatio
          : 1.0,
      child: GestureDetector(
        onTap: _initAndPlay,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null && controller.value.isInitialized)
              VideoPlayer(controller)
            else if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: context.shimmerBase),
                errorWidget: (_, __, ___) => Container(color: context.shimmerBase),
              )
            else
              Container(color: context.shimmerBase),

            if (!_isPlaying)
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: _isInitializing
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 32),
                ),
              ),

            if (controller != null && controller.value.isInitialized)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppColors.accent,
                    bufferedColor: Colors.white30,
                    backgroundColor: Colors.white10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
