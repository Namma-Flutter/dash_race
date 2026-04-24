import 'dart:convert';

import 'package:dash_race/providers/game.dart';
import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../helpers/server_utils.dart';

class ServerProvider with ChangeNotifier {
  GameProvider? _gameProvider;

  void setGameProvider(GameProvider gp) {
    _gameProvider = gp;
  }

  Future<void> start() async {
    final handler = Pipeline().addMiddleware(logRequests()).addHandler((
      request,
    ) {
      if (request.url.path == 'ws') {
        return webSocketHandler((WebSocketChannel channel, String? protocol) {
          print("Controller connected");
          channel.stream.listen(
            (message) {
              final data = jsonDecode(message);
              _gameProvider!.handleControllerMessage(data);
            },
            onDone: () {
              print("Controller disconnected");
            },
            onError: (error) {
              print("Socket error: $error");
            },
          );
        })(request);
      }
      return Response.ok("Game server running");
    });

    await serve(handler, '0.0.0.0', 4040);

    final ip = await getLocalIpAddress();

    print("Server running at:");
    print("ws://$ip:4040/ws");
    print("http://$ip:4040");
  }
}
