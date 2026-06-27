import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/search/search_bloc.dart';
import '../../../constants/color_constants.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../services/post_api_service.dart';
import '../../widgets/feed_post_card.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchBloc(),
      child: const _DiscoverView(),
    );
  }
}

class _DiscoverView extends StatefulWidget {
  const _DiscoverView();

  @override
  State<_DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<_DiscoverView>
    with TickerProviderStateMixin {
  late TabController _searchTabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _postsScrollController = ScrollController();
  final ScrollController _usersScrollController = ScrollController();

  Timer? _debounceTimer;

  // Browse mode — real feed posts from the API
  List<Map<String, dynamic>> _browsePosts = [];
  bool _browseLoading = true;
  bool _browseError = false;

  @override
  void initState() {
    super.initState();
    _searchTabController = TabController(length: 3, vsync: this);

    _searchTabController.addListener(() {
      if (!_searchTabController.indexIsChanging) {
        context
            .read<SearchBloc>()
            .add(SearchTabChanged(_searchTabController.index));
      }
    });

    _postsScrollController.addListener(_onPostsScroll);
    _usersScrollController.addListener(_onUsersScroll);

    _loadBrowsePosts();
  }

  Future<void> _loadBrowsePosts() async {
    setState(() {
      _browseLoading = true;
      _browseError = false;
    });
    try {
      final posts = await PostApiService(ApiService()).getFeedPosts(limit: 30);
      if (mounted) {
        setState(() {
          _browsePosts = posts;
          _browseLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _browseLoading = false;
          _browseError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchTabController.dispose();
    _searchController.dispose();
    _postsScrollController.dispose();
    _usersScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    final bloc = context.read<SearchBloc>();

    if (value.trim().length < 2) {
      bloc.add(const SearchCleared());
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        bloc.add(SearchQueryChanged(value));
      }
    });
  }

  void _onPostsScroll() {
    final ctrl = _postsScrollController;
    if (ctrl.position.pixels >= ctrl.position.maxScrollExtent - 300) {
      context.read<SearchBloc>().add(const SearchPostsNextPageRequested());
    }
  }

  void _onUsersScroll() {
    final ctrl = _usersScrollController;
    if (ctrl.position.pixels >= ctrl.position.maxScrollExtent - 300) {
      context.read<SearchBloc>().add(const SearchUsersNextPageRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SearchBloc, SearchState>(
      listenWhen: (prev, curr) => curr is SearchLoaded && prev is! SearchLoaded,
      listener: (context, state) {
        if (state is SearchLoaded) {
          // Sync the tab controller to the active tab from BLoC
          if (_searchTabController.index != state.activeTab) {
            _searchTabController.animateTo(state.activeTab);
          }
        }
      },
      child: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          final isSearching = state is! SearchBrowsing;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              title: const Text(
                'Discover',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(isSearching ? 100 : 56),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    if (isSearching)
                      TabBar(
                        controller: _searchTabController,
                        labelColor: AppColors.accent,
                        unselectedLabelColor: AppColors.neutral200,
                        indicatorColor: AppColors.accent,
                        tabs: const [
                          Tab(text: 'All'),
                          Tab(text: 'Users'),
                          Tab(text: 'Posts'),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search users, posts...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<SearchBloc>().add(const SearchCleared());
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
    );
  }

  Widget _buildBody(BuildContext context, SearchState state) {
    return switch (state) {
      SearchBrowsing() => _buildBrowsePostsGrid(),
      SearchLoading() => const Center(child: CircularProgressIndicator()),
      SearchLoaded() => TabBarView(
          controller: _searchTabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildAllTab(state),
            _buildUsersTab(state),
            _buildPostsTab(state),
          ],
        ),
      SearchError(:final message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.neutral300),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.neutral200),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context
                      .read<SearchBloc>()
                      .add(SearchQueryChanged(_searchController.text)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  // ─── Search result tabs ────────────────────────────────────────────────────

  Widget _buildAllTab(SearchLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.users.isNotEmpty) ...[
            _sectionHeader('People', onViewAll: () {
              _searchTabController.animateTo(1);
              context.read<SearchBloc>().add(const SearchTabChanged(1));
            }),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.users.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) =>
                    _buildUserChip(context, state.users[i]),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (state.posts.isNotEmpty) ...[
            _sectionHeader('Posts', onViewAll: () {
              _searchTabController.animateTo(2);
              context.read<SearchBloc>().add(const SearchTabChanged(2));
            }),
            ...state.posts.map(
              (p) => FeedPostCard.fromContext(
                key: ValueKey(p.id),
                context: context,
                post: p.toMap(),
              ),
            ),
          ],
          if (state.users.isEmpty && state.posts.isEmpty)
            _buildEmptyState('No results found'),
        ],
      ),
    );
  }

  Widget _buildUsersTab(SearchLoaded state) {
    if (state.users.isEmpty && !state.isLoadingMore) {
      return _buildEmptyState('No users found');
    }

    return ListView.builder(
      controller: _usersScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.users.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == state.users.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildUserListTile(context, state.users[i]);
      },
    );
  }

  Widget _buildPostsTab(SearchLoaded state) {
    if (state.posts.isEmpty && !state.isLoadingMore) {
      return _buildEmptyState('No posts found');
    }

    return ListView.builder(
      controller: _postsScrollController,
      itemCount: state.posts.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == state.posts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final post = state.posts[i];
        return FeedPostCard.fromContext(
          key: ValueKey(post.id),
          context: context,
          post: post.toMap(),
        );
      },
    );
  }

  // ─── User card components ─────────────────────────────────────────────────

  Widget _buildUserChip(BuildContext context, UserModel user) {
    return GestureDetector(
      onTap: () => context.push('/profile/${user.username}'),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            _buildAvatar(user.profileImageUrl, user.fullName, radius: 28),
            const SizedBox(height: 6),
            Text(
              user.username,
              style: const TextStyle(fontSize: 11, color: AppColors.neutral100),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListTile(BuildContext context, UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.neutral700,
      child: ListTile(
        leading: _buildAvatar(user.profileImageUrl, user.fullName, radius: 20),
        title: Text(
          user.fullName.isNotEmpty ? user.fullName : user.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user.username}',
                style: TextStyle(color: AppColors.neutral200)),
            if (user.bio.isNotEmpty)
              Text(
                user.bio,
                style: TextStyle(color: AppColors.neutral300, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: user.isFollowing
            ? OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.neutral400),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Following',
                    style: TextStyle(color: AppColors.neutral200)),
              )
            : null,
        onTap: () => context.push('/profile/${user.username}'),
      ),
    );
  }

  CircleAvatar _buildAvatar(String imageUrl, String name, {double radius = 20}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accent,
      backgroundImage: imageUrl.isNotEmpty
          ? CachedNetworkImageProvider(imageUrl)
          : null,
      child: imageUrl.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: radius * 0.75,
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            )
          : null,
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.neutral100,
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: const Text(
                'See all',
                style: TextStyle(color: AppColors.accent, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.neutral400),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: AppColors.neutral200),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Browse mode — real posts from feed ───────────────────────────────────

  Widget _buildBrowsePostsGrid() {
    if (_browseLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_browseError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.neutral400),
            const SizedBox(height: 12),
            const Text('Failed to load posts',
                style: TextStyle(color: AppColors.neutral200)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBrowsePosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_browsePosts.isEmpty) {
      return _buildEmptyState('No posts yet');
    }

    // Only show posts that have at least one image
    final imagePosts = _browsePosts.where((p) {
      final media = p['media'] as List<dynamic>? ?? [];
      return media.isNotEmpty &&
          (p['media_type'] == 'image' || p['media_type'] == 'video');
    }).toList();

    if (imagePosts.isEmpty) {
      return _buildEmptyState('No posts yet');
    }

    return RefreshIndicator(
      onRefresh: _loadBrowsePosts,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          itemCount: imagePosts.length,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          itemBuilder: (context, index) {
            final post = imagePosts[index];
            final media = (post['media'] as List<dynamic>).first
                as Map<String, dynamic>;
            final imageUrl = (media['thumbnail_url'] ?? media['media_url'])
                    ?.toString() ??
                '';

            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    height: 120 + (index % 3) * 40.0,
                    width: double.infinity,
                    placeholder: (_, __) => Container(
                      height: 120,
                      color: AppColors.neutral600,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 120,
                      color: AppColors.neutral600,
                      child: const Icon(Icons.image_not_supported,
                          color: AppColors.neutral400),
                    ),
                  ),
                  if ((post['caption'] as String?)?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['caption'] as String,
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
                                '${post['likes_count'] ?? 0}',
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
        ),
      ),
    );
  }
}
