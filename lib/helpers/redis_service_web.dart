/// Web stub for [RedisService]. The `redis` package relies on dart:io sockets,
/// which don't exist on web, so on web the leaderboard is simply disabled.
///
/// GameProvider guards every call behind a `_redisReady` flag and catches the
/// error from [connect], so these throwing members are never actually reached
/// on web — they exist only to satisfy the shared interface.
class RedisService {
  Future<void> connect() async {
    throw UnsupportedError('Redis is not available on web');
  }

  dynamic get client =>
      throw UnsupportedError('Redis is not available on web');
}
