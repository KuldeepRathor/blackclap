import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/chat/conversations_bloc.dart';
import '../../../constants/color_constants.dart';
import '../../../utils/theme_colors.dart';
import '../../widgets/conversation_tile.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.uid : '';
    // ConversationsBloc is provided by MainNavigationWrapper — no local BlocProvider needed.
    return _MessagesView(currentUserId: currentUserId);
  }
}

class _MessagesView extends StatefulWidget {
  final String currentUserId;

  const _MessagesView({required this.currentUserId});

  @override
  State<_MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<_MessagesView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context
          .read<ConversationsBloc>()
          .add(const ConversationsMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocBuilder<ConversationsBloc, ConversationsState>(
        builder: (context, state) {
          if (state is ConversationsInitial || state is ConversationsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (state is ConversationsError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<ConversationsBloc>()
                  .add(const ConversationsLoadRequested()),
            );
          }

          final loaded = state as ConversationsLoaded;

          return RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              context
                  .read<ConversationsBloc>()
                  .add(const ConversationsRefreshRequested());
              // Give the bloc time to fetch before the indicator hides.
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: loaded.conversations.isEmpty
                ? _EmptyView(
                    onNewMessage: () => context.push('/new-message'),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: loaded.conversations.length +
                        (loaded.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: context.dividerColor,
                      indent: 76,
                    ),
                    itemBuilder: (context, index) {
                      if (index == loaded.conversations.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        );
                      }
                      final conv = loaded.conversations[index];
                      return ConversationTile(
                        conversation: conv,
                        currentUserId: widget.currentUserId,
                        onTap: () => context.push(
                          '/chat/${conv.id}',
                          extra: conv,
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Messages',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: context.primaryText,
          fontSize: 20,
        ),
      ),
      actions: [
        BlocBuilder<ConversationsBloc, ConversationsState>(
          buildWhen: (a, b) {
            final ua = a is ConversationsLoaded ? a.totalUnread : 0;
            final ub = b is ConversationsLoaded ? b.totalUnread : 0;
            return ua != ub;
          },
          builder: (context, state) {
            final total =
                state is ConversationsLoaded ? state.totalUnread : 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'New message',
                  icon: Icon(
                    Icons.edit_square,
                    color: context.primaryText,
                  ),
                  onPressed: () async {
                    await context.push('/new-message');
                    // Refresh list in case a brand-new conversation was opened.
                    if (context.mounted) {
                      context
                          .read<ConversationsBloc>()
                          .add(const ConversationsRefreshRequested());
                    }
                  },
                ),
                if (total > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        total > 99 ? '99+' : '$total',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.onAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onNewMessage;

  const _EmptyView({required this.onNewMessage});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Icon(
          Icons.forum_outlined,
          size: 80,
          color: context.iconColor,
        ),
        const SizedBox(height: 20),
        Text(
          'Your Messages',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'Send private messages to a friend',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.mutedText, fontSize: 14),
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: ElevatedButton.icon(
            onPressed: onNewMessage,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Send message'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
