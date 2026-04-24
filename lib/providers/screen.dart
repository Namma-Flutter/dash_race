import 'package:dash_race/screens/home.dart';
import 'package:dash_race/screens/lobby.dart';
import 'package:flutter/material.dart';

enum GameScreenEnum { home, lobby, gameplay, result, gameOver }

class ScreenControlProvider extends ChangeNotifier {
  GameScreenEnum _current = GameScreenEnum.home;

  GameScreenEnum get current => _current;

  void goHome() => _set(GameScreenEnum.home);
  void goLobby() => _set(GameScreenEnum.lobby);
  // void goGame() => _set(GameScreenEnum.gameplay);
  // void goResult() => _set(GameScreenEnum.result);
  // void goGameOver() => _set(GameScreenEnum.gameOver);

  void _set(GameScreenEnum screen) {
    _current = screen;
    notifyListeners();
  }

  Widget get currentWidget {
    switch (_current) {
      case GameScreenEnum.home:
        return const HomeScreen();
      case GameScreenEnum.lobby:
        return const LobbyScreen();
      case GameScreenEnum.gameplay:
        // TODO: Handle this case.
        throw UnimplementedError();
      case GameScreenEnum.result:
        // TODO: Handle this case.
        throw UnimplementedError();
      case GameScreenEnum.gameOver:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}
