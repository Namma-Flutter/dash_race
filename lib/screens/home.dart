import 'package:dash_race/helpers/extensions.dart';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      spacing: 16,
      children: [
        Image.asset(
          "assets/images/logo.png",
          fit: BoxFit.contain,
          width: MediaQuery.of(context).size.width - 1000,
        ),
        Text("No High Scorers"),
        // buildLeaderboard(),
        SizedBox(height: 16),
        NesButton(
          type: NesButtonType.primary,
          child: const Text("Play"),
          onPressed: () {
            context.readServer.startIfNotRunning().then(
              (v) => context.screen.goLobby(),
            );
          },
        ),
        NesIterableOptions(
          values: context.game.trackNames,
          value: context.watchGame.currentTrack.name,
          onChange: (name) {
            context.game.changeTrack(name);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            NesButton(
              type: NesButtonType.normal,
              child: Text("Contribute"),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) {
                    return NesDialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Do you want to continue?"),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              NesButton(
                                type: NesButtonType.normal,
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("Cancel"),
                              ),

                              const SizedBox(width: 8),

                              NesButton(
                                type: NesButtonType.primary,
                                onPressed: () {
                                  Navigator.pop(context);

                                  print("Continue pressed");
                                },
                                child: const Text("Continue"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            NesButton(
              type: NesButtonType.normal,
              child: Text("Credits"),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}
