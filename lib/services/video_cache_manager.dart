import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheManager {
  static const _key = 'reelVideoCache';

  static final CacheManager instance = CacheManager(
    Config(
      _key,
      maxNrOfCacheObjects: 20,
      stalePeriod: const Duration(days: 2),
    ),
  );
}
