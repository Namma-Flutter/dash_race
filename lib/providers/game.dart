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
  final Offset checkpointA = Offset(835, 180);
  final Offset checkpointB = Offset(120, 700);

  /// Top scores from Nakama's leaderboard, cached for the home screen.
  /// Populated by [NakamaProvider] after the host connects. Each entry:
  /// `{ "playerName": String, "score": int }`.
  List<Map<String, dynamic>> topScores = [];

  /// Spawn positions per player slot (currently tuned for Track S).
  /// Indexing is bounded by [players.length] so joining with <4 players is safe.
  static const List<Offset> _spawnPoints = [
    Offset(213, 820),
    Offset(213, 779),
    Offset(213, 778),
    Offset(213, 757),
  ];

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

  /// Replace the cached leaderboard (called by NakamaProvider after fetching).
  void setTopScores(List<Map<String, dynamic>> scores) {
    topScores = scores;
    notifyListeners();
  }

  Future<void> init() async {
    canStart = false;
    isGameOver = false;
    isMaxReached = false;
    notifyListeners();
    collisionData = await loadCollisionMask(currentTrack.collisionMapPath);

    // Position only the players that actually joined. Previously this indexed
    // players[2]/[3] unconditionally and crashed with <4 players.
    for (int i = 0; i < players.length && i < _spawnPoints.length; i++) {
      final car = players[i].car;
      car.x = _spawnPoints[i].dx;
      car.y = _spawnPoints[i].dy;
      // Reset per-round state so a replay doesn't inherit the last race.
      car.angle = 0;
      car.speed = 0;
      car.up = car.down = car.left = car.right = false;
      players[i].hasPassedA = false;
      players[i].score = 0;
    }

    canStart = true;
    notifyListeners();
  }

  void finish() {
    isGameOver = true;
    notifyListeners();
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
    if (canStart && !isGameOver) {
      players.forEach((p) {
        updateCar(p.car);
        updatePlayerScore(p);
      });
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
      final Car car = player.car;
      car.left = data["left"];
      car.right = data["right"];
      car.up = data["up"];
      car.down = data["down"];
    }

    notifyListeners();
  }
}
