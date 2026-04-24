import 'package:dash_race/providers/game.dart';
import 'package:dash_race/providers/screen.dart';
import 'package:dash_race/providers/server.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

extension ProviderExtensions on BuildContext {
  GameProvider get watchGame => watch<GameProvider>();
  GameProvider get readGame => read<GameProvider>();

  ScreenControlProvider get watchScreen => watch<ScreenControlProvider>();
  ScreenControlProvider get screen => read<ScreenControlProvider>();

  ServerProvider get watchServer => watch<ServerProvider>();
  ServerProvider get readServer => read<ServerProvider>();
}
