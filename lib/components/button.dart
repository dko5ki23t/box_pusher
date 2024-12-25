import 'package:box_pusher/audio.dart';
import 'package:box_pusher/config.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flame/layout.dart';
import 'package:flutter/material.dart' hide Image;

/// 有効なボタンのPaint
Paint enabledButtonPaint = Paint()
  ..color = Colors.white
  ..style = PaintingStyle.fill;

/// 有効なボタンの枠線のPaint
Paint enabledButtonFramePaint = Paint()
  ..color = Colors.blue
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3;

/// フォーカス中のボタンの枠線のPaint
Paint focusedButtonFramePaint = Paint()
  ..color = Colors.red.shade200
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3;

/// 無効なボタンのPaint
Paint disabledButtonFramePaint = Paint()
  ..color = Colors.grey
  ..style = PaintingStyle.fill;

/// 押下されている有効なボタンのPaint
Paint enabledPressedButtonPaint = Paint()
  ..color = Colors.blueGrey
  ..style = PaintingStyle.fill
  ..strokeWidth = 2;

/// 透明なPaint
Paint transparentPaint = Paint()
  ..color = Colors.transparent
  ..style = PaintingStyle.fill;

class GameButton extends PositionComponent with TapCallbacks {
  void Function()? onPressed;
  void Function()? onReleased;
  void Function()? onCancelled;

  bool _enabled = true;
  bool _focused = false;

  final String? keyName;

  late final RectangleComponent button;
  late final RectangleComponent buttonTop;

  PositionComponent? child;

  void _paintButtons() {
    button.paint = enabled
        ? (focused ? focusedButtonFramePaint : enabledButtonFramePaint)
        : disabledButtonFramePaint;
    buttonTop.paint = enabled ? enabledButtonPaint : transparentPaint;
  }

  GameButton({
    this.keyName,
    this.onPressed,
    this.onReleased,
    this.onCancelled,
    bool enabled = true,
    bool focused = false,
    super.position,
    required Vector2 size,
    super.scale,
    super.angle,
    super.anchor,
    required this.child,
    super.priority,
  }) : super(size: size) {
    _enabled = enabled;
    _focused = enabled ? focused : false;
    buttonTop = RectangleComponent(
      size: size,
    );
    button = RectangleComponent(
      size: size,
      children: [
        buttonTop,
        AlignComponent(
          alignment: Anchor.center,
          child: child,
        ),
      ],
    );
    _paintButtons();
    add(button);
  }

  bool get enabled => _enabled;

  set enabled(bool e) {
    // 変更がないなら何もしない
    if (e == _enabled) return;
    _enabled = e;
    if (!e) _focused = false;
    _paintButtons();
  }

  bool get focused => _focused;

  set focused(bool f) {
    // 変更がないなら何もしない
    if (f == _focused) return;
    // 無効なら何もしない
    if (!enabled) return;
    _focused = f;
    _paintButtons();
  }

  @override
  @mustCallSuper
  void onTapDown(TapDownEvent event) {
    if (enabled) {
      // 決定音を鳴らす
      Audio().playSound(Sound.decide);
      button.paint = enabledPressedButtonPaint;
      buttonTop.paint = transparentPaint;
      onPressed?.call();
    }
  }

  @override
  @mustCallSuper
  void onTapUp(TapUpEvent event) {
    if (enabled) {
      button.paint = enabledButtonFramePaint;
      buttonTop.paint = enabledButtonPaint;
      onReleased?.call();
    }
  }

  @override
  @mustCallSuper
  void onTapCancel(TapCancelEvent event) {
    if (enabled) {
      button.paint = enabledButtonFramePaint;
      buttonTop.paint = enabledButtonPaint;
      onCancelled?.call();
    }
  }

  /// ボタンを押して離した時と同じ挙動をする(見た目は変わらない)
  void fire() {
    if (enabled) {
      // 決定音を鳴らす
      Audio().playSound(Sound.decide);
      onPressed?.call();
      onReleased?.call();
    }
  }
}

/// ボタングループ(フォーカスしているボタンを管理する)
class GameButtonGroup {
  final List<GameButton> buttons;
  int? focusIdx;
  bool loopFocus;

  GameButtonGroup(
      {required this.buttons, this.focusIdx, this.loopFocus = false}) {
    assert(buttons.isNotEmpty);
  }

  void focusNext() {
    if (focusIdx != null) {
      // 一旦今のフォーカスを外す
      buttons[focusIdx!].focused = false;
    }
    for (int i = 0; i < buttons.length; i++) {
      int index = (focusIdx ?? -1) + i + 1;
      if (loopFocus) {
        index %= buttons.length;
      } else if (index >= buttons.length) {
        // 他にフォーカスできるボタンが無いので現在のボタンにフォーカスを戻す
        if (focusIdx != null) {
          buttons[focusIdx!].focused = true;
        }
        return;
      }
      if (buttons[index].enabled) {
        focusIdx = index;
        buttons[index].focused = true;
        return;
      }
    }
  }

  void focusPrev() {
    if (focusIdx != null) {
      // 一旦今のフォーカスを外す
      buttons[focusIdx!].focused = false;
    }
    for (int i = 0; i < buttons.length; i++) {
      int index = (focusIdx ?? 1) - i - 1;
      if (loopFocus) {
        if (index < 0) {
          index += buttons.length;
        }
      } else if (index < 0) {
        // 他にフォーカスできるボタンが無いので現在のボタンにフォーカスを戻す
        if (focusIdx != null) {
          buttons[focusIdx!].focused = true;
        }
        return;
      }
      if (buttons[index].enabled) {
        focusIdx = index;
        buttons[index].focused = true;
        return;
      }
    }
  }

  void unFocus() {
    if (focusIdx != null) {
      buttons[focusIdx!].focused = false;
      focusIdx = null;
    }
  }

  GameButton? getCurrentFocusButton() {
    if (focusIdx == null) return null;
    assert(focusIdx! >= 0 && focusIdx! < buttons.length);
    return buttons[focusIdx!];
  }
}

class GameTextButton extends GameButton {
  GameTextButton({
    super.keyName,
    required super.size,
    super.position,
    super.anchor,
    String? text,
    super.enabled,
    super.onPressed,
    super.onReleased,
    super.onCancelled,
  }) : super(
          child: TextComponent(
            text: text,
            textRenderer: TextPaint(
              style: Config.gameTextStyle,
            ),
          ),
        );
}

class GameSpriteButton extends GameButton {
  GameSpriteButton({
    super.keyName,
    required super.size,
    super.position,
    super.anchor,
    required Sprite sprite,
    super.enabled,
    super.onPressed,
    super.onReleased,
    super.onCancelled,
  }) : super(
          child: SpriteComponent(
            sprite: sprite,
          ),
        );
}

class GameSpriteAnimationButton extends GameButton {
  SpriteAnimation animation;

  GameSpriteAnimationButton({
    super.keyName,
    required super.size,
    super.position,
    super.anchor,
    required this.animation,
    super.enabled,
    super.onPressed,
    super.onReleased,
    super.onCancelled,
  }) : super(
          child: SpriteAnimationComponent(
            animation: animation,
          ),
        );
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
