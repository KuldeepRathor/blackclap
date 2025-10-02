import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../repositories/mock_data_service.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../constants/color_constants.dart';

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
    _disposeControllers();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
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

    // Preload next video
    if (index + 1 < _reels.length) {
      _initializeVideo(index + 1);
    }
  }

  void _onPageChanged(int index) {
    // Pause previous video
    _controllers[_currentIndex]?.pause();

    setState(() {
      _currentIndex = index;
    });

    // Play current video
    _controllers[index]?.play();

    // Preload next video if needed
    if (index + 1 < _reels.length && !_controllers.containsKey(index + 1)) {
      _initializeVideo(index + 1);
    }
  }

  Future<void> _toggleLike(String reelId, String userId) async {
    final reel = _reels.firstWhere((r) => r['id'] == reelId);
    final likes = List<String>.from(reel['likes']);

    if (likes.contains(userId)) {
      await MockDataService.unlikeReel(reelId, userId);
    } else {
      await MockDataService.likeReel(reelId, userId);
    }

    setState(() {
      _reels = MockDataService.getReels();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Video PageView
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
                          color: AppColors.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
                        color: AppColors.onPrimary,
                        onPressed: () {
                          // Open camera to create reel
                        },
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
    setState(() {
      _showHeart = true;
    });

    _animationController.forward().then((_) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _showHeart = false;
          });
        }
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
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
            setState(() => _isPlaying = true);
          } else {
            widget.videoController!.pause();
            setState(() => _isPlaying = false);
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
              child:
                  widget.videoController != null &&
                      widget.videoController!.value.isInitialized
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio:
                              widget.videoController!.value.aspectRatio,
                          child: VideoPlayer(widget.videoController!),
                        ),
                        // Play/Pause overlay
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
                            child: const Icon(
                              Icons.play_arrow,
                              color: AppColors.onPrimary,
                              size: 50,
                            ),
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
                        child: CircularProgressIndicator(color: AppColors.onPrimary),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: AppColors.onPrimary,
                          size: 50,
                        ),
                      ),
                    ),
            ),
          ),

          // Gradient Overlay
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

          // Content Overlay
          Positioned(
            left: 16,
            right: 80,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigate to user profile
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surface,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.accent,
                          backgroundImage:
                              widget.reel['profileImageUrl'] != null &&
                                  widget.reel['profileImageUrl']
                                      .toString()
                                      .isNotEmpty
                              ? CachedNetworkImageProvider(
                                  widget.reel['profileImageUrl'],
                                )
                              : null,
                          child:
                              widget.reel['profileImageUrl'] == null ||
                                  widget.reel['profileImageUrl']
                                      .toString()
                                      .isEmpty
                              ? Text(
                                  widget.reel['fullName'].toString().isNotEmpty
                                      ? widget.reel['fullName']
                                            .toString()[0]
                                            .toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: AppColors.onAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.reel['username'] ?? 'unknown',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (widget.reel['isVerified'] == true) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: AppColors.info, size: 16),
                    ],
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: AppColors.onPrimary),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Follow',
                        style: TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Caption
                if (widget.reel['caption'] != null &&
                    widget.reel['caption'].toString().isNotEmpty)
                  Text(
                    widget.reel['caption'],
                    style: const TextStyle(color: AppColors.onPrimary, fontSize: 15),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Music Info
                if (widget.reel['musicName'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.music_note,
                        color: AppColors.onPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.reel['musicName'],
                          style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Side Action Buttons
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
                    final isLiked = (widget.reel['likes'] as List).contains(
                      currentUserId,
                    );

                    return _ActionButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? AppColors.like : AppColors.onPrimary,
                      label: _formatNumber(
                        (widget.reel['likes'] as List).length,
                      ),
                      onTap: () =>
                          widget.onLikeToggle(widget.reel['id'], currentUserId),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.comment_outlined,
                  color: AppColors.onPrimary,
                  label: _formatNumber(widget.reel['comments']?.length ?? 0),
                  onTap: () {
                    // Show comments
                  },
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.send_outlined,
                  color: AppColors.onPrimary,
                  label: _formatNumber(widget.reel['shares'] ?? 0),
                  onTap: () {
                    // Share reel
                  },
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.more_vert,
                  color: AppColors.onPrimary,
                  label: '',
                  onTap: () {
                    // Show more options
                  },
                ),
                const SizedBox(height: 20),
                // Music disc animation
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: widget.reel['profileImageUrl'] != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              widget.reel['profileImageUrl'],
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: widget.reel['profileImageUrl'] == null
                        ? AppColors.accent
                        : null,
                  ),
                  child: widget.reel['profileImageUrl'] == null
                      ? const Icon(
                          Icons.music_note,
                          color: AppColors.onPrimary,
                          size: 20,
                        )
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
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Icon(
                      Icons.favorite,
                      color: AppColors.onPrimary.withOpacity(
                        1.0 - _animationController.value,
                      ),
                      size: 100,
                    ),
                  );
                },
              ),
            ),

          // Bottom info bar
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
                children: [
                  const Icon(
                    Icons.home_outlined,
                    color: AppColors.onPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 24),
                  const Icon(Icons.search, color: AppColors.onPrimary, size: 24),
                  const Spacer(),
                  Text(
                    '${_formatNumber(widget.reel['views'] ?? 0)} views',
                    style: const TextStyle(color: AppColors.onPrimary, fontSize: 12),
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
                  color: AppColors.onPrimary,
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
