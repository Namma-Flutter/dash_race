import 'package:dash_race/providers/game.dart';
import 'package:dash_race/providers/screen.dart';
import 'package:dash_race/providers/server.dart';
import 'package:dash_race/screens/game.dart';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => ScreenControlProvider()),
        // ChangeNotifierProvider(create: (_) => ServerProvider()),
        ChangeNotifierProxyProvider<GameProvider, ServerProvider>(
          create: (_) => ServerProvider(),
          update: (_, gp, sp) {
            if (sp != null) {
              sp.setGameProvider(gp);
              return sp;
            }
            return sp!;
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
    return MaterialApp(theme: flutterNesTheme(), home: GameScreen());
  }
}
