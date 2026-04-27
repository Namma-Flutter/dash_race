import 'package:dash_race/helpers/extensions.dart';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<Widget> buildLeaderboard(BuildContext context) async {
    final data = await context.game.getTop10();
    return NesContainer(
      label: "Top Players",
      backgroundColor: Colors.green,
      width: 360,
      child: Column(
        children: List.generate(data.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${index}. ${data[index]["playerName"]}"),
                Text("${data[index]["score"]}"),
              ],
            ),
          );
        }),
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
        Image.asset(
          "assets/images/logo.png",
          fit: BoxFit.contain,
          width: MediaQuery.of(context).size.width - 1000,
        ),
        FutureBuilder(
          future: context.game.getTop10(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text("No High Scorers");
            }
            return NesContainer(
              label: "Top Players",
              backgroundColor: Colors.green,
              width: 360,
              child: Column(
                children: List.generate(snapshot.data!.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${index}. ${snapshot.data![index]["playerName"]}",
                        ),
                        Text("${snapshot.data![index]["score"]}"),
                      ],
                    ),
                  );
                }),
              ),
            );
          },
        ),
        SizedBox(height: 16),
        NesButton(
          type: NesButtonType.primary,
          onPressed: context.watchServer.showLoading
              ? null
              : () {
                  context.readServer.startIfNotRunning().then(
                    (v) => context.screen.goLobby(),
                  );
                },
          child: context.watchServer.showLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: const CircularProgressIndicator(color: Colors.white),
                )
              : const Text("Play"),
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
                        spacing: 16,
                        children: [
                          const Text("Do you want to contribute?"),
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: PrettyQrView.data(
                              data:
                                  "https://github.com/Namma-Flutter/dash_race",
                            ),
                          ),
                          NesButton(
                            type: NesButtonType.primary,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Scan & Close"),
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
