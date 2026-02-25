import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../repositories/mock_data_service.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../constants/color_constants.dart';
import '../../widgets/comments_bottom_sheet.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late PageController _pageController;
  List<Map<String, dynamic>> _reels = [];
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _pageController = PageController();
    _loadReels();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _disposeAllControllers();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _disposeAllControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  /// Fix memory leak: dispose controllers that are more than 2 positions away
  void _disposeDistantControllers(int currentIndex) {
    final toRemove = <int>[];
    for (final index in _controllers.keys) {
      if ((index - currentIndex).abs() > 2) {
        _controllers[index]?.dispose();
        toRemove.add(index);
      }
    }
    for (final index in toRemove) {
      _controllers.remove(index);
    }
  }

  void _loadReels() {
    setState(() {
      _reels = MockDataService.getReels();
    });
    if (_reels.isNotEmpty) {
      _initializeVideo(0);
    }
  }

  Future<void> _initializeVideo(int index) async {
    if (_controllers.containsKey(index)) return;
    if (index < 0 || index >= _reels.length) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(_reels[index]['videoUrl']),
    );

    _controllers[index] = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (index == _currentIndex) {
        await controller.play();
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video at index $index: $e');
    }

    // Preload adjacent videos
    if (index + 1 < _reels.length) _initializeVideo(index + 1);
  }

  void _onPageChanged(int index) {
    _controllers[_currentIndex]?.pause();

    setState(() => _currentIndex = index);

    _controllers[index]?.play();

    if (!_controllers.containsKey(index + 1) && index + 1 < _reels.length) {
      _initializeVideo(index + 1);
    }

    // Dispose controllers far from the viewport (memory leak fix)
    _disposeDistantControllers(index);
  }

  Future<void> _toggleLike(String reelId, String userId) async {
    final reel = _reels.firstWhere((r) => r['id'] == reelId);
    final likes = List<String>.from(reel['likes']);

    if (likes.contains(userId)) {
      await MockDataService.unlikeReel(reelId, userId);
    } else {
      await MockDataService.likeReel(reelId, userId);
    }

    setState(() => _reels = MockDataService.getReels());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _reels.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final reel = _reels[index];
              return _ReelItem(
                reel: reel,
                videoController: _controllers[index],
                onLikeToggle: _toggleLike,
                isVisible: index == _currentIndex,
              );
            },
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reels',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined,
                            color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelItem extends StatefulWidget {
  final Map<String, dynamic> reel;
  final VideoPlayerController? videoController;
  final Function(String reelId, String userId) onLikeToggle;
  final bool isVisible;

  const _ReelItem({
    required this.reel,
    this.videoController,
    required this.onLikeToggle,
    required this.isVisible,
  });

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _showHeart = false;
  bool _isPlaying = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDoubleTap(String userId) {
    setState(() => _showHeart = true);
    _animationController.forward().then((_) {
      _animationController.reverse().then((_) {
        if (mounted) setState(() => _showHeart = false);
      });
    });

    final likes = widget.reel['likes'] as List;
    if (!likes.contains(userId)) {
      widget.onLikeToggle(widget.reel['id'], userId);
    }
  }

  void _togglePlayPause() {
    if (widget.videoController != null) {
      setState(() {
        if (_isPlaying) {
          widget.videoController!.pause();
        } else {
          widget.videoController!.play();
        }
        _isPlaying = !_isPlaying;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final currentUid = authState.user.uid;
    final targetUid = widget.reel['uid'] as String;

    setState(() => _isFollowing = !_isFollowing);
    if (_isFollowing) {
      await MockDataService.followUser(currentUid, targetUid);
    } else {
      await MockDataService.unfollowUser(currentUid, targetUid);
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return VisibilityDetector(
      key: Key('reel-${widget.reel['id']}'),
      onVisibilityChanged: (info) {
        if (widget.videoController != null && widget.isVisible) {
          if (info.visibleFraction > 0.5) {
            widget.videoController!.play();
            if (mounted) setState(() => _isPlaying = true);
          } else {
            widget.videoController!.pause();
            if (mounted) setState(() => _isPlaying = false);
          }
        }
      },
      child: Stack(
        children: [
          // Video Player or Thumbnail
          GestureDetector(
            onTap: _togglePlayPause,
            onDoubleTap: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                _onDoubleTap(authState.user.uid);
              }
            },
            child: Container(
              width: screenSize.width,
              height: screenSize.height,
              color: Colors.black,
              child: widget.videoController != null &&
                      widget.videoController!.value.isInitialized
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio:
                              widget.videoController!.value.aspectRatio,
                          child: VideoPlayer(widget.videoController!),
                        ),
                        AnimatedOpacity(
                          opacity: !_isPlaying ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow,
                                color: Colors.white, size: 50),
                          ),
                        ),
                      ],
                    )
                  : CachedNetworkImage(
                      imageUrl: widget.reel['thumbnailUrl'],
                      fit: BoxFit.cover,
                      width: screenSize.width,
                      height: screenSize.height,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.error_outline,
                            color: Colors.white, size: 50),
                      ),
                    ),
            ),
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Content Overlay (bottom-left)
          Positioned(
            left: 16,
            right: 80,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/user/${widget.reel['uid']}'),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surface,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.accent,
                          backgroundImage:
                              widget.reel['profileImageUrl'] != null &&
                                      (widget.reel['profileImageUrl'] as String)
                                          .isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      widget.reel['profileImageUrl'],
                                    )
                                  : null,
                          child: widget.reel['profileImageUrl'] == null ||
                                  (widget.reel['profileImageUrl'] as String)
                                      .isEmpty
                              ? Text(
                                  (widget.reel['fullName'] as String? ?? 'U')
                                          .isNotEmpty
                                      ? (widget.reel['fullName'] as String)[0]
                                          .toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => context.push('/user/${widget.reel['uid']}'),
                      child: Text(
                        widget.reel['username'] ?? 'unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (widget.reel['isVerified'] == true) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified,
                          color: AppColors.info, size: 16),
                    ],
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _toggleFollow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isFollowing
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.reel['caption'] != null &&
                    (widget.reel['caption'] as String).isNotEmpty)
                  Text(
                    widget.reel['caption'],
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (widget.reel['musicName'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.music_note,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.reel['musicName'],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Side Action Buttons (right)
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: [
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final currentUserId = authState is AuthAuthenticated
                        ? authState.user.uid
                        : '';
                    final isLiked =
                        (widget.reel['likes'] as List).contains(currentUserId);

                    return _ActionButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? AppColors.like : Colors.white,
                      label:
                          _formatNumber((widget.reel['likes'] as List).length),
                      onTap: () =>
                          widget.onLikeToggle(widget.reel['id'], currentUserId),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.comment_outlined,
                  color: Colors.white,
                  label: _formatNumber(
                      (widget.reel['comments'] as List?)?.length ?? 0),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          CommentsBottomSheet(postId: widget.reel['id']),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.send_outlined,
                  color: Colors.white,
                  label: _formatNumber(widget.reel['shares'] ?? 0),
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.more_vert,
                  color: Colors.white,
                  label: '',
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: widget.reel['profileImageUrl'] != null &&
                            (widget.reel['profileImageUrl'] as String)
                                .isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              widget.reel['profileImageUrl'],
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: AppColors.accent,
                  ),
                  child: widget.reel['profileImageUrl'] == null ||
                          (widget.reel['profileImageUrl'] as String).isEmpty
                      ? const Icon(Icons.music_note,
                          color: Colors.white, size: 20)
                      : null,
                ),
              ],
            ),
          ),

          // Double-tap heart animation
          if (_showHeart)
            Center(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.white
                        .withOpacity(1.0 - _animationController.value),
                    size: 100,
                  ),
                ),
              ),
            ),

          // Views count bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${_formatNumber(widget.reel['views'] ?? 0)} views',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
