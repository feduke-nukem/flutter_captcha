import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_captcha/src/angle.dart';
import 'dart:math' as math;

/// {@template flutter_captcha_part.flutter_captcha_parts}
/// Each [CaptchaPartPosition] is mapped to a [Uint8List] representing the
/// image part in bytes.
/// {@endtemplate}
typedef CaptchaParts = Map<CaptchaPartPosition, Uint8List>;

/// {@template flutter_captcha_part.builder}
/// A builder for the captcha parts.
/// {@endtemplate}
typedef FlutterCaptchaPartBuilder = Widget Function(
  BuildContext context,
  Widget part,
  bool isSolved,
);

/// Simple class to represent a position in the captcha.
class CaptchaPartPosition {
  /// Horizontal position.
  final double x;

  /// Vertical position.
  final double y;

  /// @nodoc
  const CaptchaPartPosition(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaptchaPartPosition &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

/// {@template flutter_captcha_part}
/// A part of the captcha.
/// {@endtemplate}
class FlutterCaptchaPart extends StatefulWidget {
  /// {@template flutter_captcha_part.dimension}
  /// * See also [SizedBox.square].
  /// {@endtemplate}
  final double dimension;

  /// Desired widget to be used.
  final Widget child;

  /// Callback for when the solution of the captcha changes.
  final ValueChanged<bool>? onSolutionChanged;

  /// {@macro flutter_captcha_part.controller}
  final FlutterCaptchaPartController controller;

  final double size;

  /// Builder for the part of the captcha.
  final FlutterCaptchaPartBuilder? builder;

  /// {@template flutter_captcha_part.childWhenDragging}
  /// Builder for the parts of the captcha when they are moving.
  ///
  /// This builder is used when the part is moving to its solution position.
  ///
  /// See: [Draggable.childWhenDragging].
  /// {@endtemplate}
  final FlutterCaptchaPartBuilder? draggingBuilder;

  /// {@template flutter_captcha_part.feedbackBuilder}
  /// Builder for the parts of the captcha when they are moving.
  ///
  /// See: [Draggable.feedback].
  /// {@endtemplate}
  final FlutterCaptchaPartBuilder? feedbackBuilder;

  /// {@template flutter_flutter_captcha_part.canRotate}
  /// Whether the captcha part can be rotated.
  /// {@endtemplate}
  final bool canRotate;

  /// {@template flutter_captcha_part.canMove}
  /// Whether the captcha parts can be moved.
  /// {@endtemplate}
  final bool canMove;

  /// {@template flutter_captcha_part.moveCurve}
  /// Curve for the movement animation of the parts.
  /// {@endtemplate}
  final Curve moveCurve;

  /// {@template flutter_captcha_part.rotateCurve}
  /// Curve for the rotation animation of the parts.
  /// {@endtemplate}
  final Curve rotateCurve;

  /// {@template flutter_captcha_part.moveDuration}
  /// Duration for the movement animation of the parts.
  /// {@endtemplate}
  final Duration moveDuration;

  /// {@template flutter_captcha_part.rotateDuration}
  /// Duration for the rotation animation of the parts.
  /// {@endtemplate}
  final Duration rotateDuration;

  /// @nodoc
  const FlutterCaptchaPart({
    required this.moveCurve,
    required this.rotateCurve,
    required this.dimension,
    required this.child,
    required this.controller,
    required this.size,
    required this.canRotate,
    required this.canMove,
    required this.moveDuration,
    required this.rotateDuration,
    this.onSolutionChanged,
    this.draggingBuilder,
    this.feedbackBuilder,
    this.builder,
    super.key,
  });

  @override
  State<FlutterCaptchaPart> createState() => _FlutterCaptchaPartState();
}

class _FlutterCaptchaPartState extends State<FlutterCaptchaPart> {
  bool _isDragging = false;

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
    var result = widget.canMove
        ? DragTarget<FlutterCaptchaPartController>(
            onWillAccept: (data) => widget.controller._canMove(data!._position),
            onAcceptWithDetails: (details) =>
                widget.controller.maybeSwapPositions(details.data),
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
          duration: widget.rotateDuration,
          curve: widget.rotateCurve,
          turns: widget.controller.angle.value,
          child: result,
        ),
      );
    }

    if (widget.canMove) {
      result = AbsorbPointer(
        absorbing: _isDragging,
        child: Draggable(
          onDragEnd: (_) => setState(() => _isDragging = false),
          onDragStarted: () => setState(() => _isDragging = true),
          data: widget.controller,
          childWhenDragging: widget.draggingBuilder?.call(
                  context,
                  Transform.rotate(
                    angle:
                        widget.controller.angle.absoluteValue * (2 * math.pi),
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
        ),
      );
    }

    return AnimatedPositioned(
      onEnd: () => widget.controller.isBusy = false,
      curve: widget.moveCurve,
      top: widget.controller.position.y,
      left: widget.controller.position.x,
      duration: widget.moveDuration,
      child: ClipPath(child: result),
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

/// {@template flutter_captcha_part.controller}
/// Controller for a [FlutterCaptchaPart].
/// {@endtemplate}
class FlutterCaptchaPartController extends ChangeNotifier {
  FlutterCaptchaPartController({
    required CaptchaPartPosition startPosition,
    required CaptchaPartPosition solutionPosition,
    required Angle angle,
    required this.imageBytes,
  })  : _position = startPosition,
        _solutionPosition = solutionPosition,
        _angle = angle;

  final CaptchaPartPosition _solutionPosition;
  final Uint8List imageBytes;

  /// true if align animation is playing
  /// to prevent unwanted collisions
  bool isBusy = false;

  CaptchaPartPosition _position;
  CaptchaPartPosition get position => _position;
  set position(CaptchaPartPosition position) {
    if (!_canMove(position)) return;

    isBusy = true;
    _position = position;
    notifyListeners();
  }

  Angle _angle;
  Angle get angle => _angle;

  /// Whether the part is in its solution position.
  bool get isSolved => _angle.isSolved && _position == _solutionPosition;

  /// A part can move to a position if it is not busy and the position is not
  /// the current position.
  void maybeSwapPositions(FlutterCaptchaPartController other) {
    if (isBusy || other.isBusy) return;

    final changeableNewPosition = other.position;
    other.position = position;
    position = changeableNewPosition;

    if (changeableNewPosition != other.position) {}
  }

  /// Rotate the part by 90 degrees.
  void turn() {
    _angle = _angle + Angle.quarter();
    notifyListeners();
  }

  bool _canMove(CaptchaPartPosition alignment) => alignment != _position;
}
