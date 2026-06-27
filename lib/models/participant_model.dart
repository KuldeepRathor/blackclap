import 'package:equatable/equatable.dart';

/// A user inside a conversation. Lightweight projection (avoids loading the
/// full UserModel per thread). For a 1:1 DM there are two participants; for a
/// group, N — the model is the same so groups need no new shape later.
class ParticipantModel extends Equatable {
  final String userId;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String role;
  final DateTime? lastReadAt;

  const ParticipantModel({
    required this.userId,
    required this.username,
    this.displayName = '',
    this.avatarUrl = '',
    this.role = 'member',
    this.lastReadAt,
  });

  /// Parse a backend ParticipantInfo: `{ user: {...}, role, last_read_at }`.
  factory ParticipantModel.fromApiResponse(Map<String, dynamic> map) {
    final user = (map['user'] as Map<String, dynamic>?) ?? map;
    final lastReadRaw = map['last_read_at'];
    return ParticipantModel(
      userId: user['id']?.toString() ?? '',
      username: user['username']?.toString() ?? '',
      displayName: user['display_name']?.toString() ?? '',
      avatarUrl: user['avatar_url']?.toString() ?? '',
      role: map['role']?.toString() ?? 'member',
      lastReadAt: lastReadRaw is String ? DateTime.tryParse(lastReadRaw) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user': {
        'id': userId,
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
      },
      'role': role,
      'last_read_at': lastReadAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [userId, username, displayName, avatarUrl, role, lastReadAt];
}
