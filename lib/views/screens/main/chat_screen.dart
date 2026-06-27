import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/chat/chat_bloc.dart';
import '../../../constants/color_constants.dart';
import '../../../models/conversation_model.dart';
import '../../../repositories/chat_repository.dart';
import '../../../utils/theme_colors.dart';
import '../../widgets/message_bubble.dart';

class ChatScreen extends StatelessWidget {
  final String conversationId;
  final ConversationModel? conversation;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.uid : '';

    return BlocProvider<ChatBloc>(
      create: (ctx) => ChatBloc(
        repository: ctx.read<ChatRepository>(),
        conversationId: conversationId,
        currentUserId: currentUserId,
      )..add(const ChatHistoryLoadRequested()),
      child: _ChatView(
        conversation: conversation,
        currentUserId: currentUserId,
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final ConversationModel? conversation;
  final String currentUserId;

  const _ChatView({required this.conversation, required this.currentUserId});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  Timer? _typingTimer;
  bool _typingSent = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    // Idempotent — connect in case we arrived before the app-level connect ran.
    context.read<ChatRepository>().connectSocket();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // In a reverse list, maxScrollExtent is the top (oldest messages).
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      context.read<ChatBloc>().add(const ChatOlderMessagesRequested());
    }
  }

  void _onTextChanged(String value) {
    final bloc = context.read<ChatBloc>();
    if (!_typingSent) {
      _typingSent = true;
      bloc.add(const ChatTypingChanged(true));
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _typingSent = false;
      bloc.add(const ChatTypingChanged(false));
    });
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(ChatMessageSent(text));
    _textController.clear();
    _typingTimer?.cancel();
    if (_typingSent) {
      _typingSent = false;
      context.read<ChatBloc>().add(const ChatTypingChanged(false));
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    // Bottom is offset 0 in a reverse ListView.
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  String get _title =>
      widget.conversation?.displayName(widget.currentUserId) ?? 'Chat';

  String get _avatarUrl =>
      widget.conversation?.displayAvatar(widget.currentUserId) ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accent,
              backgroundImage:
                  _avatarUrl.isNotEmpty ? CachedNetworkImageProvider(_avatarUrl) : null,
              child: _avatarUrl.isEmpty
                  ? Text(
                      _title.isNotEmpty ? _title[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.onAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (a, b) => a.runtimeType != b.runtimeType ||
                    (a is ChatLoaded &&
                        b is ChatLoaded &&
                        (a.otherTyping != b.otherTyping ||
                            a.isOtherOnline != b.isOtherOnline)),
                builder: (context, state) {
                  final typing = state is ChatLoaded && state.otherTyping;
                  final online = state is ChatLoaded && state.isOtherOnline;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (typing)
                        const Text(
                          'typing…',
                          style: TextStyle(color: AppColors.accent, fontSize: 12),
                        )
                      else if (online)
                        const Text(
                          'Online',
                          style: TextStyle(color: AppColors.accent, fontSize: 12),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listenWhen: (a, b) => b is ChatLoaded,
              listener: (context, state) {
                if (state is! ChatLoaded) return;
                final count = state.messages.length;
                // Auto-scroll to newest when a message is appended and the user
                // is already near the bottom (don't yank them out of history).
                final nearBottom = !_scrollController.hasClients ||
                    _scrollController.position.pixels <= 160;
                if (count > _lastMessageCount && nearBottom) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                }
                _lastMessageCount = count;
              },
              builder: (context, state) {
                if (state is ChatLoading || state is ChatInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                if (state is ChatError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 48),
                          const SizedBox(height: 12),
                          Text(state.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: context.secondaryText)),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context
                                .read<ChatBloc>()
                                .add(const ChatHistoryLoadRequested()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final loaded = state as ChatLoaded;
                if (loaded.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hi 👋',
                      style: TextStyle(color: context.secondaryText, fontSize: 16),
                    ),
                  );
                }
                final messages = loaded.messages;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length + (loaded.isLoadingOlder ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (loaded.isLoadingOlder && index == messages.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.accent),
                          ),
                        ),
                      );
                    }
                    // Reverse mapping: newest (last) at index 0 (bottom).
                    final msg = messages[messages.length - 1 - index];
                    return MessageBubble(
                      message: msg,
                      isMine: msg.isMine(widget.currentUserId),
                      onRetry: () => context
                          .read<ChatBloc>()
                          .add(ChatMessageRetryRequested(msg.clientId)),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onChanged: _onTextChanged,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                style: TextStyle(color: context.primaryText),
                decoration: InputDecoration(
                  hintText: 'Message…',
                  hintStyle: TextStyle(color: context.mutedText),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.accent,
              child: IconButton(
                icon: const Icon(Icons.send, color: AppColors.onAccent, size: 20),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
