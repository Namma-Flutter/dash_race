import 'dart:async';
import 'dart:convert';

import 'package:dash_race/config/config.dart';
import 'package:dash_race/models/car.dart';
import 'package:dash_race/models/player.dart';
import 'package:dash_race/providers/game.dart';
import 'package:flutter/material.dart';
import 'package:nakama/nakama.dart';

/// Opcodes — must match the Nakama runtime module (nakama/modules/src/main.ts).
class OpCode {
  OpCode._();
  static const int join = 1; // controller -> host : { name }
  static const int input = 2; // controller -> host : { up, down, left, right }
  static const int joinResult = 3; // host -> controller : { accepted, reason }
  static const int state = 4; // host -> controllers : optional game state
}

enum NakamaConnectionState { idle, connecting, connected, error }

/// Transport layer for the game display (host).
///
/// Replaces the old local `shelf` WebSocket server: it authenticates to the
/// hosted Nakama server (password-gated), joins the single game match as the
/// host, and feeds controller input into [GameProvider] via the exact same
/// handlers the local server used (`handleJoin` / `handleControllerMessage` /
/// `handleRemove`). The physics simulation stays client-authoritative here.
class NakamaProvider with ChangeNotifier {
  GameProvider? _game;

  NakamaBaseClient? _client;
  NakamaWebsocketClient? _socket;
  Session? _session;
  String? _matchId;

  /// Maps a Nakama user id to the [Player] the host created for it.
  final Map<String, Player> _playersByUser = {};

  NakamaConnectionState _state = NakamaConnectionState.idle;
  String? errorMessage;

  NakamaConnectionState get connectionState => _state;
  bool get isConnected => _state == NakamaConnectionState.connected;
  bool get showLoading => _state == NakamaConnectionState.connecting;

  /// URL players open on their phones (the hosted React controller).
  String get controllerUrl => ServerConfig.controllerUrl;

  void setGameProvider(GameProvider gp) {
    _game = gp;
  }

  /// Authenticate with [password], open the realtime socket, and join (or
  /// create) the single game match as the host.
  Future<void> connect(String password) async {
    if (_state == NakamaConnectionState.connecting ||
        _state == NakamaConnectionState.connected) {
      return;
    }
    errorMessage = null;
    _setState(NakamaConnectionState.connecting);

    try {
      // Use the REST client (HTTP) rather than getNakamaClient(), which on
      // desktop returns a gRPC client bound to Nakama's gRPC port (7349). Your
      // nginx proxies HTTP + WebSocket on 443, not gRPC — so auth must go over
      // REST, exactly like the web/controller client does.
      _client = NakamaRestApiClient.init(
        host: ServerConfig.host,
        serverKey: ServerConfig.serverKey,
        port: ServerConfig.port,
        ssl: ServerConfig.useSsl,
      );

      // A per-session id is enough: the host identity only needs to stay stable
      // for the lifetime of this connection (the server bakes it into the match
      // at creation). A dropped host ends the match, so no persistence needed.
      final deviceId = 'host-${DateTime.now().microsecondsSinceEpoch}';
      _session = await _client!.authenticateCustom(
        id: deviceId,
        create: true,
        vars: {'password': password},
      );

      _socket = NakamaWebsocketClient.init(
        host: ServerConfig.host,
        port: ServerConfig.port,
        ssl: ServerConfig.useSsl,
        token: _session!.token,
        onDone: _handleSocketClosed,
        onError: _handleSocketError,
      );

      _socket!.onMatchData.listen(_onMatchData);
      _socket!.onMatchPresence.listen(_onMatchPresence);

      final rpcRes = await _socket!.rpc(
        id: 'find_or_create_game',
        payload: jsonEncode({'role': ServerConfig.role}),
      );
      _matchId = (jsonDecode(rpcRes.payload) as Map)['matchId'] as String;

      await _socket!.joinMatch(_matchId!);

      _setState(NakamaConnectionState.connected);

      // Warm the leaderboard cache for the home screen (best-effort).
      unawaited(fetchTopScores());
    } catch (e) {
      errorMessage = _friendlyError(e);
      await _cleanup();
      _setState(NakamaConnectionState.error);
    }
  }

  /// Push the final scores to Nakama's leaderboard — one record per player,
  /// written under each player's own Nakama user id — then refresh the cache.
  Future<void> submitScores() async {
    final socket = _socket;
    if (socket == null || _playersByUser.isEmpty) return;

    final scores = _playersByUser.entries
        .map((e) => {
              'userId': e.key,
              'name': e.value.name,
              'score': e.value.score,
            })
        .toList();
    try {
      await socket.rpc(
        id: 'submit_scores',
        payload: jsonEncode({'scores': scores}),
      );
    } catch (e) {
      debugPrint('submit_scores failed: $e');
    }
    await fetchTopScores();
  }

