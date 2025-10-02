import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../repositories/mock_data_service.dart';
import '../../../constants/color_constants.dart';

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
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      _users = MockDataService.getUsers();
      _filteredUsers = _users;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = MockDataService.searchUsers(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Discover',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search users, posts, or interests...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
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
                    fillColor: AppColors.neutral600,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Tabs
              if (!_isSearching)
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.neutral200,
                  indicatorColor: AppColors.accent,
                  tabs: const [
                    Tab(text: 'Posts'),
                    Tab(text: 'Users'),
                    Tab(text: 'Trending'),
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
            leading: CircleAvatar(
              backgroundColor: AppColors.accent,
              backgroundImage:
                  user['profileImageUrl'] != null &&
                      user['profileImageUrl'].toString().isNotEmpty
                  ? CachedNetworkImageProvider(user['profileImageUrl'])
                  : null,
              child:
                  user['profileImageUrl'] == null ||
                      user['profileImageUrl'].toString().isEmpty
                  ? Text(
                      user['fullName'].toString().isNotEmpty
                          ? user['fullName'].toString()[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.surface,
                      ),
                    )
                  : null,
            ),
            title: Text(
              user['fullName'] ?? 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${user['username'] ?? 'unknown'}'),
                if (user['bio'] != null && user['bio'].toString().isNotEmpty)
                  Text(
                    user['bio'],
                    style: TextStyle(color: AppColors.neutral200),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: user['isVerified'] == true
                ? const Icon(Icons.verified, color: AppColors.info, size: 20)
                : null,
            onTap: () {
              // Navigate to user profile
            },
          ),
        );
      },
    );
  }

  Widget _buildPostsGrid() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          final imageUrls = post['imageUrls'] as List<dynamic>;

          if (imageUrls.isEmpty) return const SizedBox();

          return Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrls[0],
                  fit: BoxFit.cover,
                  height: 120 + (index % 3) * 40, // Varied heights for masonry
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    height: 120,
                    color: AppColors.neutral600,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 120,
                    color: AppColors.neutral600,
                    child: const Icon(Icons.image_not_supported),
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
                          Icon(Icons.favorite, size: 12, color: AppColors.like),
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
          );
        },
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
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
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.accent,
                  backgroundImage:
                      user['profileImageUrl'] != null &&
                          user['profileImageUrl'].toString().isNotEmpty
                      ? CachedNetworkImageProvider(user['profileImageUrl'])
                      : null,
                  child:
                      user['profileImageUrl'] == null ||
                          user['profileImageUrl'].toString().isEmpty
                      ? Text(
                          user['fullName'].toString().isNotEmpty
                              ? user['fullName'].toString()[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.surface,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user['fullName'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${user['username'] ?? 'unknown'}',
                  style: TextStyle(color: AppColors.neutral200, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (user['isVerified'] == true)
                      const Icon(
                        Icons.verified,
                        color: AppColors.info,
                        size: 16,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      '${(user['followers'] as List).length} followers',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.neutral200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: () {
                      // Follow user action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.surface,
                      textStyle: const TextStyle(fontSize: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Follow'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendingContent() {
    // Create trending topics based on user interests
    final interests = <String>[];
    for (final user in _users) {
      final userInterests = user['interests'] as List<dynamic>;
      interests.addAll(userInterests.cast<String>());
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
                  color: AppColors.surface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              '#${item.key}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${item.value} users interested'),
            trailing: const Icon(Icons.trending_up, color: AppColors.accent),
            onTap: () {
              // Show posts related to this trending topic
            },
          ),
        );
      },
    );
  }
}
