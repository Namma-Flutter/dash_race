/// Picks the platform-appropriate [RedisService]: the real dart:io client on
/// native, or a no-op stub on web (where `package:redis` can't compile).
///
/// Callers just `import 'my_redis_service.dart'` and use `RedisService()`.
export 'redis_service_web.dart'
    if (dart.library.io) 'redis_service_io.dart';
