import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../constants/color_constants.dart';
import '../../models/comment_api_model.dart';
import '../../models/post_model.dart';
import '../../services/api_service.dart';
import '../../services/interaction_api_service.dart';

class CommentsSheet extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final String? currentUserAvatar;
  final String? currentUsername;
  final VoidCallback? onCommentAdded;

  const CommentsSheet({
    super.key,
    required this.post,
    required this.currentUserId,
    this.currentUserAvatar,
    this.currentUsername,
    this.onCommentAdded,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final List<CommentApiModel> _comments = [];
  bool _loading = true;
  bool _submitting = false;
  int _total = 0;
  String? _replyingToId;
  String? _replyingToUsername;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final InteractionApiService _service = InteractionApiService(ApiService());

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final data = await _service.getComments(widget.post.id);
      if (!mounted) return;
      final list = (data['comments'] as List? ?? [])
          .map((e) => CommentApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _comments.clear();
        _comments.addAll(list);
        _total = data['total'] as int? ?? list.length;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await _service.addComment(widget.post.id, text,
          parentId: _replyingToId);
      final newComment = CommentApiModel.fromJson(result);
      if (!mounted) return;
      setState(() {
        _comments.insert(0, newComment);
        _total++;
        _replyingToId = null;
        _replyingToUsername = null;
        _submitting = false;
      });
      _controller.clear();
      widget.onCommentAdded?.call();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _service.deleteComment(widget.post.id, commentId);
      if (!mounted) return;
      setState(() {
        _comments.removeWhere((c) => c.id == commentId);
        _total = (_total - 1).clamp(0, _total);
      });
    } catch (_) {}
  }

  void _startReply(String commentId, String username) {
    setState(() {
      _replyingToId = commentId;
      _replyingToUsername = username;
    });
    _focusNode.requestFocus();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.neutral600,
                    borderRadius: BorderRadius.circular(2)),
              ),
              // Title row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        'Comments${_total > 0 ? ' · $_total' : ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.onSurface)),
                  ],
                ),
              ),
              const Divider(color: AppColors.neutral600, height: 1),
              // List
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accent))
                    : _comments.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.only(bottom: 8),
                            itemCount: _comments.length,
                            itemBuilder: (_, i) =>
                                _buildCommentTile(_comments[i]),
                          ),
              ),
              const Divider(color: AppColors.neutral600, height: 1),
              // Reply banner
              if (_replyingToUsername != null)
                Container(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.reply,
                          color: AppColors.accent, size: 16),
                      const SizedBox(width: 8),
                      Text('Replying to @$_replyingToUsername',
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() {
                          _replyingToId = null;
                          _replyingToUsername = null;
                        }),
                        child: const Icon(Icons.close,
                            color: AppColors.neutral400, size: 18),
                      ),
                    ],
                  ),
                ),
              // Input
              Padding(
                padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildInputAvatar(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        constraints:
                            const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: AppColors.neutral600,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: null,
                          style: const TextStyle(
                              color: AppColors.onSurface, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment…',
                            hintStyle:
                                TextStyle(color: AppColors.neutral400),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _submitting
                          ? const SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accent))
                          : GestureDetector(
                              key: const ValueKey('send'),
                              onTap: _submitComment,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputAvatar() {
    final url = widget.currentUserAvatar;
    final name = widget.currentUsername ?? '';
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.accent.withValues(alpha: 0.2),
      backgroundImage:
          (url != null && url.isNotEmpty) ? CachedNetworkImageProvider(url) : null,
      child: (url == null || url.isEmpty)
          ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent))
          : null,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 56, color: AppColors.neutral600),
          const SizedBox(height: 16),
          const Text('No comments yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface)),
          const SizedBox(height: 8),
          const Text('Be the first to comment!',
              style:
                  TextStyle(fontSize: 13, color: AppColors.neutral400)),
        ],
      ),
    );
  }

  Widget _buildCommentTile(CommentApiModel comment) {
    final isOwn = comment.userId == widget.currentUserId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            backgroundImage: (comment.avatarUrl?.isNotEmpty == true)
                ? CachedNetworkImageProvider(comment.avatarUrl!)
                : null,
            child: (comment.avatarUrl == null || comment.avatarUrl!.isEmpty)
                ? Text(
                    comment.username.isNotEmpty
                        ? comment.username[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                      style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 13.5,
                          height: 1.4),
                      children: [
                        TextSpan(
                            text: '${comment.username} ',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        TextSpan(text: comment.content),
                      ]),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(_timeAgo(comment.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.neutral400)),
                    if (comment.repliesCount > 0) ...[
                      const SizedBox(width: 14),
                      Text(
                          '${comment.repliesCount} ${comment.repliesCount == 1 ? 'reply' : 'replies'}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.neutral400,
                              fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () =>
                          _startReply(comment.id, comment.username),
                      child: const Text('Reply',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.neutral400,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (isOwn) ...[
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => _deleteComment(comment.id),
                        child: const Text('Delete',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Column(
            children: [
              Icon(Icons.favorite_border,
                  size: 14, color: AppColors.neutral400),
            ],
          ),
        ],
      ),
    );
  }
}
