import 'package:dash_race/helpers/extensions.dart';
import 'package:flutter/material.dart';

class Track extends StatelessWidget {
  const Track({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          context.game.currentTrack.imagePath,
          width: 1000,
          height: 1000,
          fit: BoxFit.fill,
        ),

        ...context.game.players.map((player) {
          return Positioned(
            left: player.car.x,
            top: player.car.y,
            child: Transform.rotate(
              angle: player.car.angle,
              child: Image.asset(
                player.car.sprite,
                width: context.watchGame.carSize,
                height: context.watchGame.carSize,
              ),
            ),
          );
        }),

        // context.watchGame.canStart
        //     ? Positioned(
        //         left: context.game.car1.x,
        //         top: context.game.car1.y,
        //         child: Transform.rotate(
        //           angle: context.game.car1.angle,
        //           child: Image.asset(
        //             context.game.car1.sprite,
        //             width: context.game.carSize,
        //             height: context.game.carSize,
        //           ),
        //         ),
        //       )
        //     : Container(),

        // context.readGame.canStart
        //     ? Positioned(
        //   left: context.readGame.car2.x,
        //   top: context.readGame.car2.y,
        //   child: Transform.rotate(
        //     angle: context.readGame.car2.angle,
        //     child: Image.asset(
        //       context.readGame.car2.sprite,
        //       width: context.readGame.carSize,
        //       height: context.readGame.carSize,
        //     ),
        //   ),
        // )
        //     : Container(),
      ],
    );
  }
}
