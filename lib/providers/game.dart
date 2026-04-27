import 'dart:math';

import 'package:dash_race/helpers/image_utils.dart';
import 'package:dash_race/helpers/my_redis_service.dart';
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
  final Offset checkpointA = Offset(835, 180);
  final Offset checkpointB = Offset(120, 700);
  final RedisService redis = RedisService();

  // Local movement controls;
  bool upPressed = false;
  bool downPressed = false;
  bool leftPressed = false;
  bool rightPressed = false;
  bool canStart = false;
  bool isMaxReached = false;
  bool isGameOver = false;
  Track currentTrack = Track(
    id: 2,
    name: "Track S",
  ); // Need to refactor this logic later
  double get halfCar => carSize / 2;
  double checkpointRadius = 40;
  List<String> get trackNames => tracks.map((t) => t.name).toList();
  List<Player> players = [];

  late CollisionData collisionData;

  GameProvider() {
    loadRedis();
  }

  void loadRedis() async {
    await redis.connect();
  }

  Future<void> init() async {
    canStart = false;
    notifyListeners();
    collisionData = await loadCollisionMask(currentTrack.collisionMapPath);

    if (players.isNotEmpty) {
      // car1 = players[0].car;
      // car2 = players[1].car;
      // Need to change this - added for local testing !!! IMPORTANT !!!
      players[0].car.x = 213;
      // players[1].car.x = 213; // Enable for 2 player testing

      players[0].car.y = 820;
      // players[1].car.y = 779;

      /// Points is only for track S;
    }

    // car1 = Car(x: 213, y: 820, sprite: "assets/images/car1.png");
    // car2 = Car(x: 213, y: 779, sprite: "assets/images/car2.png");

    canStart = true;
    notifyListeners();
  }

  Future<void> saveHighScore(String playerName, int score) async {
    final cmd = redis.client;

    await cmd.send_object([
      "ZADD",
      "leaderboard",
      "GT", // only update if greater
      score,
      playerName,
    ]);
  }

  Future<List<Map<String, dynamic>>> getTop10() async {
    final cmd = redis.client;
    final result = await cmd.send_object([
      "ZREVRANGE",
      "leaderboard",
      0,
      9,
      "WITHSCORES",
    ]);

    final List<Map<String, dynamic>> leaderboard = [];
    for (int i = 0; i < result.length; i += 2) {
      leaderboard.add({
        "playerName": result[i],
        "score": int.parse(result[i + 1].toString()),
      });
    }
    print(leaderboard);
    return leaderboard;
  }

  void finish() {
    isGameOver = true;
    notifyListeners();
  }

  Future<void> saveNContinue() async {
    for (final Player player in players) {
      await saveHighScore(player.name, player.score);
    }
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

  bool isNearCheckpoint(Car car, Offset checkpoint) {
    final dx = car.x - checkpoint.dx;
    final dy = car.y - checkpoint.dy;

    return (dx * dx + dy * dy) <= (checkpointRadius * checkpointRadius);
  }

  void updatePlayerScore(Player player) {
    final car = player.car;

    // Step 1: Hit A
    if (!player.hasPassedA && isNearCheckpoint(car, checkpointA)) {
      player.hasPassedA = true;
      print("${player.name} passed A");
    }

    // Step 2: Then hit B → score!
    if (player.hasPassedA && isNearCheckpoint(car, checkpointB)) {
      player.score += 1;
      player.hasPassedA = false; // reset for next lap

      print("${player.name} scored! Total: ${player.score}");
    }
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

  // void resolveCarCollision() {
  //   final dx = car1.x - car2.x;
  //   final dy = car1.y - car2.y;
  //
  //   final distance = sqrt(dx * dx + dy * dy);
  //   final minDistance = carSize * .8;
  //
  //   if (distance < minDistance) {
  //     final overlap = minDistance - distance;
  //     final pushX = dx / distance * overlap / 2;
  //     final pushY = dy / distance * overlap / 2;
  //
  //     car1.x += pushX;
  //     car1.y += pushY;
  //
  //     car2.x -= pushX;
  //     car2.y -= pushY;
  //
  //     car1.speed *= .7;
  //     car2.speed *= .7;
  //   }
  // }

  void gameLoop(Duration elapsed) {
    if (canStart) {
      // print("GameLoop...");
      players.forEach((p) {
        updateCar(p.car);
        updatePlayerScore(p);
      });
      // updateCar(car1);
      // updateCar(car2);

      // resolveCarCollision();
      notifyListeners();
    }
  }

  bool canJoin() {
    if (currentTrack.name == "Track U") {
      if (players.length == 4) {
        isMaxReached = true;
        notifyListeners();
        return false;
      }
    } else {
      if (players.length == 2) {
        isMaxReached = true;
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  void handleJoin(Player player) {
    players.add(player);
    print("Player joined: ${player.name}");

    notifyListeners();
  }

  void handleRemove(Player player) {
    players.removeWhere((p) => p.id == player.id);
    print("Removed player: ${player.name}");
    isMaxReached = false;

    notifyListeners();
  }

  void handleControllerMessage(Map data, Player player) {
    if (data["type"] == "input") {
      print(data);
      // {type: input, left: false, right: false, up: false, down: false}

      // car1.left = data["left"];
      // car1.right = data["right"];
      // car1.up = data["up"];
      // car1.down = data["down"];
      // final Car car = players.firstWhere((p) => p.name == player.name).car;
      final Car car = player.car;
      car.left = data["left"];
      car.right = data["right"];
      car.up = data["up"];
      car.down = data["down"];
    }

    notifyListeners();
  }
}
