import 'package:dash_race/helpers/extensions.dart';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Prompt for the access password (validated server-side by Nakama).
  Future<String?> _askPassword(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return NesDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter access password"),
              const SizedBox(height: 12),
              SizedBox(
                width: 240,
                child: TextField(
                  controller: controller,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: "Password"),
                  onSubmitted: (v) => Navigator.pop(ctx, v),
                ),
              ),
              const SizedBox(height: 16),
              NesButton(
                type: NesButtonType.primary,
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text("Connect"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startGame(BuildContext context) async {
    if (context.game.currentTrack.name != "Track S") {
      NesScaffoldMessenger.of(context).showSnackBar(
        NesSnackbar(text: "Code Panala Inu", type: NesSnackbarType.warning),
        alignment: Alignment.topCenter,
      );
      return;
    }

    final password = await _askPassword(context);
    if (password == null || password.isEmpty || !context.mounted) return;

    await context.nakama.connect(password);
    if (!context.mounted) return;

    if (context.nakama.isConnected) {
      context.screen.goLobby();
    } else {
      NesScaffoldMessenger.of(context).showSnackBar(
        NesSnackbar(
          text: context.nakama.errorMessage ?? "Connection failed",
          type: NesSnackbarType.warning,
        ),
        alignment: Alignment.topCenter,
      );
    }
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
        // TODO: Need to fix re-building issues to avoid calling redis multiple times
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
                        Expanded(
                          child: Text(
                            "${index}. ${snapshot.data![index]["playerName"]}",
                            style: TextStyle(overflow: TextOverflow.fade),
                          ),
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
          onPressed: context.watchNakama.showLoading
              ? null
              : () => _startGame(context),
          child: context.watchNakama.showLoading
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
