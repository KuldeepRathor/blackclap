import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constants/color_constants.dart';
import '../../../utils/theme_colors.dart';
import '../../../models/post_model.dart';
import '../../../models/user_model.dart';
import '../../../repositories/chat_repository.dart';
import '../../../services/api_service.dart';
import '../../../services/post_api_service.dart';
import 'post_detail_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String username;

  const OtherUserProfileScreen({super.key, required this.username});

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  late final PostApiService _postApiService = PostApiService(_apiService);

  UserModel? _user;
  List<PostModel> _posts = [];
  bool _loading = true;
  bool _postsLoading = true;
  bool _followLoading = false;
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  String _errorMessage = 'User not found';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _apiService.getUserProfile(widget.username);
      if (mounted) {
        final user = UserModel.fromMap(data);
        setState(() {
          _user = user;
          _isFollowing = data['is_following'] as bool? ?? false;
          _followersCount = data['followers_count'] as int? ?? 0;
          _followingCount = data['following_count'] as int? ?? 0;
          _loading = false;
        });
        _loadPosts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _loadPosts() async {
    try {
      final raw = await _postApiService.getUserPostsByUsername(widget.username);
      if (mounted) {
        setState(() {
          _posts = raw.map(PostModel.fromApiResponse).toList();
          _postsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _postsLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);
    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !_isFollowing;
      _followersCount += _isFollowing ? 1 : -1;
    });
    try {
      final Map<String, dynamic> result;
      if (wasFollowing) {
        result = await _apiService.unfollowUser(widget.username);
      } else {
        result = await _apiService.followUser(widget.username);
      }
      if (mounted) {
        setState(() {
          _isFollowing = result['is_following'] as bool? ?? _isFollowing;
          _followersCount = result['followers_count'] as int? ?? _followersCount;
          _followingCount = result['following_count'] as int? ?? _followingCount;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFollowing = wasFollowing;
          _followersCount += wasFollowing ? 1 : -1;
        });
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  void _shareProfile() {
    final link = 'blackclap://profile/${widget.username}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _openingDm = false;

  Future<void> _openDM() async {
    final user = _user;
    if (user == null || _openingDm) return;
    setState(() => _openingDm = true);
    try {
      final conversation =
          await context.read<ChatRepository>().openOrCreateDm(user.uid);
      if (!mounted) return;
      context.push('/chat/${conversation.id}', extra: conversation);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open chat: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingDm = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.username,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.primaryText,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: context.primaryText),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _user == null
              ? _buildError()
              : _buildProfile(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 60, color: context.iconColor),
          const SizedBox(height: 16),
          Text(_errorMessage, style: TextStyle(fontSize: 18, color: context.secondaryText)),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final user = _user!;
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Avatar + stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () => _showAvatarZoom(user),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.accent,
                              backgroundImage: user.profileImageUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(user.profileImageUrl)
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
                          _buildStatColumn(_posts.length.toString(), 'Posts'),
                          _buildStatColumn(
                            _followersCount.toString(),
                            'Followers',
                            onTap: () => context.push(
                                '/follow-list/${widget.username}?tab=0'),
                          ),
                          _buildStatColumn(
                            _followingCount.toString(),
                            'Following',
                            onTap: () => context.push(
                                '/follow-list/${widget.username}?tab=1'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Full name + bio
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (user.fullName.isNotEmpty)
                                Text(
                                  user.fullName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: context.primaryText,
                                  ),
                                ),
                              if (user.bio.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  user.bio,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: context.primaryText,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action buttons: Follow/Following | Message | Share
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildFollowButton(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _openingDm ? null : _openDM,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.iconColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: _openingDm
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: context.primaryText,
                                      ),
                                    )
                                  : Text(
                                      'Message',
                                      style: TextStyle(
                                        color: context.primaryText,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _shareProfile,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.iconColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(44, 40),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            child: Icon(
                              Icons.person_add_alt_1_outlined,
                              color: context.primaryText,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.accent,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: context.iconColor,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.play_arrow_outlined)),
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
          _postsLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _buildPostsGrid(),
          _postsLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _buildReelsGrid(
                  _posts.where((p) => p.mediaType == MediaType.video).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    if (_isFollowing) {
      return OutlinedButton(
        onPressed: _followLoading ? null : _toggleFollow,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.iconColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: _followLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: context.primaryText),
              )
            : Text(
                'Following',
                style: TextStyle(
                  color: context.primaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
      );
    }
    return ElevatedButton(
      onPressed: _followLoading ? null : _toggleFollow,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: _followLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent),
            )
          : const Text(
              'Follow',
              style: TextStyle(
                color: AppColors.onAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.primaryText),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 13, color: context.secondaryText)),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 60, color: context.iconColor),
            const SizedBox(height: 16),
            const Text('No posts yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        final isVideo = post.mediaType == MediaType.video;
        final thumbUrl = isVideo
            ? (post.thumbnailUrls.isNotEmpty ? post.thumbnailUrls[0] : '')
            : (post.imageUrls.isNotEmpty ? post.imageUrls[0] : '');
        final hasMultiple = post.imageUrls.length > 1;

        return GestureDetector(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: context.shimmerBase,
                child: thumbUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumbUrl,
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
            const Text('No reels yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                builder: (_) => PostDetailScreen(post: reel),
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
                        placeholder: (_, __) => Container(color: context.shimmerBase),
                        errorWidget: (_, __, ___) => Container(
                          color: context.shimmerBase,
                          child: Icon(Icons.videocam_off, color: context.iconColor),
                        ),
                      )
                    : Container(
                        color: context.shimmerBase,
                        child: Icon(Icons.play_circle_outline,
                            color: context.iconColor, size: 32),
                      ),
              ),
              // Gradient scrim
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
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
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      _formatViews(reel.viewsCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
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

  void _showAvatarZoom(UserModel user) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
            Center(
              child: user.profileImageUrl.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.profileImageUrl,
                        width: 260,
                        height: 260,
                        fit: BoxFit.cover,
                      ),
                    )
                  : CircleAvatar(
                      radius: 130,
                      backgroundColor: AppColors.accent,
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
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
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share profile'),
              onTap: () {
                Navigator.pop(context);
                _shareProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined, color: AppColors.error),
              title: const Text('Block user', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.error),
              title: const Text('Report', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
