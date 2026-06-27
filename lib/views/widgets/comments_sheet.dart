import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../constants/color_constants.dart';
import '../../models/comment_api_model.dart';
import '../../models/post_model.dart';
import '../../services/api_service.dart';
import '../../services/interaction_api_service.dart';

// ---------------------------------------------------------------------------
// Thread model — holds a top-level comment and its lazy-loaded reply state
// ---------------------------------------------------------------------------

class _CommentThread {
  CommentApiModel comment;
  List<CommentApiModel> replies;
  bool isExpanded;
  bool loadingReplies;
  bool hasMoreReplies;
  String? nextRepliesCursor;
  int localRepliesCount;

  _CommentThread({
    required this.comment,
    this.replies = const [],
    this.isExpanded = false,
    this.loadingReplies = false,
    this.hasMoreReplies = false,
    this.nextRepliesCursor,
    required this.localRepliesCount,
  });
}

// ---------------------------------------------------------------------------
// Flat list item types for the ListView
// ---------------------------------------------------------------------------

sealed class _ListItem {
  const _ListItem();
}

class _ThreadItem extends _ListItem {
  final _CommentThread thread;
  const _ThreadItem(this.thread);
}

class _ReplyItem extends _ListItem {
  final CommentApiModel reply;
  final String parentId;
  const _ReplyItem(this.reply, this.parentId);
}

class _LoadingRepliesItem extends _ListItem {
  const _LoadingRepliesItem();
}

class _LoadMoreRepliesItem extends _ListItem {
  final _CommentThread thread;
  const _LoadMoreRepliesItem(this.thread);
}

class _LoadMoreCommentsItem extends _ListItem {
  const _LoadMoreCommentsItem();
}

