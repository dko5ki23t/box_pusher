import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/sequences/game_seq.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class QuestSeq extends Component with HasGameReference<BoxPusherGame> {
  @override
  Future<void> onLoad() async {
    addAll([
      TextComponent(
        text: "レベル選択",
        size: Vector2(320.0, 45.0),
        position: Vector2(180.0, 80.0),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'Aboreto',
            color: Color(0xff000000),
            fontSize: 35,
          ),
        ),
      ),
    ]);

    final offset = Vector2(50.0, 125.0 + 98.75);
    for (int y = 0; y < 6; y++) {
      for (int x = 0; x < 5; x++) {
        add(
          GameTextButton(
            size: Vector2(30.0, 30.0),
            position: offset + Vector2(x * 57.5, y * 59.5),
            text: (y * 5 + x + 1).toString(),
            onReleased: () => game.pushAndInitGame(
                mode: GameMode.quest, level: y * 5 + x + 1),
          ),
        );
      }
    }
  }

  @override
  void update(double dt) {}
}
