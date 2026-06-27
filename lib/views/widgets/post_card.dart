import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/color_constants.dart';
import '../../models/post_model.dart';
import '../../services/api_service.dart';
import '../../services/interaction_api_service.dart';
import '../../services/post_api_service.dart';
import 'comments_sheet.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  /// Logged-in user's username — used only for the comment input, not the post header.
  final String? currentUsername;
  /// Logged-in user's avatar — used only for the comment input avatar, not the post header.
  final String? currentAvatarUrl;
  final void Function(bool isLiked, int likesCount)? onLikeChanged;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.currentUsername,
    this.currentAvatarUrl,
    this.onLikeChanged,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  late bool _isLiked;
  late bool _isSaved;
  late int _likesCount;
  late int _commentsCount;
  int _currentPage = 0;
  bool _showHeart = false;

  late AnimationController _heartController;
  late AnimationController _likeController;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;
  late Animation<double> _likeScale;

  final InteractionApiService _service = InteractionApiService(ApiService());
  final PostApiService _postApiService = PostApiService(ApiService());

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _isSaved = widget.post.isSaved;
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;

    _heartController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _heartScale = Tween<double>(begin: 0.3, end: 1.3).animate(
      CurvedAnimation(
          parent: _heartController,
          curve: const Interval(0, 0.5, curve: Curves.elasticOut)));
    _heartOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartController);

    _likeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _likeScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _heartController.dispose();
    _likeController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    HapticFeedback.lightImpact();
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    _likeController.forward(from: 0);
    try {
      final result = await _service.toggleLike(widget.post.id);
      if (mounted) {
        setState(() {
          _isLiked = result['is_liked'] as bool? ?? _isLiked;
          _likesCount = result['likes_count'] as int? ?? _likesCount;
        });
        widget.onLikeChanged?.call(_isLiked, _likesCount);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likesCount += wasLiked ? 1 : -1;
        });
      }
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
      final result = await _service.toggleSave(widget.post.id);
      if (mounted) setState(() => _isSaved = result['is_saved'] as bool? ?? _isSaved);
    } catch (_) {
      if (mounted) setState(() => _isSaved = wasSaved);
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(
        post: widget.post,
        currentUserId: widget.currentUserId,
        currentUserAvatar: widget.currentAvatarUrl,
        currentUsername: widget.currentUsername ?? widget.post.username,
        onCommentAdded: () {
          if (mounted) setState(() => _commentsCount++);
        },
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    // Header always shows the POST AUTHOR's info, not the logged-in user's info.
    final displayName = widget.post.username.isNotEmpty ? widget.post.username : 'user';
    final avatarUrl = widget.post.profileImageUrl.isNotEmpty
        ? widget.post.profileImageUrl
        : null;

    return Container(
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(displayName, avatarUrl),
          _buildMedia(),
          _buildActions(),
          _buildDetails(displayName),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  bool get _isOwnPost => widget.post.uid == widget.currentUserId;

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.neutral500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (_isOwnPost)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: const Text(
                  'Delete post',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined,
                    color: AppColors.neutral200),
                title: const Text('Report'),
                onTap: () => Navigator.pop(context),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete post',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'This will permanently delete your post. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.neutral400)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deletePost(context);
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await _postApiService.deletePost(widget.post.id);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Post deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToAuthorProfile(BuildContext context, String authorUsername) {
    if (authorUsername.isEmpty) return;
    // If the author is the current user, don't navigate (they can use the profile tab)
    if (authorUsername == widget.currentUserId) return;
    context.push('/profile/$authorUsername');
  }

  Widget _buildHeader(String displayName, String? avatarUrl) {
    final authorUsername = widget.post.username;
    return GestureDetector(
      onTap: () => _navigateToAuthorProfile(context, authorUsername),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _buildAvatar(displayName, avatarUrl, 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.onSurface)),
                  if (widget.post.location.isNotEmpty)
                    Text(widget.post.location,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.neutral400)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showPostMenu(context),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.more_horiz,
                    color: AppColors.neutral400, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? url, double radius) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(1.5),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        backgroundImage:
            url != null ? CachedNetworkImageProvider(url) : null,
        child: url == null
            ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: TextStyle(
                    fontSize: radius * 0.8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent))
            : null,
      ),
    );
  }

  Widget _buildMedia() {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        children: [
          if (widget.post.mediaType == MediaType.image &&
              widget.post.imageUrls.isNotEmpty)
            ..._buildImageMedia()
          else if (widget.post.mediaType == MediaType.video)
            _buildVideoMedia()
          else
            const SizedBox.shrink(),
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
                            Shadow(color: Colors.black54, blurRadius: 20)
                          ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildImageMedia() {
    final images = widget.post.imageUrls;
    return [
      AspectRatio(
        aspectRatio: 1,
        child: ColoredBox(
          color: Colors.black,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: images[i],
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accent, strokeWidth: 2)),
              errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported,
                  color: AppColors.neutral400),
            ),
          ),
        ),
      ),
      if (images.length > 1)
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: _currentPage == i ? 8 : 5,
                      height: _currentPage == i ? 8 : 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == i
                            ? AppColors.accent
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    )),
          ),
        ),
      Positioned(
        top: 10,
        right: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('${_currentPage + 1}/${images.length}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    ];
  }

  Widget _buildVideoMedia() {
    final thumb = widget.post.thumbnailUrls.isNotEmpty
        ? widget.post.thumbnailUrls[0]
        : null;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          thumb != null
              ? CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.neutral600),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.neutral800))
              : Container(color: AppColors.neutral800),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3)
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8), width: 2),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 38),
            ),
          ),
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 14),
                  SizedBox(width: 3),
                  Text('Video',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _likeController,
            builder: (_, child) =>
                Transform.scale(scale: _likeScale.value, child: child),
            child: IconButton(
              icon: Icon(
                _isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isLiked ? AppColors.like : AppColors.neutral200,
                size: 26,
              ),
              onPressed: _toggleLike,
            ),
          ),
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
          IconButton(
            icon: const Icon(Icons.send_outlined,
                color: AppColors.neutral200, size: 24),
            onPressed: () {},
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isSaved ? AppColors.accent : AppColors.neutral200,
              size: 24,
            ),
            onPressed: _toggleSave,
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(String displayName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_likesCount > 0)
            Text(
                '${_formatCount(_likesCount)} ${_likesCount == 1 ? 'like' : 'likes'}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.onSurface)),
          if (widget.post.caption.isNotEmpty) ...[
            const SizedBox(height: 5),
            RichText(
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                  style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 13.5,
                      height: 1.4),
                  children: [
                    TextSpan(
                        text: '$displayName ',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: widget.post.caption),
                  ]),
            ),
          ],
          if (_commentsCount > 0) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _openComments,
              child: Text(
                  'View all $_commentsCount comment${_commentsCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: AppColors.neutral400, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 6),
          Text(_timeAgo(widget.post.createdAt),
              style: const TextStyle(
                  color: AppColors.neutral400, fontSize: 11)),
        ],
      ),
    );
  }
}
