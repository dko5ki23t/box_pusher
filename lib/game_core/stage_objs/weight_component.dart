import 'package:push_and_merge/components/opacity_effect_text_component.dart';
import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/game_core/stage.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flame/layout.dart';
import 'package:flutter/widgets.dart' hide Image;

class WeightComponent extends SpriteComponent {
  static String get imageFileName => 'weight.png';
  final AlignComponent _weightViewComponent = AlignComponent(
    alignment: Anchor.center,
    child: OpacityEffectTextComponent(
      priority: Stage.frontPriority,
      text: '',
      textRenderer: TextPaint(
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: Config.gameTextFamily,
              color: Color(0xff000000))),
      children: [
        SequenceEffect(
          [
            OpacityEffect.to(
              0.0,
              EffectController(duration: 1.0, startDelay: 0.3),
            ),
            OpacityEffect.to(
              0.8,
              EffectController(duration: 1.0),
            ),
          ],
          infinite: true,
        )
      ],
    ),
  );

  WeightComponent({required int weight})
      : super(
          size: Stage.cellSize * 0.8,
          children: [
            SequenceEffect(
              [
                OpacityEffect.to(
                  0.0,
                  EffectController(duration: 1.0, startDelay: 0.3),
                ),
                OpacityEffect.to(
                  0.8,
                  EffectController(duration: 1.0),
                ),
              ],
              infinite: true,
            )
          ],
        ) {
    super.add(_weightViewComponent);
    (_weightViewComponent.child as OpacityEffectTextComponent).text = '$weight';
  }

  @override
  Future<void> onLoad() async {
    super.sprite = Sprite(await Flame.images.load(imageFileName));
  }

  set weight(int w) =>
      (_weightViewComponent.child as TextComponent).text = '$w';
}
