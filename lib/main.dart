import 'package:dash_race/providers/game.dart';
import 'package:dash_race/providers/nakama_provider.dart';
import 'package:dash_race/providers/screen.dart';
import 'package:dash_race/screens/game.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // window_manager is desktop-only. On web the app fills the browser tab, so
  // skip all of it there.
  if (!kIsWeb) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      size: Size(1600, 1200), // Window size
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: Colors.transparent,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => ScreenControlProvider()),
        ChangeNotifierProxyProvider<GameProvider, NakamaProvider>(
          create: (_) => NakamaProvider(),
          update: (_, gp, np) {
            np ??= NakamaProvider();
            np.setGameProvider(gp);
            return np;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: flutterNesTheme(),
      home: GameScreen(),
    );
  }
}
