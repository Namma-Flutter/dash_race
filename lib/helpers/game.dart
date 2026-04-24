import 'package:flutter/services.dart';

import '../models/car.dart';

void handleKeyEvent(KeyEvent event, Car car1, Car car2) {
  final isDown = event is KeyDownEvent || event is KeyRepeatEvent;

  /// PLAYER 1 — Arrow keys
  if (event.logicalKey == LogicalKeyboardKey.arrowUp) car1.up = isDown;
  if (event.logicalKey == LogicalKeyboardKey.arrowDown) car1.down = isDown;
  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) car1.left = isDown;
  if (event.logicalKey == LogicalKeyboardKey.arrowRight) car1.right = isDown;

  /// PLAYER 2 — WASD
  if (event.logicalKey == LogicalKeyboardKey.keyW) car2.up = isDown;
  if (event.logicalKey == LogicalKeyboardKey.keyS) car2.down = isDown;
  if (event.logicalKey == LogicalKeyboardKey.keyA) car2.left = isDown;
  if (event.logicalKey == LogicalKeyboardKey.keyD) car2.right = isDown;
}
