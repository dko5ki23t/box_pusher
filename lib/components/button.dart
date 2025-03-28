import 'package:push_and_merge/audio.dart';
import 'package:push_and_merge/components/rounded_component.dart';
import 'package:push_and_merge/config.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flame/layout.dart';
import 'package:flutter/material.dart' hide Image;

class GameButton extends PositionComponent with TapCallbacks {
  void Function()? onPressed;
  void Function()? onReleased;
  void Function()? onCancelled;

  bool _enabled = true;
  bool _focused = false;

  final String? keyName;

  late final RoundedComponent button;

  PositionComponent? child;

  /// 有効なボタンのPaint
  final Paint _enabledButtonPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  /// 有効なボタンの枠線のPaint
  final Paint _enabledButtonFramePaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  /// フォーカス中のボタンの枠線のPaint
  final Paint _focusedButtonFramePaint = Paint()
    ..color = Colors.red.shade200
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  /// 無効なボタンの枠線のPaint
  final Paint _disabledButtonFramePaint = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  /// 無効なボタンのPaint
  final Paint _disabledButtonPaint = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.fill;

  /// 押下されている有効なボタンのPaint
  final Paint _enabledPressedButtonPaint = Paint()
    ..color = Colors.blueGrey
    ..style = PaintingStyle.fill
    ..strokeWidth = 2;

  /// 透明なPaint
  final Paint _transparentPaint = Paint()
    ..color = Colors.transparent
    ..style = PaintingStyle.fill;

  set enabledBgColor(Color color) {
    _enabledButtonPaint.color = color;
    _colorButtons();
  }

  set enabledFrameColor(Color color) {
    _enabledButtonFramePaint.color = color;
    _colorButtons();
  }

  set focusedFrameColor(Color color) {
    _focusedButtonFramePaint.color = color;
    _colorButtons();
  }

  set disabledFrameColor(Color color) {
    _disabledButtonFramePaint.color = color;
    _colorButtons();
  }

  set disabledBgColor(Color color) {
    _disabledButtonPaint.color = color;
    _colorButtons();
  }

  set enabledPressedBgColor(Color color) {
    _enabledPressedButtonPaint.color = color;
    _colorButtons();
  }

  void _colorButtons() {
    button.borderColor = enabled
        ? (focused
            ? _focusedButtonFramePaint.color
            : _enabledButtonFramePaint.color)
        : _disabledButtonFramePaint.color;
    button.color =
        enabled ? _enabledButtonPaint.color : _disabledButtonPaint.color;
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
    button = RoundedComponent(
      size: size,
      cornerRadius: 5,
      strokeWidth: 2,
      children: [
        AlignComponent(
          alignment: Anchor.center,
          child: child,
        ),
      ],
    );
    _colorButtons();
    add(button);
  }

  bool get enabled => _enabled;

  set enabled(bool e) {
    // 変更がないなら何もしない
    if (e == _enabled) return;
    _enabled = e;
    if (!e) _focused = false;
    _colorButtons();
  }

  bool get focused => _focused;

  set focused(bool f) {
    // 変更がないなら何もしない
    if (f == _focused) return;
    // 無効なら何もしない
    if (!enabled) return;
    _focused = f;
    _colorButtons();
  }

  @override
  @mustCallSuper
  void onTapDown(TapDownEvent event) {
    if (enabled) {
      // 決定音を鳴らす
      Audio().playSound(Sound.decide);
      button.borderColor = _enabledPressedButtonPaint.color;
      button.color = _transparentPaint.color;
      onPressed?.call();
    }
  }

  @override
  @mustCallSuper
  void onTapUp(TapUpEvent event) {
    if (enabled) {
      button.borderColor = _enabledButtonFramePaint.color;
      button.color = _enabledButtonPaint.color;
      onReleased?.call();
    }
  }

  @override
  @mustCallSuper
  void onTapCancel(TapCancelEvent event) {
    if (enabled) {
      button.borderColor = _enabledButtonFramePaint.color;
      button.color = _enabledButtonPaint.color;
      onCancelled?.call();
    }
  }

