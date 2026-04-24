import 'dart:math';

import 'package:dash_race/helpers/image_utils.dart';
import 'package:dash_race/models/player.dart';
import 'package:dash_race/models/track.dart';
import 'package:flutter/material.dart';

import '../models/car.dart';

class GameProvider with ChangeNotifier {
  final double maxSpeed = 7; // 5 is good
  final double acceleration = 0.25;
  final double friction = 0.06;
  final double rotationSpeed = 0.05;
  final double carSize = 64;
  final List<Track> tracks = [
    Track(id: 1, name: "Track U"),
    Track(id: 2, name: "Track S"),
    Track(id: 3, name: "Track N"),
    Track(id: 4, name: "Snow"),
  ];
  // final List<Player> playerScores = [
  //   Player("Sanjivy", 120),
  //   Player("Arun", 95),
  //   Player("Karthik", 80),
  //   Player("Priya", 75),
  //   Player("Rahul", 60),
  //   Player("Vikram", 58),
  //   Player("Sneha", 50),
  //   Player("Ajay", 48),
  //   Player("Manoj", 45),
  //   Player("Divya", 40),
  //   Player("Extra1", 10),
  // ];

  // Local movement controls;
  bool upPressed = false;
  bool downPressed = false;
  bool leftPressed = false;
  bool rightPressed = false;
  bool canStart = false;
  Track currentTrack = Track(
    id: 1,
    name: "Track U",
  ); // Need to refactor this logic later
  double get halfCar => carSize / 2;
  List<String> get trackNames => tracks.map((t) => t.name).toList();
  List<Player> players = [];

  late CollisionData collisionData;

  late Car car1;
  late Car car2;

  Future<void> init() async {
    canStart = false;
    notifyListeners();
    collisionData = await loadCollisionMask(currentTrack.collisionMapPath);

    car1 = Car(x: 213, y: 820, sprite: "assets/images/car1.png");
    car2 = Car(x: 213, y: 779, sprite: "assets/images/car2.png");

    // canStart = true;
    // notifyListeners();
  }

  void changeTrack(String name) {
    currentTrack = tracks.firstWhere(
      (t) => t.name == name,
      orElse: () => tracks.first, // Fallback safety
    );
    notifyListeners();
  }

  Offset frontProbe(double nextX, double nextY, double angle) {
    final centerX = nextX + halfCar;
    final centerY = nextY + halfCar;

    return Offset(
      centerX + cos(angle) * halfCar,
      centerY + sin(angle) * halfCar,
    );
  }

  bool isRoadPixel(double px, double py) {
    // if (collisionData.bytes == null) return true;
    final width = collisionData.image.width;
    final height = collisionData.image.height;

    final xPos = px.floor().clamp(0, width - 1);
    final yPos = py.floor().clamp(0, height - 1);
    final offset = (yPos * width + xPos) * 4;

    final r = collisionData.bytes.getUint8(offset);
    final g = collisionData.bytes.getUint8(offset + 1);
    final b = collisionData.bytes.getUint8(offset + 2);

    return r > 200 && g > 200 && b > 200;
  }

  bool isCarMostlyOnRoad(double cx, double cy, double angle) {
    final centerX = cx + halfCar;
    final centerY = cy + halfCar;

    final probes = [
      Offset(0, 0),
      Offset(-halfCar * .8, -halfCar * .8),
      Offset(halfCar * .8, -halfCar * .8),
      Offset(-halfCar * .8, halfCar * .8),
      Offset(halfCar * .8, halfCar * .8),
      Offset(0, -halfCar * .9),
      Offset(0, halfCar * .9),
      Offset(-halfCar * .9, 0),
      Offset(halfCar * .9, 0),
    ];

    int blocked = 0;
    for (final p in probes) {
      final rx = p.dx * cos(angle) - p.dy * sin(angle);
      final ry = p.dx * sin(angle) + p.dy * cos(angle);

      if (!isRoadPixel(centerX + rx, centerY + ry)) {
        blocked++;
      }
    }

    return blocked <= 2;
  }

  void updateCar(Car car) {
    if (car.speed.abs() > .2) {
      if (car.left) car.angle -= rotationSpeed;
      if (car.right) car.angle += rotationSpeed;
    }

    if (car.up) car.speed += acceleration;
    if (car.down) car.speed -= acceleration;

    car.speed = car.speed.clamp(-maxSpeed / 2, maxSpeed);

    if (!car.up && !car.down) {
      if (car.speed > 0) {
        car.speed = max(0, car.speed - friction);
      } else if (car.speed < 0) {
        car.speed = min(0, car.speed + friction);
      }
    }

    final nextX = car.x + cos(car.angle) * car.speed;
    final nextY = car.y + sin(car.angle) * car.speed;
    final front = frontProbe(nextX, nextY, car.angle);

    if (isRoadPixel(front.dx, front.dy) &&
        isCarMostlyOnRoad(nextX, nextY, car.angle)) {
      car.x = nextX;
      car.y = nextY;
    }

    // if (isOnTrack(nextX, nextY)) {
    //   car.x = nextX;
    //   car.y = nextY;
    // } else {
    //   if (isOnTrack(nextX, car.y)) {
    //     car.x = nextX;
    //     car.speed *= 0.7;
    //   } else if (isOnTrack(car.x, nextY)) {
    //     car.y = nextY;
    //     car.speed *= 0.7;
    //   } else {
    //     car.speed *= -0.3;
    //   }
    // }
  }

  void resolveCarCollision() {
    final dx = car1.x - car2.x;
    final dy = car1.y - car2.y;

    final distance = sqrt(dx * dx + dy * dy);
    final minDistance = carSize * .8;

    if (distance < minDistance) {
      final overlap = minDistance - distance;
      final pushX = dx / distance * overlap / 2;
      final pushY = dy / distance * overlap / 2;

      car1.x += pushX;
      car1.y += pushY;

      car2.x -= pushX;
      car2.y -= pushY;

      car1.speed *= .7;
      car2.speed *= .7;
    }
  }

  void gameLoop(Duration elapsed) {
    // print("GameLoop...");
    updateCar(car1);
    updateCar(car2);

    resolveCarCollision();
    notifyListeners();
  }

  void handleControllerMessage(Map data) {
    if (data["type"] == "join") {
      print("Player joined: ${data["name"]}");
      players.add(
        Player(
          id: "0",
          name: data["name"],
          car: Car(x: 213, y: 820, sprite: "assets/images/car1.png"),
        ),
      );
    }

    if (data["type"] == "input") {
      print(data);
      // {type: input, left: false, right: false, up: false, down: false}
      // car1.left = data["left"];
      // car1.right = data["right"];
      // car1.up = data["up"];
      // car1.down = data["down"];
    }

    notifyListeners();
  }
}
