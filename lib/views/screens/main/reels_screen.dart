import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../constants/color_constants.dart';
import '../../../models/post_model.dart';
import '../../../services/api_service.dart';
import '../../../services/post_api_service.dart';
import '../../../services/interaction_api_service.dart';
import '../../../services/video_cache_manager.dart';
import '../../widgets/comments_sheet.dart';
import 'other_user_profile_screen.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  final PostApiService _postApiService = PostApiService(ApiService());
  final InteractionApiService _interactionService = InteractionApiService(ApiService());

  List<PostModel> _reels = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final Map<int, VideoPlayerController> _controllers = {};

  // True only while this screen is actually on screen (tab selected, no route
  // pushed on top). Every play() must go through _canPlay — async video
  // initialization and lifecycle/visibility callbacks can otherwise start
  // audio while the user is on another tab or screen.
  bool _isScreenVisible = true;
  bool _commentsOpen = false;

  bool get _canPlay => mounted && _isScreenVisible && !_commentsOpen;

  void _playCurrent() {
    if (_canPlay) {
      _controllers[_currentIndex]?.play();
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
    _loadReels();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _pauseAll();
    } else if (state == AppLifecycleState.resumed) {
      // Only resume if the reels tab is actually on screen — the app can be
      // backgrounded and resumed while the user is on another tab.
      _playCurrent();
    }
  }

  void _pauseAll() {
    for (final c in _controllers.values) {
      c.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    _controllers.clear();
  }

  Future<void> _loadReels() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasMore = true;
    });
    try {
      final raw = await _postApiService.getReels(limit: 20);
      if (!mounted) return;
      final posts = raw
          .map((m) => PostModel.fromApiResponse(m))
          .where((p) => p.videoUrls.isNotEmpty)
          .toList();
      setState(() {
        _reels = posts;
        _isLoading = false;
      });
      if (_reels.isNotEmpty) {
        _initializeVideo(0);
        _initializeVideo(1);
      }
    } catch (e) {
      debugPrint('Error loading reels: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load reels.\nTap to retry.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshReels() async {
    try {
      final raw = await _postApiService.getReels(limit: 20);
      if (!mounted) return;
      final posts = raw
          .map((m) => PostModel.fromApiResponse(m))
          .where((p) => p.videoUrls.isNotEmpty)
          .toList();
      _pauseAll();
      _disposeControllers();
      setState(() {
        _reels = posts;
        _currentIndex = 0;
        _hasMore = true;
        _error = null;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      if (_reels.isNotEmpty) {
        _initializeVideo(0);
        _initializeVideo(1);
      }
    } catch (e) {
      debugPrint('Error refreshing reels: $e');
    }
  }

  Future<void> _loadMoreReels() async {
    if (_isLoadingMore || !_hasMore || _reels.isEmpty) return;
    setState(() => _isLoadingMore = true);
    try {
      final cursor = _reels.last.createdAt.toUtc().toIso8601String();
      final raw = await _postApiService.getReels(limit: 20, cursor: cursor);
      if (!mounted) return;
      final newPosts = raw
          .map((m) => PostModel.fromApiResponse(m))
          .where((p) => p.videoUrls.isNotEmpty)
          .toList();
      if (newPosts.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
        return;
      }
      setState(() {
        _reels.addAll(newPosts);
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more reels: $e');
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _initializeVideo(int index) async {
    if (_controllers.containsKey(index)) return;
    if (index < 0 || index >= _reels.length) return;

    final videoUrl = _reels[index].videoUrls.first;

    VideoPlayerController controller;
    // Use cached local file if available — instant start, no network round-trip
    final cached = await VideoCacheManager.instance.getFileFromCache(videoUrl);
    if (cached != null) {
      controller = VideoPlayerController.file(cached.file);
    } else {
      controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      // Background-cache this video so the next visit is instant
      // ignore: discarded_futures
      VideoCacheManager.instance.downloadFile(videoUrl);
    }

    _controllers[index] = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      // Re-check visibility after the async gap: the user may have navigated
      // to another tab/screen while the video was buffering.
      if (index == _currentIndex && _canPlay) {
        await controller.play();
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video at index $index: $e');
    }
  }

  void _disposeOutOfRange(int current) {
    final keep = <int>{
      if (current - 1 >= 0) current - 1,
      current,
      if (current + 1 < _reels.length) current + 1,
      if (current + 2 < _reels.length) current + 2,
    };
    final toDispose = _controllers.keys.where((k) => !keep.contains(k)).toList();
    for (final k in toDispose) {
      _controllers[k]?.dispose();
      _controllers.remove(k);
    }
  }

  void _onPageChanged(int index) {
    _controllers[_currentIndex]?.pause();
    setState(() => _currentIndex = index);
    if (_canPlay) {
      _controllers[index]?.play();
    }

    // Preload the next two reels
    for (final next in [index + 1, index + 2]) {
      if (next < _reels.length && !_controllers.containsKey(next)) {
        _initializeVideo(next);
      }
    }

    // Release controllers outside the sliding window [index-1 … index+2]
    _disposeOutOfRange(index);

    // Fetch more reels when 5 away from the end
    if (index >= _reels.length - 5) {
      _loadMoreReels();
    }
  }

  void _onLikeToggle(int index) async {
    final post = _reels[index];
    setState(() {
      _reels[index] = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
    });
    try {
      final result = await _interactionService.toggleLike(post.id);
      if (!mounted) return;
      setState(() {
        _reels[index] = _reels[index].copyWith(
          isLiked: result['is_liked'] as bool? ?? !post.isLiked,
          likesCount: result['likes_count'] as int? ?? _reels[index].likesCount,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reels[index] = post;
      });
    }
  }

  Future<void> _onCommentTap(int index) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    // Pause while comments are open
    _commentsOpen = true;
    _controllers[_currentIndex]?.pause();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Push on the root navigator so the sheet sits above PersistentTabView.
      // The tab navigator strips the keyboard inset (viewInsets.bottom == 0),
      // which would hide the input behind the keyboard; the root keeps it.
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(
        post: _reels[index],
        currentUserId: authState.user.uid,
        currentUserAvatar: authState.user.profileImageUrl,
        currentUsername: authState.user.username,
        onCommentAdded: () {
          if (mounted) {
            setState(() {
              _reels[index] = _reels[index].copyWith(
                commentsCount: _reels[index].commentsCount + 1,
              );
            });
          }
        },
      ),
    );

    // Resume after sheet closes
    _commentsOpen = false;
    _playCurrent();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('reels-screen'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction < 0.1) {
          // Tab switched away or a screen was pushed on top — stop everything
          _isScreenVisible = false;
          _pauseAll();
        } else if (info.visibleFraction > 0.9) {
          // Tab switched back — resume current reel
          _isScreenVisible = true;
          _playCurrent();
        }
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.onPrimary))
          else if (_error != null)
            GestureDetector(
              onTap: _loadReels,
              child: Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.onPrimary, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (_reels.isEmpty)
            const Center(
              child: Text(
                'No reels yet.\nUpload a video to see it here.',
                style: TextStyle(color: AppColors.onPrimary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          else
            RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: Colors.black,
              onRefresh: _refreshReels,
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _reels.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _ReelItem(
                    post: _reels[index],
                    videoController: _controllers[index],
                    onLikeToggle: () => _onLikeToggle(index),
                    onCommentTap: () => _onCommentTap(index),
                    isVisible: index == _currentIndex,
                    canAutoPlay: () => _canPlay,
                  );
                },
              ),
            ),

          // Top bar — dynamic height, no fixed value
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'Reels',
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
                        color: AppColors.onPrimary,
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
      ),
    );
  }
}

class _ReelItem extends StatefulWidget {
  final PostModel post;
  final VideoPlayerController? videoController;
  final VoidCallback onLikeToggle;
  final VoidCallback onCommentTap;
  final bool isVisible;
  final bool Function() canAutoPlay;

  const _ReelItem({
    required this.post,
    this.videoController,
    required this.onLikeToggle,
    required this.onCommentTap,
    required this.isVisible,
    required this.canAutoPlay,
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
  Timer? _tapTimer;

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
  void didUpdateWidget(_ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync _isPlaying when the controller changes (e.g. on page change)
    if (widget.videoController != oldWidget.videoController) {
      _isPlaying = widget.videoController?.value.isPlaying ?? true;
    }
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Wait for the double-tap window before committing to single-tap action.
  // This way double-tap only likes (no pause side-effect from the first tap).
  void _onTap() {
    if (_tapTimer != null && _tapTimer!.isActive) {
      // Second tap arrived within window → double-tap, cancel pending pause
      _tapTimer!.cancel();
      _tapTimer = null;
      _onDoubleTap();
    } else {
      // First tap — wait to see if a second tap follows
      _tapTimer = Timer(const Duration(milliseconds: 270), () {
        _tapTimer = null;
        if (mounted) _togglePlayPause();
      });
    }
  }

  void _onDoubleTap() {
    setState(() => _showHeart = true);
    _animationController.forward().then((_) {
      _animationController.reverse().then((_) {
        if (mounted) setState(() => _showHeart = false);
      });
    });
    if (!widget.post.isLiked) {
      widget.onLikeToggle();
    }
  }

  void _togglePlayPause() {
    if (widget.videoController == null) return;
    setState(() {
      if (_isPlaying) {
        widget.videoController!.pause();
      } else {
        widget.videoController!.play();
      }
      _isPlaying = !_isPlaying;
    });
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
    final post = widget.post;
    final thumbnailUrl = post.thumbnailUrls.isNotEmpty ? post.thumbnailUrls.first : '';

    return VisibilityDetector(
      key: Key('reel-${post.id}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        if (widget.videoController != null && widget.isVisible) {
          // canAutoPlay guards against resuming while the screen is hidden
          // (other tab, pushed route) or the comments sheet is open.
          if (info.visibleFraction > 0.5 && widget.canAutoPlay()) {
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
          // Video / thumbnail
          GestureDetector(
            onTap: _onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: screenSize.width,
              height: screenSize.height,
              color: Colors.black,
              child: widget.videoController != null &&
                      widget.videoController!.value.isInitialized
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: widget.videoController!.value.size.width,
                              height: widget.videoController!.value.size.height,
                              child: VideoPlayer(widget.videoController!),
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: _isPlaying ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 46,
                            ),
                          ),
                        ),
                      ],
                    )
                  : thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          fit: BoxFit.cover,
                          width: screenSize.width,
                          height: screenSize.height,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: AppColors.onPrimary),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.error_outline, color: AppColors.onPrimary, size: 50),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: AppColors.onPrimary),
                        ),
            ),
          ),

          // Gradient overlay — bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: screenSize.height * 0.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // Bottom-left: user info + caption
          Positioned(
            left: 16,
            right: 80,
            bottom: 40,
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OtherUserProfileScreen(username: post.username),
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.accent,
                          backgroundImage: post.profileImageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(post.profileImageUrl)
                              : null,
                          child: post.profileImageUrl.isEmpty
                              ? Text(
                                  post.fullName.isNotEmpty
                                      ? post.fullName[0].toUpperCase()
                                      : post.username.isNotEmpty
                                          ? post.username[0].toUpperCase()
                                          : 'U',
                                  style: const TextStyle(
                                    color: AppColors.onAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OtherUserProfileScreen(username: post.username),
                            ),
                          ),
                          child: Text(
                            post.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (post.caption.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      post.caption,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Right side action buttons
          Positioned(
            right: 10,
            bottom: 40,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(
                    icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? AppColors.like : Colors.white,
                    label: _formatNumber(post.likesCount),
                    onTap: widget.onLikeToggle,
                  ),
                  const SizedBox(height: 22),
                  _ActionButton(
                    icon: Icons.comment_outlined,
                    color: Colors.white,
                    label: _formatNumber(post.commentsCount),
                    onTap: widget.onCommentTap,
                  ),
                  const SizedBox(height: 22),
                  _ActionButton(
                    icon: Icons.send_outlined,
                    color: Colors.white,
                    label: '',
                    onTap: () {},
                  ),
                  const SizedBox(height: 22),
                  _ActionButton(
                    icon: Icons.more_vert,
                    color: Colors.white,
                    label: '',
                    onTap: () {},
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: post.profileImageUrl.isNotEmpty
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(post.profileImageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: post.profileImageUrl.isEmpty ? AppColors.accent : null,
                    ),
                    child: post.profileImageUrl.isEmpty
                        ? const Icon(Icons.music_note, color: Colors.white, size: 18)
                        : null,
                  ),
                ],
              ),
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
                      color: Colors.white.withOpacity(1.0 - _animationController.value),
                      size: 100,
                    ),
                  );
                },
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
        mainAxisSize: MainAxisSize.min,
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
