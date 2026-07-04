import 'api_service.dart';

class ModerationApiService {
  final ApiService _api;
  ModerationApiService(ApiService api) : _api = api;

  Future<bool> blockUser(String username) async {
    final data = await _api.post('/block/$username', {});
    return data['is_blocked'] as bool? ?? true;
  }

  Future<bool> unblockUser(String username) async {
    // Backend returns 200 with the updated block state for DELETE too.
    await _api.delete('/block/$username');
    return false;
  }

  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final data = await _api.getList('/block');
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) =>
      _api.post('/reports', {
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
        if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
      });
}
