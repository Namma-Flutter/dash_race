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
        // Text(
        //   "120",
        //   style: TextStyle(fontSize: 64, color: Colors.blue),
        //   textAlign: TextAlign.center,
        // ),
        CountdownText(
          initialSeconds: 180,
          onComplete: () {
            print("Time's up!");
            // TODO: End game!
          },
        ),
        buildLaps(context),
        SizedBox(height: 16),
        NesButton(
          type: NesButtonType.error,
          child: Text("Quit"),
          onPressed: () {
            context.screen.goHome();
          },
        ),
      ],
    );
  }
}