// ---------------------------------------------------------------------------
// CommentsSheet
// ---------------------------------------------------------------------------

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
  final List<_CommentThread> _threads = [];
  bool _loadingInitial = true;
  bool _loadingMore = false;
  String? _nextCursor;
  bool _submitting = false;
  int _localCount = 0;

  String? _replyingToCommentId;
  String? _replyingToUsername;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  // Controls the draggable sheet so we can expand it when keyboard shows.
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final InteractionApiService _service = InteractionApiService(ApiService());

  @override
  void initState() {
    super.initState();
    _localCount = widget.post.commentsCount;
    _loadComments();
    _scrollController.addListener(_onScroll);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // When the user taps the input, expand the sheet to near-full before the
  // keyboard rises so the list stays visible and the input clears the keyboard.
  void _onFocusChange() {
    if (_focusNode.hasFocus && _sheetController.isAttached) {
      _sheetController.animateTo(
        0.92,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Build flat item list for ListView
  // -------------------------------------------------------------------------

  List<_ListItem> _buildItems() {
    final items = <_ListItem>[];
    for (final thread in _threads) {
      items.add(_ThreadItem(thread));
      if (thread.isExpanded) {
        for (final reply in thread.replies) {
          items.add(_ReplyItem(reply, thread.comment.id));
        }
        if (thread.loadingReplies) {
          items.add(const _LoadingRepliesItem());
        } else if (thread.hasMoreReplies) {
          items.add(_LoadMoreRepliesItem(thread));
        }
      }
    }
    if (_loadingMore) items.add(const _LoadMoreCommentsItem());
    return items;
  }

  // -------------------------------------------------------------------------
  // Network calls
  // -------------------------------------------------------------------------

  Future<void> _loadComments() async {
    try {
      final data = await _service.getComments(widget.post.id);
      if (!mounted) return;
      final list = (data['comments'] as List? ?? [])
          .map((e) => CommentApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _threads.clear();
        _threads.addAll(list.map((c) => _CommentThread(
              comment: c,
              localRepliesCount: c.repliesCount,
            )));
        _nextCursor = data['next_cursor'] as String?;
        _loadingInitial = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingInitial = false);
    }
  }

  Future<void> _loadMoreComments() async {
    if (_loadingMore || _nextCursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final data = await _service.getComments(
        widget.post.id,
        afterCursor: _nextCursor,
      );
      if (!mounted) return;
      final list = (data['comments'] as List? ?? [])
          .map((e) => CommentApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _threads.addAll(list.map((c) => _CommentThread(
              comment: c,
              localRepliesCount: c.repliesCount,
            )));
        _nextCursor = data['next_cursor'] as String?;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadReplies(_CommentThread thread) async {
    if (thread.loadingReplies) return;
    setState(() => thread.loadingReplies = true);
    try {
      final data = await _service.getReplies(widget.post.id, thread.comment.id);
      if (!mounted) return;
      final list = (data['replies'] as List? ?? [])
          .map((e) => CommentApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        thread.replies = list;
        thread.nextRepliesCursor = data['next_cursor'] as String?;
        thread.hasMoreReplies = thread.nextRepliesCursor != null;
        thread.isExpanded = true;
        thread.loadingReplies = false;
      });
    } catch (_) {
      if (mounted) setState(() => thread.loadingReplies = false);
    }
  }

  Future<void> _loadMoreReplies(_CommentThread thread) async {
    if (thread.loadingReplies || thread.nextRepliesCursor == null) return;
    setState(() => thread.loadingReplies = true);
    try {
      final data = await _service.getReplies(
        widget.post.id,
        thread.comment.id,
        afterCursor: thread.nextRepliesCursor,
      );
      if (!mounted) return;
      final list = (data['replies'] as List? ?? [])
          .map((e) => CommentApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        thread.replies = [...thread.replies, ...list];
        thread.nextRepliesCursor = data['next_cursor'] as String?;
        thread.hasMoreReplies = thread.nextRepliesCursor != null;
        thread.loadingReplies = false;
      });
    } catch (_) {
      if (mounted) setState(() => thread.loadingReplies = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await _service.addComment(
        widget.post.id,
        text,
        parentId: _replyingToCommentId,
      );
      final newComment = CommentApiModel.fromJson(result);
      if (!mounted) return;

      final replyingToId = _replyingToCommentId;
      setState(() {
        if (replyingToId == null) {
          _threads.insert(
            0,
            _CommentThread(comment: newComment, localRepliesCount: 0),
          );
          _localCount++;
        } else {
          final idx = _threads.indexWhere((t) => t.comment.id == replyingToId);
          if (idx != -1) {
            final thread = _threads[idx];
            thread.localRepliesCount++;
            if (thread.isExpanded) {
              thread.replies = [...thread.replies, newComment];
            } else {
              thread.comment = thread.comment.copyWith(
                repliesCount: thread.localRepliesCount,
              );
            }
          }
        }
        _replyingToCommentId = null;
        _replyingToUsername = null;
        _submitting = false;
      });
      _controller.clear();
      widget.onCommentAdded?.call();

      if (replyingToId == null && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(String commentId, {String? parentId}) async {
    try {
      await _service.deleteComment(widget.post.id, commentId);
      if (!mounted) return;
      setState(() {
        if (parentId == null) {
          _threads.removeWhere((t) => t.comment.id == commentId);
          _localCount = (_localCount - 1).clamp(0, _localCount);
        } else {
          final idx = _threads.indexWhere((t) => t.comment.id == parentId);
          if (idx != -1) {
            final thread = _threads[idx];
            thread.replies =
                thread.replies.where((r) => r.id != commentId).toList();
            thread.localRepliesCount =
                (thread.localRepliesCount - 1).clamp(0, thread.localRepliesCount);
          }
        }
      });
    } catch (_) {}
  }

  void _startReply(String commentId, String username) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUsername = username;
    });
    _focusNode.requestFocus(); // triggers _onFocusChange → sheet expands
  }

  void _toggleReplies(_CommentThread thread) {
    if (thread.isExpanded) {
      setState(() => thread.isExpanded = false);
    } else if (thread.replies.isEmpty) {
      _loadReplies(thread);
    } else {
      setState(() => thread.isExpanded = true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreComments();
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Read the keyboard height HERE, at the top of build(). This makes the
    // State's element depend on MediaQuery, so it rebuilds on every keyboard
    // open/close. We then pad the ENTIRE sheet upward by that amount, so the
    // whole sheet (list + input) sits above the keyboard. The input can no
    // longer be hidden because the sheet itself never overlaps the keyboard.
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final items = _buildItems();

    // Padding(bottom: keyboardInset) lifts the whole sheet above the keyboard.
    // FractionallySizedBox sizes the sheet relative to the space ABOVE the
    // keyboard (the Padding shrinks the available height first), so it grows
    // taller when the keyboard is closed and shrinks to fit when it's open —
    // never overflowing the top. The input is the last item in the Column, so
    // it always sits flush above the keyboard. This is the standard modal
    // keyboard-avoidance pattern and works reliably.
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              const Divider(color: AppColors.neutral600, height: 1),
              Expanded(
                child: _loadingInitial
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent))
                    : items.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 8),
                            itemCount: items.length,
                            itemBuilder: (_, i) => _buildItem(items[i]),
                          ),
              ),
              const Divider(color: AppColors.neutral600, height: 1),
              if (_replyingToUsername != null) _buildReplyBanner(),
              _buildInput(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() => Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: AppColors.neutral600, borderRadius: BorderRadius.circular(2)),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Comments${_localCount > 0 ? ' · $_localCount' : ''}',
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.onSurface),
        ),
      );

  Widget _buildEmpty() => Center(
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
                style: TextStyle(fontSize: 13, color: AppColors.neutral400)),
          ],
        ),
      );

  Widget _buildReplyBanner() => Container(
        color: AppColors.accent.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.reply, color: AppColors.accent, size: 16),
            const SizedBox(width: 8),
            Text(
              'Replying to @$_replyingToUsername',
              style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() {
                _replyingToCommentId = null;
                _replyingToUsername = null;
              }),
              child: const Icon(Icons.close,
                  color: AppColors.neutral400, size: 18),
            ),
          ],
        ),
      );

  // Keyboard avoidance is handled by the AnimatedPadding around the whole
  // sheet in build(), so this just needs a flat bottom gap. Add the safe-area
  // inset so the input clears the home indicator when the keyboard is closed.
  Widget _buildInput(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildAvatar(widget.currentUserAvatar, widget.currentUsername ?? '',
                radius: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppColors.neutral600,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  style:
                      const TextStyle(color: AppColors.onSurface, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Add a comment…',
                    hintStyle: TextStyle(color: AppColors.neutral400),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          strokeWidth: 2, color: AppColors.accent))
                  : GestureDetector(
                      key: const ValueKey('send'),
                      onTap: _submitComment,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                            color: AppColors.accent, shape: BoxShape.circle),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
            ),
          ],
        ),
      );

  // -------------------------------------------------------------------------
  // Item dispatch
  // -------------------------------------------------------------------------

  Widget _buildItem(_ListItem item) {
    return switch (item) {
      _ThreadItem(:final thread) => _buildCommentTile(thread),
      _ReplyItem(:final reply, :final parentId) =>
        _buildReplyTile(reply, parentId),
      _LoadingRepliesItem() => const Padding(
          padding: EdgeInsets.only(left: 56, top: 8, bottom: 8),
          child: SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppColors.accent),
          ),
        ),
      _LoadMoreRepliesItem(:final thread) => _buildLoadMoreRepliesButton(thread),
      _LoadMoreCommentsItem() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
              child: SizedBox(
            width: 20,
            height: 20,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
          )),
        ),
    };
  }

  // -------------------------------------------------------------------------
  // Top-level comment tile
  // -------------------------------------------------------------------------

  Widget _buildCommentTile(_CommentThread thread) {
    final comment = thread.comment;
    final isOwn = comment.userId == widget.currentUserId;
    final count = thread.localRepliesCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(comment.avatarUrl, comment.username, radius: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        color: AppColors.onSurface, fontSize: 13.5, height: 1.4),
                    children: [
                      TextSpan(
                          text: '${comment.username} ',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: comment.content),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(_timeAgo(comment.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.neutral400)),
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
                if (count > 0) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _toggleReplies(thread),
                    child: Row(
                      children: [
                        Container(
                            width: 24, height: 1, color: AppColors.neutral400),
                        const SizedBox(width: 8),
                        Text(
                          thread.isExpanded
                              ? 'Hide replies'
                              : 'View $count ${count == 1 ? 'reply' : 'replies'}',
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.neutral400,
                              fontWeight: FontWeight.w600),
                        ),
                        if (thread.loadingReplies && !thread.isExpanded) ...[
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: AppColors.accent),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Reply tile (indented)
  // -------------------------------------------------------------------------

  Widget _buildReplyTile(CommentApiModel reply, String parentId) {
    final isOwn = reply.userId == widget.currentUserId;
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 14, top: 7, bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(reply.avatarUrl, reply.username, radius: 13),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        color: AppColors.onSurface, fontSize: 13, height: 1.4),
                    children: [
                      TextSpan(
                          text: '${reply.username} ',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: reply.content),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(_timeAgo(reply.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.neutral400)),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => _startReply(parentId, reply.username),
                      child: const Text('Reply',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.neutral400,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (isOwn) ...[
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () =>
                            _deleteComment(reply.id, parentId: parentId),
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
        ],
      ),
    );
  }

  Widget _buildLoadMoreRepliesButton(_CommentThread thread) => GestureDetector(
        onTap: () => _loadMoreReplies(thread),
        child: Padding(
          padding: const EdgeInsets.only(left: 56, top: 4, bottom: 10),
          child: Row(
            children: [
              Container(width: 24, height: 1, color: AppColors.neutral400),
              const SizedBox(width: 8),
              const Text(
                'Load more replies',
                style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

  // -------------------------------------------------------------------------
  // Shared avatar builder
  // -------------------------------------------------------------------------

  Widget _buildAvatar(String? url, String name, {required double radius}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
      backgroundImage:
          (url != null && url.isNotEmpty) ? CachedNetworkImageProvider(url) : null,
      child: (url == null || url.isEmpty)
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: TextStyle(
                  fontSize: radius * 0.8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent),
            )
          : null,
    );
  }
}
