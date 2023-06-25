import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_captcha/flutter_captcha.dart';
import 'package:flutter_captcha/src/flutter_captcha_angle.dart';
import 'dart:math' as math;

import 'package:flutter_captcha/src/flutter_captcha_image.dart';

const _curve = Curves.fastOutSlowIn;

typedef FlutterCaptchaPartBuilder = Widget Function(
  BuildContext context,
  Widget child,
  bool isSolved,
);

class FlutterCaptchaPart extends StatefulWidget {
  final double dimension;
  final Widget child;
  final ValueChanged<bool>? onSolutionChanged;
  final FlutterCaptchaPartController controller;
  final double size;
  final FlutterCaptchaPartBuilder? builder;
  final FlutterCaptchaPartBuilder? whenMovingBuilder;
  final FlutterCaptchaPartBuilder? feedbackBuilder;
  final bool canRotate;
  final bool canMove;

  const FlutterCaptchaPart({
    required this.dimension,
    required this.child,
    required this.controller,
    required this.size,
    required this.canRotate,
    required this.canMove,
    this.onSolutionChanged,
    this.whenMovingBuilder,
    this.feedbackBuilder,
    this.builder,
    super.key,
  });

  @override
  State<FlutterCaptchaPart> createState() => _FlutterCaptchaPartState();
}

class _FlutterCaptchaPartState extends State<FlutterCaptchaPart> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = widget.dimension / MediaQuery.of(context).size.width;

    var result = widget.canMove
        ? DragTarget<FlutterCaptchaPartController>(
            onWillAccept: (data) => widget.controller._canMove(data!._position),
            onAcceptWithDetails: (details) {
              widget.controller.maybeSwapPositions(details.data);
            },
            builder: (context, _, __) =>
                widget.builder?.call(
                  context,
                  widget.child,
                  widget.controller.isSolved,
                ) ??
                widget.child,
          )
        : widget.child;

    if (widget.canRotate) {
      result = GestureDetector(
        onTap: _rotate,
        child: AnimatedRotation(
          filterQuality: FilterQuality.medium,
          duration: const Duration(milliseconds: 250),
          curve: _curve,
          turns: widget.controller.angle.value,
          child: result,
        ),
      );
    }

    if (widget.canMove) {
      result = Draggable(
        data: widget.controller,
        childWhenDragging: widget.whenMovingBuilder?.call(
                context,
                Transform.rotate(
                  angle: widget.controller.angle.absoluteValue * (2 * math.pi),
                  child: widget.child,
                ),
                widget.controller.isSolved) ??
            SizedBox.square(
              dimension: widget.size,
            ),
        feedback: _FeedbackPart(
          builder: widget.feedbackBuilder,
          controller: widget.controller,
          child: widget.child,
        ),
        child: result,
      );
    }

    return AnimatedPositioned(
      onEnd: () {
        widget.controller.isBusy = false;
      },
      curve: _curve,
      top: widget.controller.position.y * scaleFactor,
      left: widget.controller.position.x * scaleFactor,
      duration: const Duration(milliseconds: 400),
      child: result,
    );
  }

  void _rotate() {
    widget.controller.turn();
    widget.onSolutionChanged?.call(widget.controller.isSolved);
  }
}

class _FeedbackPart extends StatelessWidget {
  final FlutterCaptchaPartController controller;
  final FlutterCaptchaPartBuilder? builder;
  final Widget child;

  const _FeedbackPart({
    required this.controller,
    required this.child,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: (controller.angle * 2 * math.pi).value,
      child: builder?.call(
            context,
            child,
            controller.isSolved,
          ) ??
          child,
    );
  }
}

class FlutterCaptchaPartController extends ChangeNotifier {
  FlutterCaptchaPartController({
    required FlutterCaptchaPartPosition startPosition,
    required FlutterCaptchaPartPosition solutionPosition,
    required FlutterCaptchaAngle angle,
    required this.imageBytes,
  })  : _position = startPosition,
        _solutionPosition = solutionPosition,
        _angle = angle;

  final FlutterCaptchaPartPosition _solutionPosition;
  final Uint8List imageBytes;

  /// true if align animation is playing
  /// to prevent unwanted collisions
  bool isBusy = false;

  FlutterCaptchaPartPosition _position;
  FlutterCaptchaPartPosition get position => _position;
  set position(FlutterCaptchaPartPosition position) {
    if (!_canMove(position)) return;

    isBusy = true;
    _position = position;
    notifyListeners();
  }

  void maybeSwapPositions(FlutterCaptchaPartController other) {
    if (isBusy || other.isBusy) return;

    final changeableNewPosition = other.position;
    other.position = position;
    position = changeableNewPosition;

    if (changeableNewPosition != other.position) {}
  }

  FlutterCaptchaAngle _angle;
  FlutterCaptchaAngle get angle => _angle;
  void turn() {
    _angle = _angle.turn();
    notifyListeners();
  }

  bool get isSolved => _angle.isSolved && _position == _solutionPosition;

  bool _canMove(FlutterCaptchaPartPosition alignment) => alignment != _position;
}

class FlutterCaptchaPartsControllers extends ChangeNotifier {
  FlutterCaptchaPartsControllers();

  final _random = math.Random();
  final _controllersMap =
      <FlutterCaptchaPartPosition, FlutterCaptchaPartController>{};

  Iterable<FlutterCaptchaPartController> get value => _controllersMap.values;
  bool get isSolved =>
      _controllersMap.values.every((element) => element.isSolved);

  void init(
    FlutterCaptchaParts seed, {
    required bool shuffleAngles,
    required bool shufflePositions,
  }) {
    final startPositions = List<FlutterCaptchaPartPosition>.from(seed.keys);
    final solutionPositions = seed.keys.toList();
    final angles = FlutterCaptchaAngle.all();

    if (shufflePositions) startPositions.shuffle(_random);

    assert(startPositions.length == solutionPositions.length);

    for (int i = 0; i < solutionPositions.length; i++) {
      final startPosition = startPositions[i];
      final solutionPosition = solutionPositions[i];

      final angle = shuffleAngles
          ? _createRandomAngle(angles)
          : FlutterCaptchaAngle.full();

      _controllersMap[solutionPosition] = FlutterCaptchaPartController(
        imageBytes: seed[solutionPosition]!,
        angle: angle,
        startPosition: startPosition,
        solutionPosition: solutionPosition,
      );
    }

    notifyListeners();
  }

  FlutterCaptchaAngle _createRandomAngle(List<FlutterCaptchaAngle> angles) {
    final angleIndex = _random.nextInt(angles.length);

    return angles[angleIndex];
  }

  @override
  void dispose() {
    _controllersMap.clear();
    super.dispose();
  }

  void reset() {
    _controllersMap.clear();
    notifyListeners();
  }
}
