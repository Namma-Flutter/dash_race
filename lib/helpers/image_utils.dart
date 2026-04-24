import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class CollisionData {
  ui.Image image;
  ByteData bytes;

  CollisionData({required this.image, required this.bytes});
}

Future<CollisionData> loadCollisionMask(String imagePath) async {
  final data = await rootBundle.load(imagePath);

  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());

  final frame = await codec.getNextFrame();

  final collisionImage = frame.image;
  final collisionBytes = await collisionImage!.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  );

  return CollisionData(bytes: collisionBytes!, image: collisionImage);
}
