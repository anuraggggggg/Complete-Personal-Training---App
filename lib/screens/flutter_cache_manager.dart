import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class FastGifCacheManager extends CacheManager {
  static const key = 'fastGifCache';

  FastGifCacheManager()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 30),
            maxNrOfCacheObjects: 500,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );

  static final FastGifCacheManager instance = FastGifCacheManager();
}
