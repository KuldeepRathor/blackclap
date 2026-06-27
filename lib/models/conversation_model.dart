import 'package:equatable/equatable.dart';

import 'message_model.dart';
import 'participant_model.dart';

/// Unified DM + group conversation. Phase 1 only creates 1:1 DMs
/// (`isGroup == false`, exactly two participants); the group fields exist now
/// so the UI and parsing need no change later.
class ConversationModel extends Equatable {
  final String id;
  final bool isGroup;
  final String? title;
  final String? avatarUrl;
  final List<ParticipantModel> participants;
  final MessageModel? lastMessage;
  final String? lastMessagePreview;
  final int unreadCount;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    this.isGroup = false,
    this.title,
    this.avatarUrl,
    this.participants = const [],
    this.lastMessage,
    this.lastMessagePreview,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  factory ConversationModel.fromApiResponse(Map<String, dynamic> map) {
    final partsRaw = (map['participants'] as List?) ?? const [];
    final parts = partsRaw
        .whereType<Map<String, dynamic>>()
        .map(ParticipantModel.fromApiResponse)
        .toList();

    MessageModel? last;
    final lastRaw = map['last_message'];
    if (lastRaw is Map<String, dynamic>) {
      last = MessageModel.fromApiResponse(lastRaw);
    }

    final updatedRaw =
        map['last_message_at'] ?? map['updated_at'] ?? map['created_at'];

    return ConversationModel(
      id: map['id']?.toString() ?? '',
      isGroup: map['type']?.toString() == 'group',
      title: map['title']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      participants: parts,
      lastMessage: last,
      lastMessagePreview: map['last_message_preview']?.toString(),
      unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(updatedRaw?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// The "other" person in a DM (first participant that isn't the current user).
  ParticipantModel? otherParticipant(String currentUserId) {
    for (final p in participants) {
      if (p.userId != currentUserId) return p;
    }
    return participants.isNotEmpty ? participants.first : null;
  }

  String displayName(String currentUserId) {
    if (isGroup) return title ?? 'Group';
    final other = otherParticipant(currentUserId);
    if (other == null) return 'Conversation';
    return other.displayName.isNotEmpty ? other.displayName : other.username;
  }

  String displayAvatar(String currentUserId) {
    if (isGroup) return avatarUrl ?? '';
    return otherParticipant(currentUserId)?.avatarUrl ?? '';
  }

  ConversationModel copyWith({
    String? id,
    bool? isGroup,
    String? title,
    String? avatarUrl,
    List<ParticipantModel>? participants,
    MessageModel? lastMessage,
    String? lastMessagePreview,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      isGroup: isGroup ?? this.isGroup,
      title: title ?? this.title,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        isGroup,
        title,
        avatarUrl,
        participants,
        lastMessage,
        lastMessagePreview,
        unreadCount,
        updatedAt,
      ];
}