  /// Fetch the top scores from Nakama and cache them in [GameProvider] for the
  /// home screen to display. Requires an active connection.
  Future<void> fetchTopScores() async {
    final socket = _socket;
    final game = _game;
    if (socket == null || game == null) return;
    try {
      final res = await socket.rpc(id: 'list_top_scores');
      final decoded = jsonDecode(res.payload) as Map<String, dynamic>;
      final records = (decoded['records'] as List?) ?? const [];
      final scores = records
          .whereType<Map>()
          .map((r) => <String, dynamic>{
                'playerName': (r['name'] ?? 'Player').toString(),
                'score': r['score'] is int
                    ? r['score'] as int
                    : int.tryParse('${r['score']}') ?? 0,
              })
          .toList();
      game.setTopScores(scores);
    } catch (e) {
      debugPrint('list_top_scores failed: $e');
    }
  }

  void _onMatchData(MatchData md) {
    final game = _game;
    final userId = md.presence?.userId;
    if (game == null || userId == null) return;

    final payload = _decodePayload(md.data);

    switch (md.opCode) {
      case OpCode.join:
        _handleJoin(userId, payload);
        break;
      case OpCode.input:
        final player = _playersByUser[userId];
        if (player != null) {
          // handleControllerMessage expects the legacy shape
          // ({type:"input", left, right, up, down}); the opcode already told us
          // this is input, so tag it here before handing it over.
          game.handleControllerMessage({...payload, 'type': 'input'}, player);
        }
        break;
    }
  }

  /// Decode a Nakama match-data payload into a JSON map.
  ///
  /// Nakama's realtime transport delivers the `data` field base64-encoded, so
  /// the raw bytes are usually the base64 *text* (e.g. `eyJsZWZ0Ijpm...`) rather
  /// than the JSON itself. We try to parse the bytes directly first and fall
  /// back to base64-decoding, so both encodings are handled safely.
  Map<String, dynamic> _decodePayload(List<int>? bytes) {
    if (bytes == null || bytes.isEmpty) return const {};

    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      return const {};
    }

    dynamic decoded = _tryJson(text);
    if (decoded == null) {
      try {
        decoded = _tryJson(utf8.decode(base64.decode(text.trim())));
      } catch (_) {
        decoded = null;
      }
    }
    return decoded is Map<String, dynamic> ? decoded : const {};
  }

  dynamic _tryJson(String source) {
    try {
      return jsonDecode(source);
    } catch (_) {
      return null;
    }
  }

  void _handleJoin(String userId, Map<String, dynamic> payload) {
    final game = _game;
    if (game == null) return;
    if (_playersByUser.containsKey(userId)) return; // duplicate join
    // Nakama already enforces MAX_PLAYERS; this is a hard cap so the sprite
    // index (car1..car4) never overflows.
    if (game.players.length >= 4) return;

    final slot = game.players.length;
    final player = Player(
      id: userId,
      name: (payload['name'] ?? 'Player ${slot + 1}').toString(),
      car: Car(x: 0, y: 0, sprite: 'assets/images/car${slot + 1}.png'),
    );
    _playersByUser[userId] = player;
    game.handleJoin(player);
    print("called from nakama");
  }

  void _onMatchPresence(MatchPresenceEvent event) {
    final game = _game;
    if (game == null) return;
    for (final p in event.leaves) {
      final player = _playersByUser.remove(p.userId);
      if (player != null) game.handleRemove(player);
    }
  }

  void _handleSocketClosed() {
    if (_state == NakamaConnectionState.connected) {
      errorMessage ??= 'Disconnected from the game server';
      _playersByUser.clear();
      _setState(NakamaConnectionState.error);
    }
  }

  void _handleSocketError(dynamic error) {
    errorMessage = _friendlyError(error);
    _setState(NakamaConnectionState.error);
  }

  String _friendlyError(Object? e) {
    final s = e.toString().toLowerCase();
    if (s.contains('unauthorized') || s.contains('401')) {
      return 'Wrong password';
    }
    return 'Could not reach the game server';
  }

  Future<void> _cleanup() async {
    try {
      if (_socket != null && _matchId != null) {
        await _socket!.leaveMatch(_matchId!);
      }
    } catch (_) {}
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    _matchId = null;
    _session = null;
    _playersByUser.clear();
  }

  /// Tear down the connection and return to idle.
  Future<void> disconnect() async {
    await _cleanup();
    errorMessage = null;
    _setState(NakamaConnectionState.idle);
  }

  void _setState(NakamaConnectionState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}
