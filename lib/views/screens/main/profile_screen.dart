import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../models/post_model.dart';
import '../../../repositories/post_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/api_service.dart';
import '../../../services/post_api_service.dart';
import '../../../constants/color_constants.dart';
import '../../../utils/theme_colors.dart';
import '../../widgets/feed_post_card.dart';
import 'post_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<PostModel> _userPosts = [];
  List<Map<String, dynamic>> _savedPosts = [];
  List<PostModel> _taggedPosts = [];
  bool _postsLoading = false;
  bool _savedLoading = false;
  bool _taggedLoading = false;

  final PostApiService _postApiService = PostApiService(ApiService());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserContent());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 2 && _taggedPosts.isEmpty && !_taggedLoading) {
      _loadTaggedPosts();
    }
    if (_tabController.index == 3 && _savedPosts.isEmpty && !_savedLoading) {
      _loadSavedPosts();
    }
  }

  Future<void> _loadTaggedPosts() async {
    if (!mounted) return;
    setState(() => _taggedLoading = true);
    try {
      final raw = await _postApiService.getTaggedPosts();
      if (mounted) {
        setState(() => _taggedPosts =
            raw.map((m) => PostModel.fromApiResponse(m)).toList());
      }
    } catch (_) {
      if (mounted) setState(() => _taggedPosts = []);
    } finally {
      if (mounted) setState(() => _taggedLoading = false);
    }
  }

  Future<void> _loadSavedPosts() async {
    if (!mounted) return;
    setState(() => _savedLoading = true);
    try {
      final raw = await _postApiService.getSavedPosts();
      if (mounted) {
        setState(() => _savedPosts = raw);
      }
    } catch (_) {
      if (mounted) setState(() => _savedPosts = []);
    } finally {
      if (mounted) setState(() => _savedLoading = false);
    }
  }

  Future<void> _refresh() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final userRepository = context.read<UserRepository>();
    final postRepository = context.read<PostRepository>();
    final authBloc = context.read<AuthBloc>();

    try {
      final user = await userRepository.getProfile();
      if (user != null && mounted) {
        authBloc.add(AuthUserChanged(user: user));
      }
    } catch (_) {}

    try {
      final posts = await postRepository.getUserPosts(authState.user.uid);
      if (mounted) setState(() => _userPosts = posts);
    } catch (_) {
      if (mounted) setState(() => _userPosts = []);
    }

    if (_tabController.index == 2) {
      setState(() => _taggedPosts = []);
      await _loadTaggedPosts();
    }
    if (_tabController.index == 3) {
      setState(() => _savedPosts = <Map<String, dynamic>>[]);
      await _loadSavedPosts();
    }
  }

  void _loadUserContent() async {
    final authState = context.read<AuthBloc>().state;
    final userRepository = context.read<UserRepository>();
    final postRepository = context.read<PostRepository>();
    if (authState is AuthAuthenticated) {
      setState(() => _postsLoading = true);

      // Fetch real posts from backend
      try {
        final posts = await postRepository.getUserPosts(authState.user.uid);
        if (mounted) setState(() => _userPosts = posts);
      } catch (_) {
        // Fall back to empty on error
        if (mounted) setState(() => _userPosts = []);
      } finally {
        if (mounted) setState(() => _postsLoading = false);
      }

      // Fetch the latest profile data from the backend
      try {
        await userRepository.getProfile();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return Text(
                state.user.username,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              );
            }
            return const Text('Profile');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_box_outlined, color: context.primaryText),
            onPressed: () => context.push('/create-post'),
          ),
          IconButton(
            icon: Icon(Icons.menu, color: context.primaryText),
            onPressed: () {
              // Show menu
              _showProfileMenu(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.accent,
              notificationPredicate: (notification) => notification.depth == 2,
              child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Profile Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Profile Image and Stats
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Profile Image
                                  GestureDetector(
                                    onTap: () => _showProfileImageZoom(
                                      context,
                                      user.profileImageUrl,
                                      user.fullName,
                                    ),
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: AppColors.accent,
                                      backgroundImage:
                                          user.profileImageUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              user.profileImageUrl,
                                            )
                                          : null,
                                      child: user.profileImageUrl.isEmpty
                                          ? Text(
                                              user.fullName.isNotEmpty
                                                  ? user.fullName[0].toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.onAccent,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  // Stats
                                  _buildStatColumn(
                                    (user.postsCount ?? user.posts.length).toString(),
                                    'Posts',
                                  ),
                                  _buildStatColumn(
                                    (user.followersCount ?? user.followers.length).toString(),
                                    'Followers',
                                    onTap: () => context.push(
                                        '/follow-list/${user.username}?tab=0'),
                                  ),
                                  _buildStatColumn(
                                    (user.followingCount ?? user.following.length).toString(),
                                    'Following',
                                    onTap: () => context.push(
                                        '/follow-list/${user.username}?tab=1'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Name and Bio
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (user.bio.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        user.bio,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                    if (user.interests.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: user.interests
                                            .map(
                                              (interest) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: context.dividerColor,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  interest,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Edit Profile and Share Profile Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        context.push('/edit-profile');
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: context.iconColor,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Edit profile',
                                        style: TextStyle(
                                          color: context.primaryText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // Share profile
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: context.iconColor,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Share profile',
                                        style: TextStyle(
                                          color: context.primaryText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Tab Bar
                        TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.accent,
                          labelColor: AppColors.accent,
                          unselectedLabelColor: AppColors.neutral400,
                          tabs: const [
                            Tab(icon: Icon(Icons.grid_on)),
                            Tab(
                              icon: Icon(
                                Icons.play_arrow_outlined,
                              ),
                            ),
                            Tab(
                              icon: Icon(
                                Icons.person_pin_outlined,
                              ),
                            ),
                            Tab(
                              icon: Icon(
                                Icons.bookmark_border,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Posts Grid
                  _postsLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildPostsGrid(_userPosts),
                  // Reels Grid
                  _postsLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildReelsGrid(
                          _userPosts
                              .where((p) => p.mediaType == MediaType.video)
                              .toList(),
                        ),
                  // Tagged Grid
                  _taggedLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildTaggedGrid(_taggedPosts),
                  // Saved Grid
                  _savedLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildSavedGrid(_savedPosts),
                ],
              ),
            ),   // closes NestedScrollView
          );     // closes RefreshIndicator
          }

          return const Center(
            child: Text('Please log in to view your profile'),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String count, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 14, color: context.secondaryText)),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(List<PostModel> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 60, color: context.iconColor),
            const SizedBox(height: 16),
            const Text(
              'No Posts Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'When you share photos, they will appear on your profile.',
              style: TextStyle(color: context.secondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final isVideo = post.mediaType == MediaType.video;
        final thumbnailUrl = isVideo
            ? (post.thumbnailUrls.isNotEmpty ? post.thumbnailUrls[0] : '')
            : (post.imageUrls.isNotEmpty ? post.imageUrls[0] : '');
        final hasMultiple = post.imageUrls.length > 1;

        return GestureDetector(
          onTap: () async {
            final deleted = await Navigator.of(context, rootNavigator: true).push<bool>(
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(
                  post: post,
                  onLikeChanged: (isLiked, likesCount) {
                    setState(() {
                      final idx = _userPosts.indexWhere((p) => p.id == post.id);
                      if (idx != -1) {
                        _userPosts[idx] = _userPosts[idx].copyWith(
                          isLiked: isLiked,
                          likesCount: likesCount,
                        );
                      }
                    });
                  },
                ),
              ),
            );
            if (deleted == true && mounted) {
              setState(() => _userPosts.removeWhere((p) => p.id == post.id));
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: context.shimmerBase,
                child: thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: context.shimmerBase,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: context.shimmerBase,
                          child: Icon(
                            isVideo ? Icons.videocam_off : Icons.image_not_supported,
                            color: context.iconColor,
                          ),
                        ),
                      )
                    : Container(
                        color: context.shimmerHighlight,
                        child: Icon(
                          isVideo ? Icons.play_circle_outline : Icons.image,
                          color: context.iconColor,
                          size: 32,
                        ),
                      ),
              ),
              if (isVideo)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 18),
                ),
              if (!isVideo && hasMultiple)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.collections, color: Colors.white, size: 16),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReelsGrid(List<PostModel> reels) {
    if (reels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 60, color: context.iconColor),
            const SizedBox(height: 16),
            const Text(
              'No Reels Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your video posts will appear here.',
              style: TextStyle(color: context.secondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: reels.length,
      itemBuilder: (context, index) {
        final reel = reels[index];
        final thumbnailUrl = reel.thumbnailUrls.isNotEmpty
            ? reel.thumbnailUrls[0]
            : (reel.videoUrls.isNotEmpty ? reel.videoUrls[0] : '');

        return GestureDetector(
          onTap: () {
            _postApiService.recordView(reel.id);
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(
                  post: reel,
                  onLikeChanged: (isLiked, likesCount) {
                    setState(() {
                      final idx = _userPosts.indexWhere((p) => p.id == reel.id);
                      if (idx != -1) {
                        _userPosts[idx] = _userPosts[idx].copyWith(
                          isLiked: isLiked,
                          likesCount: likesCount,
                        );
                      }
                    });
                  },
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black,
                child: thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: context.shimmerBase),
                        errorWidget: (_, __, ___) => Container(
                          color: context.shimmerBase,
                          child: Icon(Icons.videocam_off,
                              color: context.iconColor),
                        ),
                      )
                    : Container(
                        color: context.shimmerBase,
                        child: Icon(Icons.play_circle_outline,
                            color: context.iconColor, size: 32),
                      ),
              ),
              // Gradient scrim at bottom for readability
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 40,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),
              ),
              // Views count
              Positioned(
                bottom: 5,
                left: 5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      _formatViews(reel.viewsCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black54),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatViews(int count) {
    if (count >= 1000000) {
      final m = count / 1000000;
      return '${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      final k = count / 1000;
      return '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildTaggedGrid(List<PostModel> tagged) {
    if (tagged.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_pin_outlined, size: 60, color: context.iconColor),
            const SizedBox(height: 16),
            const Text(
              'Photos of you',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'When people tag you in photos, they\'ll appear here.',
              style: TextStyle(color: context.secondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: tagged.length,
      itemBuilder: (context, index) {
        final post = tagged[index];
        final isVideo = post.mediaType == MediaType.video;
        final thumbnailUrl = isVideo
            ? (post.thumbnailUrls.isNotEmpty ? post.thumbnailUrls[0] : '')
            : (post.imageUrls.isNotEmpty ? post.imageUrls[0] : '');

        return GestureDetector(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(
                  post: post,
                  onLikeChanged: (isLiked, likesCount) {
                    setState(() {
                      final idx = _taggedPosts.indexWhere((p) => p.id == post.id);
                      if (idx != -1) {
                        _taggedPosts[idx] = _taggedPosts[idx].copyWith(
                          isLiked: isLiked,
                          likesCount: likesCount,
                        );
                      }
                    });
                  },
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: context.shimmerBase,
                child: thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                            color: context.shimmerBase),
                        errorWidget: (context, url, error) => Container(
                          color: context.shimmerBase,
                          child: Icon(
                            isVideo ? Icons.videocam_off : Icons.image_not_supported,
                            color: context.iconColor,
                          ),
                        ),
                      )
                    : Container(
                        color: context.shimmerHighlight,
                        child: Icon(
                          isVideo ? Icons.play_circle_outline : Icons.image,
                          color: context.iconColor,
                          size: 32,
                        ),
                      ),
              ),
              if (isVideo)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 18),
                ),
              const Positioned(
                bottom: 6,
                left: 6,
                child: Icon(Icons.person_pin, color: Colors.white70, size: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedGrid(List<Map<String, dynamic>> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 60, color: context.iconColor),
            const SizedBox(height: 16),
            const Text(
              'Saved',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Save photos and videos that you want to see again.',
              style: TextStyle(color: context.secondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final mediaTypeStr = post['media_type'] as String? ?? 'image';
        final isVideo = mediaTypeStr == 'video';
        final media = (post['media'] as List? ?? []);
        final thumbnailUrl = media.isNotEmpty
            ? (media[0]['thumbnail_url'] as String? ??
               (isVideo ? '' : media[0]['media_url'] as String? ?? ''))
            : '';

        return GestureDetector(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => _SavedPostDetailScreen(post: post),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: context.shimmerBase,
                child: thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: context.shimmerBase),
                        errorWidget: (_, __, ___) => Container(
                          color: context.shimmerBase,
                          child: Icon(
                            isVideo ? Icons.videocam_off : Icons.image_not_supported,
                            color: context.iconColor,
                          ),
                        ),
                      )
                    : Container(
                        color: context.shimmerHighlight,
                        child: Icon(
                          isVideo ? Icons.play_circle_outline : Icons.image,
                          color: context.iconColor,
                          size: 32,
                        ),
                      ),
              ),
              if (isVideo)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 18),
                ),
              const Positioned(
                top: 6,
                left: 6,
                child: Icon(Icons.bookmark, color: Colors.white, size: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProfileImageZoom(
    BuildContext context,
    String imageUrl,
    String fullName,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.black.withValues(alpha: 0.6)),
              ),
              Center(
                child: imageUrl.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 260,
                          height: 260,
                          fit: BoxFit.cover,
                        ),
                      )
                    : CircleAvatar(
                        radius: 130,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 100,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onAccent,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.neutral600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_outline),
                title: const Text('Saved'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to saved posts
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('Your activity'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to activity
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Archive'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to archive
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('QR code'),
                onTap: () {
                  Navigator.pop(context);
                  // Show QR code
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text(
                  'Log out',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Saved post detail screen using the unified FeedPostCard ──────────────────

class _SavedPostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;
  const _SavedPostDetailScreen({required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Post',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final currentUserId =
              authState is AuthAuthenticated ? authState.user.uid : '';
          final currentUsername =
              authState is AuthAuthenticated ? authState.user.username : '';
          final currentAvatar =
              authState is AuthAuthenticated ? authState.user.profileImageUrl : '';

          return SingleChildScrollView(
            child: FeedPostCard(
              post: _normalizePostMap(post),
              currentUserId: currentUserId,
              currentUsername: currentUsername,
              currentAvatar: currentAvatar,
            ),
          );
        },
      ),
    );
  }

  /// Converts the backend FeedPostResponse map to the field names FeedPostCard expects.
  Map<String, dynamic> _normalizePostMap(Map<String, dynamic> raw) {
    final media = (raw['media'] as List? ?? []);
    final mediaTypeStr = raw['media_type'] as String? ?? 'image';
    final imageUrls = media
        .where((m) => m['media_type'] == 'image')
        .map<String>((m) => m['media_url'] as String)
        .toList();
    final videoUrls = media
        .where((m) => m['media_type'] == 'video')
        .map<String>((m) => m['media_url'] as String)
        .toList();
    final thumbnailUrls = media
        .map((m) => m['thumbnail_url'] as String?)
        .where((t) => t != null && t.isNotEmpty)
        .cast<String>()
        .toList();

    return {
      ...raw,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'thumbnailUrls': thumbnailUrls,
      'mediaType': mediaTypeStr,
      'createdAt': DateTime.tryParse(raw['created_at'] as String? ?? '') ?? DateTime.now(),
    };
  }
}
