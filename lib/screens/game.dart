import 'package:dash_race/components/bottom_scroller.dart';
import 'package:dash_race/providers/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';

import '../helpers/extensions.dart';
import '../helpers/game.dart';

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

    // startServer();
  }

  @override
  void dispose() {
    ticker.dispose();
    focusNode.dispose();

    super.dispose();
  }

  // Widget buildLeaderboard() {
  //   final topPlayers = [...playerScores]
  //     ..sort((a, b) => b.score.compareTo(a.score));
  //
  //   final top10 = topPlayers.take(10).toList();
  //
  //   return NesContainer(
  //     label: "Top Players",
  //     backgroundColor: Colors.green,
  //     width: 360,
  //     child: Column(
  //       children: List.generate(top10.length, (index) {
  //         final player = top10[index];
  //
  //         return Padding(
  //           padding: const EdgeInsets.symmetric(vertical: 2),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text("${index}. ${player.name}"),
  //               Text("${player.score}"),
  //             ],
  //           ),
  //         );
  //       }),
  //     ),
  //   );
  // }

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
                    handleKeyEvent(event, gameProvider.car1, gameProvider.car2);
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
                          SizedBox(
                            width: 1000,
                            height: 1000,
                            child: Stack(
                              children: [
                                Image.asset(
                                  gameProvider.currentTrack.imagePath,
                                  width: 1000,
                                  height: 1000,
                                  fit: BoxFit.fill,
                                ),

                                gameProvider.canStart
                                    ? Positioned(
                                        left: gameProvider.car1.x,
                                        top: gameProvider.car1.y,
                                        child: Transform.rotate(
                                          angle: gameProvider.car1.angle,
                                          child: Image.asset(
                                            gameProvider.car1.sprite,
                                            width: gameProvider.carSize,
                                            height: gameProvider.carSize,
                                          ),
                                        ),
                                      )
                                    : Container(),

                                gameProvider.canStart
                                    ? Positioned(
                                        left: gameProvider.car2.x,
                                        top: gameProvider.car2.y,
                                        child: Transform.rotate(
                                          angle: gameProvider.car2.angle,
                                          child: Image.asset(
                                            gameProvider.car2.sprite,
                                            width: gameProvider.carSize,
                                            height: gameProvider.carSize,
                                          ),
                                        ),
                                      )
                                    : Container(),
                              ],
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
                          // MenuScreenController(
                          //   onPlayPressed: () async {
                          //     // Register init() and gameLoop events
                          //     // await gameProvider.init();
                          //     // ticker = createTicker(gameProvider.gameLoop)
                          //     //   ..start();
                          //
                          //     // NesScaffoldMessenger.of(context).showSnackBar(
                          //     //   NesSnackbar(
                          //     //     text: "Starting...",
                          //     //     type: NesSnackbarType.normal,
                          //     //   ),
                          //     //   alignment: Alignment.topCenter,
                          //     // );
                          //   },
                          // ),
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
