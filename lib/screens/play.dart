import 'package:dash_race/components/countdown.dart';
import 'package:dash_race/helpers/extensions.dart';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

class GamePlayScreen extends StatelessWidget {
  const GamePlayScreen({super.key});

  Widget buildLaps(BuildContext context) {
    return NesContainer(
      label: "Laps",
      width: 360,
      child: Column(
        children: context.watchGame.players.map((player) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 12,
                children: [
                  Image.asset(player.car.sprite, width: 64, height: 64),
                  Text(player.name),
                ],
              ),
              Text(player.score.toString()),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      spacing: 16,
      children: [
        context.watchGame.isGameOver
            ? Text(
                "Game Over",
                style: TextStyle(fontSize: 48, color: Colors.red),
              )
            : CountdownText(
                initialSeconds: 120,
                onComplete: () {
                  context.game.finish();
                },
              ),
        buildLaps(context),
        SizedBox(height: 16),
        context.watchGame.isGameOver
            ? NesButton(
                type: NesButtonType.primary,
                child: Text("Save & Continue"),
                onPressed: () {
                  NesScaffoldMessenger.of(context).showSnackBar(
                    NesSnackbar(
                      text: "Thanks for playing!!!",
                      type: NesSnackbarType.warning,
                    ),
                    alignment: Alignment.topCenter,
                  );
                  context.nakama.submitScores().then(
                    (v) => context.screen.goHome(),
                  );
                },
              )
            : NesButton(
                type: NesButtonType.error,
                child: Text("Quit"),
                onPressed: () {
                  NesScaffoldMessenger.of(context).showSnackBar(
                    NesSnackbar(
                      text: "Game exited by user!!!",
                      type: NesSnackbarType.warning,
                    ),
                    alignment: Alignment.topCenter,
                  );
                  context.screen.goHome();
                },
              ),
      ],
    );
  }
}
