import 'package:dash_race/helpers/extensions.dart';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  Widget buildLobby(BuildContext context) {
    return NesContainer(
      label: "#Players Joined",
      width: 360,
      child: Column(
        children: context.watchGame.players.map((player) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Image.asset(player.car.sprite, width: 32, height: 32),
                const SizedBox(width: 10),
                Text(player.name),
              ],
            ),
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
        Text(
          "Scan below QR to join and play the game",
          style: TextStyle(fontSize: 12, color: Colors.blue),
          textAlign: TextAlign.center,
        ),
        Text(
          context.watchGame.isMaxReached
              ? "Maximum players reached for this track!!!"
              : "",
          style: TextStyle(fontSize: 10, color: Colors.red),
          textAlign: TextAlign.center,
        ),
        SizedBox(
          width: 150,
          height: 150,
          child: PrettyQrView.data(
            data: "http://${context.watchServer.ip!}:5173",
          ),
        ),
        buildLobby(context),
        SizedBox(height: 16),
        NesButton(
          type: NesButtonType.success,
          child: const Text("Start Game"),
          onPressed: () {
            if (context.game.players.isEmpty) {
              NesScaffoldMessenger.of(context).showSnackBar(
                NesSnackbar(
                  text: "No players joined",
                  type: NesSnackbarType.warning,
                ),
                alignment: Alignment.topCenter,
              );
            } else {
              context.game.init().then((v) => context.screen.goGamePlay());
              // TODO: Add a counter
              NesScaffoldMessenger.of(context).showSnackBar(
                NesSnackbar(
                  text: "Game started",
                  type: NesSnackbarType.success,
                ),
                alignment: Alignment.topCenter,
              );
            }
          },
        ),
        NesButton(
          type: NesButtonType.normal,
          child: Text("Back"),
          onPressed: () {
            context.screen.goHome();
          },
        ),
      ],
    );
  }
}
