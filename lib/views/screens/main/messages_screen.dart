import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../constants/color_constants.dart';
import '../../../repositories/mock_data_service.dart';
import '../../widgets/user_avatar.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadConversations() {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthAuthenticated ? authState.user.uid : 'user1';
    setState(() {
      _conversations = MockDataService.getConversations(uid);
      _filtered = List.from(_conversations);
    });
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = List.from(_conversations));
      return;
    }
    setState(() {
      _filtered = _conversations.where((c) {
        final name = (c['partnerName'] ?? '').toString().toLowerCase();
        final uname = (c['partnerUsername'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase()) ||
            uname.contains(query.toLowerCase());
      }).toList();
    });
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(now, dt)) {
      return DateFormat('h:mm a').format(dt);
    } else if (now.difference(dt).inDays < 7) {
      return DateFormat('EEE').format(dt);
    }
    return DateFormat('MM/dd').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search messages',
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
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Conversations list
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: AppColors.neutral300),
                        SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                              color: AppColors.textTertiary, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: () async => _loadConversations(),
                    child: ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final conv = _filtered[index];
                        final partnerId = conv['partnerId'] ?? '';
                        final partnerName = conv['partnerName'] ?? 'Unknown';
                        final partnerImageUrl = conv['partnerImageUrl'] ?? '';
                        final lastMessage = conv['message'] ?? '';
                        final createdAt = conv['createdAt'] as DateTime;
                        final isUnread = !(conv['isRead'] as bool? ?? true);
                        final isFromMe = conv['senderId'] ==
                            (context.read<AuthBloc>().state is AuthAuthenticated
                                ? (context.read<AuthBloc>().state
                                        as AuthAuthenticated)
                                    .user
                                    .uid
                                : '');

                        return Dismissible(
                          key: Key(partnerId),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: AppColors.error,
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            setState(() => _filtered.removeAt(index));
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: UserAvatar(
                              imageUrl: partnerImageUrl,
                              fallbackName: partnerName,
                              radius: 28,
                            ),
                            title: Text(
                              partnerName,
                              style: TextStyle(
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: AppColors.onSurface,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                if (isFromMe)
                                  const Text(
                                    'You: ',
                                    style: TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 13),
                                  ),
                                Expanded(
                                  child: Text(
                                    lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isUnread
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isUnread
                                          ? AppColors.onSurface
                                          : AppColors.textTertiary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTime(createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isUnread
                                        ? AppColors.accent
                                        : AppColors.textTertiary,
                                  ),
                                ),
                                if (isUnread) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            onTap: () {
                              context.push('/chat/$partnerId');
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
