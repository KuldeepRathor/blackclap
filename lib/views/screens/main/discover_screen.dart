import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../repositories/mock_data_service.dart';
import '../../../constants/color_constants.dart';
import '../../widgets/user_avatar.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _reels = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _posts = MockDataService.getPosts();
      _reels = MockDataService.getReels();
      _users = MockDataService.getUsers();
      _filteredUsers = _users;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      _filteredUsers =
          query.isEmpty ? _users : MockDataService.searchUsers(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Discover',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_isSearching ? 64 : 108),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search users, posts...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              if (!_isSearching)
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textTertiary,
                  indicatorColor: AppColors.accent,
                  tabs: const [
                    Tab(text: 'Posts'),
                    Tab(text: 'Users'),
                    Tab(text: 'Trending'),
                    Tab(text: 'Reels'),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: _isSearching
          ? _buildSearchResults()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPostsGrid(),
                _buildUsersGrid(),
                _buildTrendingContent(),
                _buildReelsGrid(),
              ],
            ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: UserAvatar(
              imageUrl: user['profileImageUrl'],
              fallbackName: user['fullName'] ?? 'U',
              radius: 24,
            ),
            title: Text(
              user['fullName'] ?? 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${user['username'] ?? 'unknown'}'),
                if (user['bio'] != null && (user['bio'] as String).isNotEmpty)
                  Text(
                    user['bio'],
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: user['isVerified'] == true
                ? const Icon(Icons.verified, color: AppColors.info, size: 20)
                : null,
            onTap: () => context.push('/user/${user['uid']}'),
          ),
        );
      },
    );
  }

  Widget _buildPostsGrid() {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async => _loadData(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];
            final imageUrls = post['imageUrls'] as List<dynamic>;
            if (imageUrls.isEmpty) return const SizedBox.shrink();

            return GestureDetector(
              onTap: () => context.push('/post/${post['id']}'),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrls[0],
                      fit: BoxFit.cover,
                      height: 120 + (index % 3) * 40,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        height: 120,
                        color: AppColors.imagePlaceholder,
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 120,
                        color: AppColors.imagePlaceholder,
                        child: const Icon(Icons.image_not_supported,
                            color: AppColors.neutral400),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['caption'] ?? '',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.favorite,
                                  size: 12, color: AppColors.like),
                              const SizedBox(width: 4),
                              Text(
                                '${(post['likes'] as List).length}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
      ),
    );
  }

  Widget _buildUsersGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return GestureDetector(
          onTap: () => context.push('/user/${user['uid']}'),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UserAvatar(
                    imageUrl: user['profileImageUrl'],
                    fallbackName: user['fullName'] ?? 'U',
                    radius: 30,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user['fullName'] ?? 'Unknown',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${user['username'] ?? 'unknown'}',
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (user['isVerified'] == true)
                    const Icon(Icons.verified, color: AppColors.info, size: 16),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () => context.push('/user/${user['uid']}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        textStyle: const TextStyle(fontSize: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('View Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendingContent() {
    final interests = <String>[];
    for (final user in _users) {
      interests.addAll((user['interests'] as List<dynamic>).cast<String>());
    }

    final trendingMap = <String, int>{};
    for (final interest in interests) {
      trendingMap[interest] = (trendingMap[interest] ?? 0) + 1;
    }

    final trending = trendingMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trending.length,
      itemBuilder: (context, index) {
        final item = trending[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.accent,
              child: Text(
                '#${index + 1}',
                style: const TextStyle(
                  color: AppColors.textOnAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text('#${item.key}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${item.value} users interested'),
            trailing: const Icon(Icons.trending_up, color: AppColors.accent),
          ),
        );
      },
    );
  }

  Widget _buildReelsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 0.6,
      ),
      itemCount: _reels.length,
      itemBuilder: (context, index) {
        final reel = _reels[index];
        return GestureDetector(
          onTap: () => context.push('/reels'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: reel['thumbnailUrl'],
                fit: BoxFit.cover,
                placeholder: (ctx, url) =>
                    Container(color: AppColors.imagePlaceholder),
                errorWidget: (ctx, url, err) => Container(
                  color: AppColors.imagePlaceholder,
                  child: const Icon(Icons.play_circle_outline,
                      size: 40, color: AppColors.neutral400),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.play_arrow,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${reel['views']}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      reel['username'] ?? '',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.videocam, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
