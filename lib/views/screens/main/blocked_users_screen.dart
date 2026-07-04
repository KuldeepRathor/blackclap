import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../constants/color_constants.dart';
import '../../../utils/theme_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/moderation_api_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late final ModerationApiService _service = ModerationApiService(ApiService());

  List<Map<String, dynamic>> _blocked = [];
  bool _loading = true;
  bool _error = false;
  final Set<String> _unblocking = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final list = await _service.getBlockedUsers();
      if (!mounted) return;
      setState(() {
        _blocked = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _unblock(Map<String, dynamic> user) async {
    final username = user['username'] as String? ?? '';
    if (username.isEmpty || _unblocking.contains(username)) return;
    setState(() => _unblocking.add(username));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.unblockUser(username);
      if (!mounted) return;
      setState(() {
        _blocked.removeWhere((u) => u['username'] == username);
        _unblocking.remove(username);
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('Unblocked @$username'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _unblocking.remove(username));
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blocked Accounts',
          style: TextStyle(fontWeight: FontWeight.bold, color: context.primaryText),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.iconColor),
            const SizedBox(height: 12),
            Text('Failed to load', style: TextStyle(color: context.secondaryText)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_blocked.isEmpty) {
      return Center(
        child: Text(
          'You haven\'t blocked anyone',
          style: TextStyle(color: context.secondaryText),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _blocked.length,
      itemBuilder: (context, i) => _buildTile(_blocked[i]),
    );
  }

  Widget _buildTile(Map<String, dynamic> user) {
    final username = user['username'] as String? ?? '';
    final displayName = user['display_name'] as String?;
    final avatarUrl = user['avatar_url'] as String?;
    final isUnblocking = _unblocking.contains(username);

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.accent,
        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? CachedNetworkImageProvider(avatarUrl)
            : null,
        child: (avatarUrl == null || avatarUrl.isEmpty)
            ? Text(
                (displayName?.isNotEmpty == true ? displayName! : username)
                    .substring(0, 1)
                    .toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.onAccent),
              )
            : null,
      ),
      title: Text(
        displayName?.isNotEmpty == true ? displayName! : username,
        style: TextStyle(fontWeight: FontWeight.bold, color: context.primaryText),
      ),
      subtitle: Text('@$username', style: TextStyle(color: context.secondaryText, fontSize: 13)),
      trailing: OutlinedButton(
        onPressed: isUnblocking ? null : () => _unblock(user),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.iconColor),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: isUnblocking
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text('Unblock', style: TextStyle(fontSize: 12, color: context.secondaryText)),
      ),
    );
  }
}
