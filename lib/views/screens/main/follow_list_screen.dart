import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../config/app_url.dart';
import '../../../constants/color_constants.dart';
import '../../../utils/theme_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/token_storage.dart';

class FollowListScreen extends StatefulWidget {
  final String username;

  /// 0 = Followers tab first, 1 = Following tab first
  final int initialTab;

  const FollowListScreen({
    super.key,
    required this.username,
    this.initialTab = 0,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Per-tab state
  final _followers = <UserModel>[];
  final _following = <UserModel>[];
  bool _followersLoading = true;
  bool _followingLoading = true;
  bool _followersError = false;
  bool _followingError = false;
  bool _followersLoaded = false;
  bool _followingLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(_onTabChanged);
    // Load the initial tab eagerly
    if (widget.initialTab == 0) {
      _loadFollowers();
    } else {
      _loadFollowing();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0 && !_followersLoaded) _loadFollowers();
    if (_tabController.index == 1 && !_followingLoaded) _loadFollowing();
  }

  Future<List<UserModel>> _fetch(String url) async {
    final token = await TokenStorage.getAccessToken();
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = json.decode(response.body) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(UserModel.fromMap)
          .toList();
    }
    throw Exception('Failed to load (${response.statusCode})');
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _followersLoading = true;
      _followersError = false;
    });
    try {
      final list = await _fetch(AppUrl.followers(widget.username));
      if (mounted) {
        setState(() {
          _followers
            ..clear()
            ..addAll(list);
          _followersLoading = false;
          _followersLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _followersLoading = false;
          _followersError = true;
        });
      }
    }
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _followingLoading = true;
      _followingError = false;
    });
    try {
      final list = await _fetch(AppUrl.following(widget.username));
      if (mounted) {
        setState(() {
          _following
            ..clear()
            ..addAll(list);
          _followingLoading = false;
          _followingLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _followingLoading = false;
          _followingError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '@${widget.username}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.primaryText,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: context.secondaryText,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(
            users: _followers,
            loading: _followersLoading,
            error: _followersError,
            onRetry: _loadFollowers,
            emptyMessage: 'No followers yet',
          ),
          _buildList(
            users: _following,
            loading: _followingLoading,
            error: _followingError,
            onRetry: _loadFollowing,
            emptyMessage: 'Not following anyone yet',
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required List<UserModel> users,
    required bool loading,
    required bool error,
    required VoidCallback onRetry,
    required String emptyMessage,
  }) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: context.iconColor),
            const SizedBox(height: 12),
            Text('Failed to load',
                style: TextStyle(color: context.secondaryText)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (users.isEmpty) {
      return Center(
        child: Text(emptyMessage,
            style: TextStyle(color: context.secondaryText)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      itemBuilder: (context, i) => _buildUserTile(users[i]),
    );
  }

  Widget _buildUserTile(UserModel user) {
    return ListTile(
      leading: _avatar(user),
      title: Text(
        user.fullName.isNotEmpty ? user.fullName : user.username,
        style: TextStyle(
            fontWeight: FontWeight.bold, color: context.primaryText),
      ),
      subtitle: Text(
        '@${user.username}',
        style: TextStyle(color: context.secondaryText, fontSize: 13),
      ),
      trailing: user.isFollowing
          ? OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.iconColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Following',
                  style:
                      TextStyle(fontSize: 12, color: context.secondaryText)),
            )
          : null,
      onTap: () => context.push('/profile/${user.username}'),
    );
  }

  CircleAvatar _avatar(UserModel user) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.accent,
      backgroundImage: user.profileImageUrl.isNotEmpty
          ? CachedNetworkImageProvider(user.profileImageUrl)
          : null,
      child: user.profileImageUrl.isEmpty
          ? Text(
              user.fullName.isNotEmpty
                  ? user.fullName[0].toUpperCase()
                  : user.username[0].toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.onAccent),
            )
          : null,
    );
  }
}
