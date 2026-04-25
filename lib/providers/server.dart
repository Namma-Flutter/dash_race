import 'dart:convert';
import 'dart:io';

import 'package:dash_race/models/car.dart';
import 'package:dash_race/models/player.dart';
import 'package:dash_race/providers/game.dart';
import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../helpers/server_utils.dart';

class ServerProvider with ChangeNotifier {
  final Map<WebSocketChannel, Player> _connections = {};

  GameProvider? _gameProvider;
  HttpServer? _server;
  bool _isRunning = false;

  void setGameProvider(GameProvider gp) {
    _gameProvider = gp;
  }

  Future<void> startIfNotRunning() async {
    if (_isRunning) {
      print("Server already running");
      return;
    }

    await start();
  }

  Future<void> start() async {
    if (_isRunning) {
      print("Server already running");
      return;
    }

    final handler = Pipeline().addMiddleware(logRequests()).addHandler((
      request,
    ) {
      if (request.url.path == 'ws') {
        return webSocketHandler((WebSocketChannel channel, String? protocol) {
          print("Controller connected");
          channel.stream.listen(
            (message) {
              final data = jsonDecode(message);
              if (data["type"] == "join") {
                if (_gameProvider!.canJoin()) {
                  final int playerCount = _gameProvider!.players.length;
                  final Player player = Player(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: data["name"],
                    car: Car(
                      x: 0,
                      y: 0,
                      sprite: "assets/images/car${playerCount + 1}.png",
                    ),
                  );
                  _gameProvider!.handleJoin(player);
                  _connections[channel] = player;
                } else {
                  channel.sink.add(
                    jsonEncode({"type": "join", "message": "cancelled"}),
                  );
                  channel.sink.close();
                }
              } else {
                _gameProvider!.handleControllerMessage(
                  data,
                  _connections[channel]!,
                );
              }
            },
            onDone: () {
              final player = _connections[channel];
              if (player != null) {
                _gameProvider!.handleRemove(player);
                _connections.remove(channel);
              }
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

    _server = await serve(handler, '0.0.0.0', 4040);
    _isRunning = true;

    final ip = await getLocalIpAddress();

    print("Server running at:");
    print("ws://$ip:4040/ws");
    print("http://$ip:4040");
  }
}
