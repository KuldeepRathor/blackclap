import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../constants/color_constants.dart';
import '../../../models/user_model.dart';
import '../../../repositories/chat_repository.dart';
import '../../../services/api_service.dart';
import '../../../services/search_api_service.dart';
import '../../../utils/theme_colors.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isSearching = false;
  List<UserModel> _results = [];
  String? _error;
  String? _openingDmFor;

  late final SearchApiService _searchApi;
  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    _searchApi = SearchApiService(ApiService());
    final authState = context.read<AuthBloc>().state;
    _currentUserId =
        authState is AuthAuthenticated ? authState.user.uid : '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _isSearching = false;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _search(trimmed),
    );
  }

  Future<void> _search(String query) async {
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final result = await _searchApi.search(query: query, type: 'users');
      if (!mounted) return;
      setState(() {
        _results =
            result.users.where((u) => u.uid != _currentUserId).toList();
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Search failed. Please try again.';
        _isSearching = false;
      });
    }
  }

  Future<void> _openDm(UserModel user) async {
    if (_openingDmFor != null) return;
    setState(() => _openingDmFor = user.uid);
    try {
      final conv =
          await context.read<ChatRepository>().openOrCreateDm(user.uid);
      if (!mounted) return;
      context.pushReplacement('/chat/${conv.id}', extra: conv);
    } catch (_) {
      if (!mounted) return;
      setState(() => _openingDmFor = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open conversation. Try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Message',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.primaryText,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onQueryChanged,
              style: TextStyle(color: context.primaryText),
              decoration: InputDecoration(
                hintText: 'Search people…',
                hintStyle: TextStyle(color: context.mutedText),
                prefixIcon: Icon(
                  Icons.search,
                  color: context.mutedText,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: context.mutedText,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_outlined,
                size: 72, color: context.iconColor),
            const SizedBox(height: 16),
            Text(
              'Search for people to message',
              style: TextStyle(color: context.mutedText, fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.error, size: 40),
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: context.secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _search(query),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No people found',
          style: TextStyle(color: context.mutedText, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final user = _results[index];
        final isOpening = _openingDmFor == user.uid;

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: context.shimmerBase,
            backgroundImage: user.profileImageUrl.isNotEmpty
                ? CachedNetworkImageProvider(user.profileImageUrl)
                : null,
            child: user.profileImageUrl.isEmpty
                ? Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.onAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Text(
            user.username,
            style: TextStyle(
              color: context.primaryText,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: user.fullName.isNotEmpty
              ? Text(
                  user.fullName,
                  style: TextStyle(color: context.mutedText, fontSize: 13),
                )
              : null,
          trailing: isOpening
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                )
              : Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: context.iconColor,
                ),
          onTap: isOpening ? null : () => _openDm(user),
        );
      },
    );
  }
}
