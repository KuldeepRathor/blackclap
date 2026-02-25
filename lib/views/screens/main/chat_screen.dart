import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../constants/color_constants.dart';
import '../../../repositories/mock_data_service.dart';
import '../../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;

  const ChatScreen({super.key, required this.otherUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _otherUser;
  String _currentUid = '';

  @override
  void initState() {
    super.initState();
    _otherUser = MockDataService.getUser(widget.otherUserId);
    final authState = context.read<AuthBloc>().state;
    _currentUid = authState is AuthAuthenticated ? authState.user.uid : 'user1';
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    setState(() {
      _messages = MockDataService.getMessages(_currentUid, widget.otherUserId);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    await MockDataService.sendMessage(
      senderId: _currentUid,
      receiverId: widget.otherUserId,
      message: text,
    );

    _loadMessages();
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(now, dt)) return 'Today';
    if (DateUtils.isSameDay(now.subtract(const Duration(days: 1)), dt))
      return 'Yesterday';
    return DateFormat('MMMM d, y').format(dt);
  }

  String _formatTime(DateTime dt) => DateFormat('h:mm a').format(dt);

  List<Widget> _buildMessages() {
    final widgets = <Widget>[];
    String? lastDateLabel;

    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final createdAt = msg['createdAt'] as DateTime;
      final dateLabel = _formatDate(createdAt);
      final isFromMe = msg['senderId'] == _currentUid;
      final isLastInBlock = i == _messages.length - 1 ||
          _messages[i + 1]['senderId'] != msg['senderId'];

      // Date separator
      if (dateLabel != lastDateLabel) {
        lastDateLabel = dateLabel;
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
              ),
            ),
          ),
        );
      }

      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            left: isFromMe ? 60 : 12,
            right: isFromMe ? 12 : 60,
            bottom: isLastInBlock ? 8 : 2,
          ),
          child: Column(
            crossAxisAlignment:
                isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isFromMe && isLastInBlock) ...[
                    UserAvatar(
                      imageUrl: _otherUser?['profileImageUrl'],
                      fallbackName: _otherUser?['username'] ?? 'U',
                      radius: 14,
                    ),
                    const SizedBox(width: 6),
                  ] else if (!isFromMe) ...[
                    const SizedBox(width: 34),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isFromMe
                            ? AppColors.accent
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(
                              isFromMe ? 18 : (isLastInBlock ? 4 : 18)),
                          bottomRight: Radius.circular(
                              isFromMe ? (isLastInBlock ? 4 : 18) : 18),
                        ),
                      ),
                      child: Text(
                        msg['message'],
                        style: TextStyle(
                          color: isFromMe
                              ? AppColors.textOnAccent
                              : AppColors.onSurface,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isLastInBlock)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 40, right: 4),
                  child: Text(
                    _formatTime(createdAt),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textTertiary),
                  ),
                ),
              // Seen receipt
              if (isFromMe &&
                  i == _messages.length - 1 &&
                  (msg['isRead'] as bool? ?? false))
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 4),
                  child: Text(
                    'Seen',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final otherName = _otherUser?['fullName'] ?? 'Chat';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              imageUrl: _otherUser?['profileImageUrl'],
              fallbackName: otherName,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '@${_otherUser?['username'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: AppColors.neutral300),
                        SizedBox(height: 12),
                        Text(
                          'Start a conversation!',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _buildMessages(),
                  ),
          ),
          // Input row
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file,
                        color: AppColors.textTertiary),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle:
                            const TextStyle(color: AppColors.textTertiary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppColors.neutral300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppColors.neutral300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppColors.accent, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: AppColors.textOnAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
