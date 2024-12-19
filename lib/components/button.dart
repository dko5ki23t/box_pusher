import 'package:box_pusher/audio.dart';
import 'package:box_pusher/config.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/layout.dart';
import 'package:flutter/material.dart' hide Image;

class GameTextButton extends ButtonComponent {
  bool _enabled = true;
  void Function()? _onPressed;
  void Function()? _onReleased;
  void Function()? _onCancelled;

  GameTextButton({
    required super.size,
    super.position,
    super.anchor,
    String? text,
    bool enabled = true,
    void Function()? onPressed,
    void Function()? onReleased,
    void Function()? onCancelled,
  }) : super(
          onPressed: () {
            // 決定音を鳴らす
            Audio.playSound(Sound.decide);
            if (onPressed != null) onPressed();
          },
          onReleased: onReleased,
          onCancelled: onCancelled,
          button: enabled
              ? RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.blue
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3,
                  children: [
                    RectangleComponent(
                      size: size,
                      paint: Paint()
                        ..color = Colors.white
                        ..style = PaintingStyle.fill,
                    ),
                    AlignComponent(
                      alignment: Anchor.center,
                      child: TextComponent(
                        text: text,
                        textRenderer: TextPaint(
                          style: const TextStyle(
                            fontFamily: Config.gameTextFamily,
                            color: Color(0xff000000),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.grey
                    ..style = PaintingStyle.fill,
                  children: [
                    RectangleComponent(
                      size: size,
                      paint: Paint()
                        ..color = Colors.transparent
                        ..style = PaintingStyle.fill,
                    ),
                    AlignComponent(
                      alignment: Anchor.center,
                      child: TextComponent(
                        text: text,
                        textRenderer: TextPaint(
                          style: const TextStyle(
                            fontFamily: Config.gameTextFamily,
                            color: Color(0xff000000),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          buttonDown: enabled
              ? RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.blueGrey
                    ..style = PaintingStyle.fill
                    ..strokeWidth = 2,
                  children: [
                    AlignComponent(
                      alignment: Anchor.center,
                      child: TextComponent(
                        text: text,
                        textRenderer: TextPaint(
                          style: const TextStyle(
                            fontFamily: Config.gameTextFamily,
                            color: Color(0xff000000),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.grey
                    ..style = PaintingStyle.fill,
                  children: [
                    RectangleComponent(
                      size: size,
                      paint: Paint()
                        ..color = Colors.transparent
                        ..style = PaintingStyle.fill,
                    ),
                    AlignComponent(
                      alignment: Anchor.center,
                      child: TextComponent(
                        text: text,
                        textRenderer: TextPaint(
                          style: const TextStyle(
                            fontFamily: Config.gameTextFamily,
                            color: Color(0xff000000),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ) {
    _onPressed = onPressed;
    _onReleased = onReleased;
    _onCancelled = onCancelled;
    _enabled = enabled;
  }

  bool get enabled => _enabled;

  set enabled(bool e) {
    if (e != _enabled) {
      if (!e) {
        _onPressed = super.onPressed;
        _onReleased = super.onReleased;
        _onCancelled = super.onCancelled;
      }
      super.onPressed = e ? _onPressed : null;
      super.onReleased = e ? _onReleased : null;
      super.onCancelled = e ? _onCancelled : null;
      if (e) {
        (super.button! as RectangleComponent).paint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        ((super.button! as RectangleComponent).firstChild()
                as RectangleComponent)
            .paint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
      } else {
        (super.button! as RectangleComponent).paint = Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.fill;
        ((super.button! as RectangleComponent).firstChild()
                as RectangleComponent)
            .paint = Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill;
      }
    }
    _enabled = e;
  }
}

// TODO: ちゃんとrender()の中でenabledによって描画処理を変えるようなcomponentをbuttonやbuttonDownに設定するべき
class GameSpriteButton extends ButtonComponent {
  bool _enabled = true;
  Sprite sprite;
  void Function()? _onPressed;
  void Function()? _onReleased;
  void Function()? _onCancelled;

  GameSpriteButton({
    required super.size,
    super.position,
    super.anchor,
    required this.sprite,
    bool enabled = true,
    void Function()? onPressed,
    void Function()? onReleased,
    void Function()? onCancelled,
  }) : super(
          onPressed: enabled ? onPressed : null,
          onReleased: enabled ? onReleased : null,
          onCancelled: enabled ? onCancelled : null,
          button: enabled
              ? RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.blue
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3,
                  children: [
                    RectangleComponent(
                      size: size,
                      paint: Paint()
                        ..color = Colors.white
                        ..style = PaintingStyle.fill,
                    ),
                    AlignComponent(
                      alignment: Anchor.center,
                      child: SpriteComponent(
                        sprite: sprite,
                      ),
                    ),
                  ],
                )
              : RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.grey
                    ..style = PaintingStyle.fill,
                  children: [
                    RectangleComponent(
                      size: size,
                      paint: Paint()
                        ..color = Colors.transparent
                        ..style = PaintingStyle.fill,
                    ),
                    AlignComponent(
                      alignment: Anchor.center,
                      child: SpriteComponent(
                        sprite: sprite,
                      ),
                    ),
                  ],
                ),
          buttonDown: enabled
              ? RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.blueGrey
                    ..style = PaintingStyle.fill
                    ..strokeWidth = 2,
                  children: [
                    AlignComponent(
                      alignment: Anchor.center,
                      child: SpriteComponent(
                        sprite: sprite,
                      ),
                    ),
                  ],
                )
              : RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.grey
                    ..style = PaintingStyle.fill
                    ..strokeWidth = 2,
                  children: [
                    RectangleComponent(
                      size: size,
                      paint: Paint()
                        ..color = Colors.transparent
                        ..style = PaintingStyle.fill,
                    ),
                    AlignComponent(
                      alignment: Anchor.center,
                      child: SpriteComponent(
                        sprite: sprite,
                      ),
                    ),
                  ],
                ),
        ) {
    _onPressed = onPressed;
    _onReleased = onReleased;
    _onCancelled = onCancelled;
    _enabled = enabled;
  }

  bool get enabled => _enabled;

  set enabled(bool e) {
    if (e != _enabled) {
      if (!e) {
        _onPressed = super.onPressed;
        _onReleased = super.onReleased;
        _onCancelled = super.onCancelled;
      }
      super.onPressed = e ? _onPressed : null;
      super.onReleased = e ? _onReleased : null;
      super.onCancelled = e ? _onCancelled : null;
      if (e) {
        (super.button! as RectangleComponent).paint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        ((super.button! as RectangleComponent).firstChild()
                as RectangleComponent)
            .paint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
      } else {
        (super.button! as RectangleComponent).paint = Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.fill;
        ((super.button! as RectangleComponent).firstChild()
                as RectangleComponent)
            .paint = Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill;
      }
    }
    _enabled = e;
  }
}

// TODO: ちゃんとrender()の中でenabledによって描画処理を変えるようなcomponentをbuttonやbuttonDownに設定するべき
class GameSpriteAnimationButton extends ButtonComponent {
  bool _enabled = true;
  SpriteAnimation _animation;
  void Function()? _onPressed;
  void Function()? _onReleased;
  void Function()? _onCancelled;

  GameSpriteAnimationButton({
    required super.size,
    super.position,
    super.anchor,
    required SpriteAnimation animation,
    bool enabled = true,
    void Function()? onPressed,
    void Function()? onReleased,
    void Function()? onCancelled,
  })  : _animation = animation,
        super(
          onPressed: enabled ? onPressed : null,
          onReleased: enabled ? onReleased : null,
          onCancelled: enabled ? onCancelled : null,
          button: enabled
              ? RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.blue
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3,
                  children: [
                    RectangleComponent(
                      size: size,
                      paint: Paint()
                        ..color = Colors.white
                        ..style = PaintingStyle.fill,
                    ),
                    AlignComponent(
                      alignment: Anchor.center,
                      child: SpriteAnimationComponent(
                        animation: animation,
                      ),
                    ),
                  ],
                )
              : RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.grey
                    ..style = PaintingStyle.fill,
                  children: [
                    RectangleComponent(
                      size: size,
                      paint: Paint()
                        ..color = Colors.transparent
                        ..style = PaintingStyle.fill,
                    ),
                    AlignComponent(
                      alignment: Anchor.center,
                      child: SpriteAnimationComponent(
                        animation: animation,
                      ),
                    ),
                  ],
                ),
          buttonDown: enabled
              ? RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.blueGrey
                    ..style = PaintingStyle.fill
                    ..strokeWidth = 2,
                  children: [
                    AlignComponent(
                      alignment: Anchor.center,
                      child: SpriteAnimationComponent(
                        animation: animation,
                      ),
                    ),
                  ],
                )
              : RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.grey
                    ..style = PaintingStyle.fill
                    ..strokeWidth = 2,
                  children: [
                    RectangleComponent(
                      size: size,
                      paint: Paint()
                        ..color = Colors.transparent
                        ..style = PaintingStyle.fill,
                    ),
                    AlignComponent(
                      alignment: Anchor.center,
                      child: SpriteAnimationComponent(
                        animation: animation,
                      ),
                    ),
                  ],
                ),
        ) {
    _onPressed = onPressed;
    _onReleased = onReleased;
    _onCancelled = onCancelled;
    _enabled = enabled;
  }

  bool get enabled => _enabled;

  set enabled(bool e) {
    if (e != _enabled) {
      if (!e) {
        _onPressed = super.onPressed;
        _onReleased = super.onReleased;
        _onCancelled = super.onCancelled;
      }
      super.onPressed = e ? _onPressed : null;
      super.onReleased = e ? _onReleased : null;
      super.onCancelled = e ? _onCancelled : null;
      if (e) {
        (super.button! as RectangleComponent).paint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        ((super.button! as RectangleComponent).firstChild()
                as RectangleComponent)
            .paint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
      } else {
        (super.button! as RectangleComponent).paint = Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.fill;
        ((super.button! as RectangleComponent).firstChild()
                as RectangleComponent)
            .paint = Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill;
      }
    }
    _enabled = e;
  }

  // TODO:このへんかなり強引
  SpriteAnimation get animation => _animation;
  set animation(SpriteAnimation a) {
    _animation = a;
    (super.button!.children.whereType<AlignComponent>().first.child
            as SpriteAnimationComponent)
        .animation = _animation;
    (super.buttonDown!.children.whereType<AlignComponent>().first.child
            as SpriteAnimationComponent)
        .animation = _animation;
  }
}

class GameSpriteOnOffButton extends ButtonComponent {
  bool _isOn = true;
  Sprite _sprite;

  void Function(bool isOn)? onChanged;

  GameSpriteOnOffButton({
    required super.size,
    super.position,
    super.anchor,
    required Sprite sprite,
    bool isOn = false,
    this.onChanged,
  })  : _sprite = sprite,
        super(
          button: !isOn
              ? RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.blue
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3,
                  children: [
                    RectangleComponent(
                      size: size,
                      paint: Paint()
                        ..color = Colors.white
                        ..style = PaintingStyle.fill,
                    ),
                    AlignComponent(
                      alignment: Anchor.center,
                      child: SpriteComponent(
                        sprite: sprite,
                      ),
                    ),
                  ],
                )
              : RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.grey
                    ..style = PaintingStyle.fill,
                  children: [
                    RectangleComponent(
                      size: size,
                      paint: Paint()
                        ..color = Colors.transparent
                        ..style = PaintingStyle.fill,
                    ),
                    AlignComponent(
                      alignment: Anchor.center,
                      child: SpriteComponent(
                        sprite: sprite,
                      ),
                    ),
                  ],
                ),
          buttonDown: !isOn
              ? RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.blueGrey
                    ..style = PaintingStyle.fill
                    ..strokeWidth = 2,
                  children: [
                    AlignComponent(
                      alignment: Anchor.center,
                      child: SpriteComponent(
                        sprite: sprite,
                      ),
                    ),
                  ],
                )
              : RectangleComponent(
                  size: size,
                  paint: Paint()
                    ..color = Colors.grey
                    ..style = PaintingStyle.fill
                    ..strokeWidth = 2,
                  children: [
                    RectangleComponent(
                      size: size,
                      paint: Paint()
                        ..color = Colors.transparent
                        ..style = PaintingStyle.fill,
                    ),
                    AlignComponent(
                      alignment: Anchor.center,
                      child: SpriteComponent(
                        sprite: sprite,
                      ),
                    ),
                  ],
                ),
        ) {
    _isOn = isOn;
    super.onReleased = onChanged != null
        ? () {
            this.isOn = !this.isOn;
            onChanged!(this.isOn);
          }
        : null;
  }

  bool get isOn => _isOn;

  set isOn(bool b) {
    if (b != _isOn) {
      if (!b) {
        (super.button! as RectangleComponent).paint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        ((super.button! as RectangleComponent).firstChild()
                as RectangleComponent)
            .paint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
      } else {
        (super.button! as RectangleComponent).paint = Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.fill;
        ((super.button! as RectangleComponent).firstChild()
                as RectangleComponent)
            .paint = Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill;
      }
    }
    _isOn = b;
  }

  // TODO:このへんかなり強引
  Sprite get sprite => _sprite;
  set sprite(Sprite s) {
    _sprite = s;
    (super.button!.children.whereType<AlignComponent>().first.child
            as SpriteComponent)
        .sprite = _sprite;
    (super.buttonDown!.children.whereType<AlignComponent>().first.child
            as SpriteComponent)
        .sprite = _sprite;
  }
}
