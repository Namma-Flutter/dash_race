import 'package:redis/redis.dart';

class RedisService {
  late RedisConnection _connection;
  Command? _command;

  Future<void> connect() async {
    _connection = RedisConnection();
    _command = await _connection.connect('localhost', 6379);
    print("Connected to Redis");
  }

  Command get client {
    if (_command == null) {
      throw Exception("Redis not connected. Call connect() first.");
    }
    return _command!;
  }
}