  /// ボタンを押して離した時と同じ挙動をする(見た目は変わらない)
  Future<void> fire() async {
    if (enabled) {
      // 決定音を鳴らす
      await Audio().playSound(Sound.decide);
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

  void focusCurrent({int? focusIdIfNull}) {
    focusIdx ??= focusIdIfNull ?? 0;
    buttons[focusIdx!].focused = true;
  }

  void focusNext({int? focusIdIfNull}) {
    if (focusIdx == null) {
      focusCurrent(focusIdIfNull: focusIdIfNull);
      return;
    }
    // 一旦今のフォーカスを外す
    buttons[focusIdx!].focused = false;
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

  void focusPrev({int? focusIdIfNull}) {
    if (focusIdx == null) {
      focusCurrent(focusIdIfNull: focusIdIfNull);
      return;
    }
    // 一旦今のフォーカスを外す
    buttons[focusIdx!].focused = false;
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
  String? _text;

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
  })  : _text = text,
        super(
          child: TextComponent(
            text: text,
            textRenderer: TextPaint(
              style: Config.gameTextStyle,
            ),
          ),
        );

  String? get text => _text;

  set text(String? t) {
    _text = t;
    if (t != null) {
      (super.child as TextComponent).text = t;
    }
  }
}

class GameMenuButton extends GameButton {
  String? _text;

  GameMenuButton({
    super.keyName,
    required super.size,
    super.position,
    super.anchor,
    String? text,
    super.enabled,
    super.onPressed,
    super.onReleased,
    super.onCancelled,
  })  : _text = text,
        super(
          child: TextComponent(
            text: text,
            textRenderer: TextPaint(
              style: const TextStyle(
                fontFamily: Config.gameTextFamily,
                color: Colors.white,
              ),
            ),
          ),
        ) {
    super.enabledFrameColor = Colors.white;
    super.enabledBgColor = const Color(0xa0000000);
    super.enabledPressedBgColor = const Color(0xc0000000);
    super.disabledFrameColor = Colors.grey;
    super.disabledBgColor = const Color(0xc0000000);
  }

  String? get text => _text;

  set text(String? t) {
    _text = t;
    if (t != null) {
      (super.child as TextComponent).text = t;
    }
  }
}

class GameDialogButton extends GameButton {
  String? _text;

  GameDialogButton({
    super.keyName,
    required super.size,
    super.position,
    super.anchor,
    String? text,
    super.enabled,
    super.onPressed,
    super.onReleased,
    super.onCancelled,
  })  : _text = text,
        super(
          child: TextComponent(
            text: text,
            textRenderer: TextPaint(
              style: const TextStyle(
                fontFamily: Config.gameTextFamily,
                color: Colors.white,
              ),
            ),
          ),
        ) {
    super.enabledFrameColor = const Color(0x00000000);
    super.enabledBgColor = const Color(0x00000000);
  }

  String? get text => _text;

  set text(String? t) {
    _text = t;
    if (t != null) {
      (super.child as TextComponent).text = t;
    }
  }
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

  set sprite(Sprite s) {
    (super.child as SpriteComponent).sprite = s;
  }
}

class GameSpriteAnimationButton extends GameButton {
  GameSpriteAnimationButton({
    super.keyName,
    required super.size,
    super.position,
    super.anchor,
    required SpriteAnimation animation,
    super.enabled,
    super.onPressed,
    super.onReleased,
    super.onCancelled,
  }) : super(
          child: SpriteAnimationComponent(
            animation: animation,
          ),
        );

  set animation(SpriteAnimation a) {
    (super.child as SpriteAnimationComponent).animation = a;
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

/// fire(),press(),release(),cancel()で手動で押せるボタン
class ManuallyTappableButton extends ButtonComponent {
  ManuallyTappableButton({
    super.button,
    super.buttonDown,
    super.onPressed,
    super.onReleased,
    super.onCancelled,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
  });

  /// ボタンを押して離した時と同じ挙動をする
  void fire() {
    onPressed?.call();
    onReleased?.call();
  }

  /// ボタンを押した時と同じ挙動をする
  void press() {
    if (buttonDown != null) {
      button!.removeFromParent();
      buttonDown!.parent = this;
    }
    onPressed?.call();
  }

  /// ボタンを離した時と同じ挙動をする
  void release() {
    if (buttonDown != null) {
      buttonDown!.removeFromParent();
      button!.parent = this;
    }
    onReleased?.call();
  }

  /// ボタンを押すのをキャンセルした時と同じ挙動をする
  void cancel() {
    if (buttonDown != null) {
      buttonDown!.removeFromParent();
      button!.parent = this;
    }
    onCancelled?.call();
  }
}
