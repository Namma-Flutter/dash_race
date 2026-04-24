class Car {
  double x;
  double y;
  double angle;
  double speed;

  bool up = false;
  bool down = false;
  bool left = false;
  bool right = false;

  final String sprite;

  Car({
    required this.x,
    required this.y,
    required this.sprite,
    this.angle = 0,
    this.speed = 0,
  });
}
