import 'package:redis/redis.dart';

/// Native (mobile/desktop) Redis client. Uses dart:io sockets via the `redis`
/// package, so it must never be imported on web — see [my_redis_service.dart]
/// which conditionally picks this or the web stub.
class RedisService {
  late RedisConnection _connection;
  Command? _command;

  Future<void> connect() async {
    _connection = RedisConnection();
    _command = await _connection.connect('localhost', 6379);
  }

  Command get client {
    if (_command == null) {
      throw Exception("Redis not connected. Call connect() first.");
    }
    return _command!;
  }
}
