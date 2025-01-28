// https://github.com/flame-engine/flame/issues/2635

// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_internal_member

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/src/events/flame_game_mixins/multi_drag_dispatcher.dart';
import 'package:flutter/gestures.dart';

// This is kanged from `Flutter` [InteractiveViewer] widget
enum _GestureType {
  pan,
  scale,
  rotate,
}

/// An helper mixin that should be used instead of `Flame`
/// default detectors in order to make both game & components
/// receive guestures.
///
/// <br>
/// This is need due to fact of how `Flutter` GestureArea
/// works under the hood.
/// https://github.com/flame-engine/flame/issues/2635
mixin CustomScaleDetector on FlameGame {
  _GestureType? _gestureType;

  static int _id = 0;

  @override
  void onMount() {
    gestureDetectors.add(
      () {
        return ScaleGestureRecognizer();
      },
      (ScaleGestureRecognizer instance) {
        instance.onStart = _handleScaleStart;
        instance.onUpdate = _handleScaleUpdate;
        instance.onEnd = _handleScaleEnd;
      },
    );
  }

  @override
  void onChildrenChanged(Component child, ChildrenChangeType type) {
    super.onChildrenChanged(child, type);
    switch (type) {
      case ChildrenChangeType.removed:
        return;
      case ChildrenChangeType.added:
        if (child is! MultiDragListener) {
          return;
        }
        // Not sure what causing the problem, but if an child component
        // with `MultiDragListener` gets added, scale & rotation becoming `0`
        // even if we scale with two finger's (working with 3 or more finger's)
        //
        // So to fix that we are removing the guesture detector which gets
        // added by `MultiDragListener`
        //
        // https://github.com/flame-engine/flame/issues/2635#issuecomment-2466755220
        gestureDetectors.remove<ImmediateMultiDragGestureRecognizer>();
        return;
    }
  }

  @override
  void onRemove() {
    gestureDetectors.remove<ScaleGestureRecognizer>();
  }

  void onDragStart(int pointerId, DragStartInfo info) {}

  void onDragUpdate(int pointerId, DragUpdateInfo info) {}

  void onDragEnd(int pointerId, DragEndInfo info) {}

  void onScaleStart(ScaleStartInfo info) {}

  void onScaleUpdate(ScaleUpdateInfo info) {}

  void onScaleEnd(ScaleEndInfo info) {}

  void _handleDragStart(int pointerId, DragStartDetails details) {
    onDragStart(pointerId, DragStartInfo.fromDetails(this, details));
  }

  void _handleDragUpdate(int pointerId, DragUpdateDetails details) {
    onDragUpdate(pointerId, DragUpdateInfo.fromDetails(this, details));
  }

  void _handleDragEnd(int pointerId, DragEndDetails details) {
    onDragEnd(pointerId, DragEndInfo.fromDetails(details));
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _id++;
    _gestureType = null;
    final dragDetails = DragStartDetails(
      sourceTimeStamp: details.sourceTimeStamp,
      globalPosition: details.focalPoint,
      localPosition: details.localFocalPoint,
    );
    final dragEvent = DragStartEvent(_id, this, dragDetails);
    findByKey<MultiDragDispatcher>(const MultiDragDispatcherKey())
        ?.onDragStart(dragEvent);
    if (dragEvent.continuePropagation) {
      _handleDragStart(_id, dragDetails);
    }
    onScaleStart(ScaleStartInfo.fromDetails(this, details));
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_gestureType == _GestureType.pan) {
      // When a gesture first starts, it sometimes has no change in scale and
      // rotation despite being a two-finger gesture. Here the gesture is
      // allowed to be reinterpreted as its correct type after originally
      // being marked as a pan.
      _gestureType = _getGestureType(details);
    }
    switch (_gestureType ??= _getGestureType(details)) {
      case _GestureType.pan:
        final dragDetails = DragUpdateDetails(
          sourceTimeStamp: details.sourceTimeStamp,
          delta: details.focalPointDelta,
          globalPosition: details.focalPoint,
          localPosition: details.localFocalPoint,
        );
        final dragEvent = DragUpdateEvent(_id, this, dragDetails)
          ..continuePropagation = true;
        findByKey<MultiDragDispatcher>(const MultiDragDispatcherKey())
            ?.onDragUpdate(dragEvent);
        if (dragEvent.continuePropagation) {
          _handleDragUpdate(_id, dragDetails);
        }
        break;
      case _GestureType.scale:
      case _GestureType.rotate:
        onScaleUpdate(ScaleUpdateInfo.fromDetails(this, details));
        break;
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    final dragDetails = DragEndDetails(velocity: details.velocity);
    final dragEvent = DragEndEvent(_id, dragDetails);
    findByKey<MultiDragDispatcher>(const MultiDragDispatcherKey())
        ?.onDragEnd(dragEvent);
    if (dragEvent.continuePropagation) {
      _handleDragEnd(_id, dragDetails);
    }
    onScaleEnd(ScaleEndInfo.fromDetails(details));
  }

  // Decide which type of gesture this is by comparing the amount of scale
  // and rotation in the gesture, if any. Scale starts at 1 and rotation
  // starts at 0. Pan will have no scale and no rotation because it uses only one
  // finger.
  _GestureType _getGestureType(ScaleUpdateDetails details) {
    if ((details.scale - 1).abs() > details.rotation.abs()) {
      return _GestureType.scale;
    } else if (details.rotation != 0.0) {
      return _GestureType.rotate;
    } else {
      return _GestureType.pan;
    }
  }
}
