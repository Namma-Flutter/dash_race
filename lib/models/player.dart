import 'car.dart';

class Player {
  String id;
  String name;
  int score;
  Car car;
  // WebSocket socket;

  // Movements
  bool up = false;
  bool down = false;
  bool left = false;
  bool right = false;

  Player({
    required this.id,
    required this.name,
    // required this.socket,
    required this.car,
    this.score = 0,
  });
}
