import 'package:dash_race/components/bottom_scroller.dart';
import 'package:dash_race/providers/game.dart';
import 'package:dash_race/screens/track.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';

import '../helpers/extensions.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final FocusNode focusNode = FocusNode();
  late final Ticker ticker;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    ticker = createTicker(context.game.gameLoop)..start();
    // startServer();
  }

  @override
  void dispose() {
    ticker.dispose();
    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        return Scaffold(
          body: NesScaffold(
            body: Builder(
              builder: (context) {
                return Focus(
                  focusNode: focusNode,
                  onKeyEvent: (node, event) {
                    // TODO !!!
                    // handleKeyEvent(event, gameProvider.car1, gameProvider.car2);
                    return KeyEventResult.handled;
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 0,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            // Change later for better effects
                            // switchInCurve: Curves.linear,
                            // switchOutCurve: Curves.elasticOut,
                            child: SizedBox(
                              key: ValueKey(gameProvider.currentTrack.name),
                              width: 1000,
                              height: 1000,
                              child: Track(
                                key: ValueKey(gameProvider.currentTrack.name),
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            child: NesContainer(
                              key: ValueKey(
                                context.watchScreen.currentWidget,
                              ), // Need to refactor the valueKey
                              height: 1000,
                              width: MediaQuery.of(context).size.width - 1000,
                              backgroundColor: Colors.white,
                              borderColor: Colors.blue,
                              child: Center(
                                child: context.watchScreen.currentWidget,
                              ),
                            ),
                          ),
                        ],
                      ),
                      BottomScroller(),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
