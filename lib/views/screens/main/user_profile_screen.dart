import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../constants/color_constants.dart';
import '../../../repositories/mock_data_service.dart';
import '../../widgets/user_avatar.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _posts = [];
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final user = MockDataService.getUser(widget.userId);
    final authState = context.read<AuthBloc>().state;
    final currentUid = authState is AuthAuthenticated ? authState.user.uid : '';

    setState(() {
      _user = user;
      _posts = MockDataService.getUserPosts(widget.userId);
      if (user != null) {
        final followers = List<String>.from(user['followers'] ?? []);
        _isFollowing = followers.contains(currentUid);
      }
    });
  }

  Future<void> _toggleFollow() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final currentUid = authState.user.uid;

    setState(() => _isLoadingFollow = true);

    if (_isFollowing) {
      await MockDataService.unfollowUser(currentUid, widget.userId);
    } else {
      await MockDataService.followUser(currentUid, widget.userId);
    }

    _loadData();
    setState(() => _isLoadingFollow = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(child: Text('User not found')),
      );
    }

    final user = _user!;
    final authState = context.read<AuthBloc>().state;
    final currentUid = authState is AuthAuthenticated ? authState.user.uid : '';
    final isOwnProfile = widget.userId == currentUid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // AppBar
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    color: AppColors.background,
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => context.pop(),
                          ),
                          Expanded(
                            child: Text(
                              user['username'] ?? 'Profile',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (user['isVerified'] == true)
                            const Icon(Icons.verified,
                                color: AppColors.info, size: 20),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Avatar
                        UserAvatar(
                          imageUrl: user['profileImageUrl'],
                          fallbackName: user['fullName'] ?? 'U',
                          radius: 44,
                        ),
                        const SizedBox(height: 12),

                        // Name
                        Text(
                          user['fullName'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Bio
                        if (user['bio'] != null &&
                            (user['bio'] as String).isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            user['bio'],
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(_posts.length.toString(), 'Posts'),
                            _buildStat(
                              (List<dynamic>.from(user['followers'] ?? []))
                                  .length
                                  .toString(),
                              'Followers',
                            ),
                            _buildStat(
                              (List<dynamic>.from(user['following'] ?? []))
                                  .length
                                  .toString(),
                              'Following',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Action buttons
                        if (!isOwnProfile)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoadingFollow ? null : _toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isFollowing
                                        ? AppColors.surfaceVariant
                                        : AppColors.accent,
                                    foregroundColor: _isFollowing
                                        ? AppColors.onSurface
                                        : AppColors.onAccent,
                                  ),
                                  child: _isLoadingFollow
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Text(
                                          _isFollowing ? 'Following' : 'Follow',
                                        ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      context.push('/chat/${widget.userId}'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: AppColors.neutral300),
                                  ),
                                  child: const Text(
                                    'Message',
                                    style:
                                        TextStyle(color: AppColors.onSurface),
                                  ),
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
                    unselectedLabelColor: AppColors.neutral400,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on)),
                      Tab(icon: Icon(Icons.bookmark_border)),
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
            _buildPostsGrid(),
            const Center(
              child: Text('Saved posts',
                  style: TextStyle(color: AppColors.textTertiary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildPostsGrid() {
    if (_posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined,
                size: 48, color: AppColors.neutral300),
            SizedBox(height: 12),
            Text('No Posts Yet',
                style: TextStyle(color: AppColors.textTertiary)),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        final images = List<dynamic>.from(post['imageUrls'] ?? []);
        final imageUrl = images.isNotEmpty ? images[0] : '';

        return GestureDetector(
          onTap: () => context.push('/post/${post['id']}'),
          child: Container(
            color: AppColors.imagePlaceholder,
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) =>
                        Container(color: AppColors.imagePlaceholder),
                    errorWidget: (ctx, url, err) => const Icon(
                        Icons.image_not_supported,
                        color: AppColors.neutral400),
                  )
                : const Icon(Icons.image, color: AppColors.neutral400),
          ),
        );
      },
    );
  }
}
