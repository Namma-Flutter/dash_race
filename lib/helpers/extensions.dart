import 'package:dash_race/providers/game.dart';
import 'package:dash_race/providers/nakama_provider.dart';
import 'package:dash_race/providers/screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

extension ProviderExtensions on BuildContext {
  GameProvider get watchGame => watch<GameProvider>();
  GameProvider get game => read<GameProvider>();

  ScreenControlProvider get watchScreen => watch<ScreenControlProvider>();
  ScreenControlProvider get screen => read<ScreenControlProvider>();

  NakamaProvider get watchNakama => watch<NakamaProvider>();
  NakamaProvider get nakama => read<NakamaProvider>();
}
