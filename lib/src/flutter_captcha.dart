import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;
import 'angle.dart';

part 'flutter_captcha_part.dart';

typedef FlutterCaptchaCrossLine = ({
  double width,
  Color color,
});

/// {@template flutter_captcha}
/// A captcha widget for flutter.
///
/// This widget will split an image into parts and the user will have to solve
/// the puzzle by moving or rotating the parts to their correct positions.
/// {@endtemplate}
final class FlutterCaptcha extends StatefulWidget {
  final Widget child;

  /// Captcha will be split into [splitSize]x[splitSize] parts.
  ///
  /// For example, if size is 2, the captcha will contain 4 parts.
  final int splitSize;

  /// {@macro flutter_captcha_part.dimension}
  final double dimension;

  /// Builder for the parts of the captcha.
  final FlutterCaptchaPartBuilder? partsBuilder;

  /// {@macro flutter_captcha_part.childWhenDragging}}
  final FlutterCaptchaPartBuilder? draggingBuilder;

  /// {@macro flutter_captcha_part.feedbackBuilder}
  final FlutterCaptchaPartBuilder? feedbackBuilder;

  /// {@macro flutter_flutter_captcha_part.canRotate}
  final bool canRotate;

  /// {@macro flutter_captcha_part.canMove}
  final bool canMove;

  /// {@macro flutter_captcha_part.moveCurve}
  final Curve moveCurve;

  /// {@macro flutter_captcha_part.rotateCurve}
  final Curve rotateCurve;

  /// {@macro flutter_captcha_part.moveDuration}}
  final Duration moveDuration;

  /// {@macro flutter_captcha_part.rotateDuration}
  final Duration rotateDuration;

  final BoxFit? fit;

  /// The cross line that will be drawn over the captcha.
  final FlutterCaptchaCrossLine? crossLine;

  const FlutterCaptcha({
    required this.child,
    required this.dimension,
    this.moveCurve = Curves.fastOutSlowIn,
    this.rotateCurve = Curves.fastOutSlowIn,
    this.moveDuration = const Duration(milliseconds: 400),
    this.rotateDuration = const Duration(milliseconds: 250),
    this.splitSize = 2,
    this.canRotate = true,
    this.canMove = true,
    this.fit,
    this.partsBuilder,
    this.draggingBuilder,
    this.feedbackBuilder,
    this.crossLine = (color: Colors.white, width: 10.0),
    super.key,
  })  : assert(splitSize > 1, 'splitSize must be greater than 1'),
        assert(dimension > 0, 'dimension must be greater than 0');

  FlutterCaptcha.image({
    required ImageProvider image,
    required this.dimension,
    this.moveCurve = Curves.fastOutSlowIn,
    this.rotateCurve = Curves.fastOutSlowIn,
    this.moveDuration = const Duration(milliseconds: 400),
    this.rotateDuration = const Duration(milliseconds: 250),
    this.splitSize = 2,
    this.canRotate = true,
    this.canMove = true,
    this.partsBuilder,
    this.draggingBuilder,
    this.feedbackBuilder,
    this.fit,
    ImageFrameBuilder? frameBuilder,
    ImageLoadingBuilder? loadingBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    bool excludeFromSemantics = false,
    String? semanticLabel,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? imageFit,
    Alignment alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    FilterQuality filterQuality = FilterQuality.low,
    this.crossLine = (color: Colors.white, width: 10.0),
    super.key,
  }) : child = Image(
          image: image,
          frameBuilder: frameBuilder,
          loadingBuilder: loadingBuilder,
          errorBuilder: errorBuilder,
          semanticLabel: semanticLabel,
          excludeFromSemantics: excludeFromSemantics,
          width: width,
          height: height,
          color: color,
          opacity: opacity,
          colorBlendMode: colorBlendMode,
          fit: imageFit,
          alignment: alignment,
          repeat: repeat,
          centerSlice: centerSlice,
          matchTextDirection: matchTextDirection,
          gaplessPlayback: gaplessPlayback,
          isAntiAlias: isAntiAlias,
          filterQuality: filterQuality,
        );

  @override
  State<FlutterCaptcha> createState() => FlutterCaptchaState();
}

final class FlutterCaptchaState extends State<FlutterCaptcha> {
  final _random = math.Random();

  @visibleForTesting
  final controllers = <FlutterCaptchaPartController>[];

  @visibleForTesting
  CaptchaPartPositions? currentPositions;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _init(),
    );
  }

  @override
  void didUpdateWidget(FlutterCaptcha oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.splitSize != widget.splitSize ||
        oldWidget.dimension != widget.dimension) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => _init(),
      );

      return;
    }

    if (oldWidget.canMove != widget.canMove ||
        oldWidget.canRotate != widget.canRotate) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => reset(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.dimension,
        child: Stack(
          children: [
            for (final controller in controllers)
              FlutterCaptchaPart(
                key: ObjectKey(controller),
                canMove: widget.canMove,
                canRotate: widget.canRotate,
                builder: widget.partsBuilder,
                controller: controller,
                draggingBuilder: widget.draggingBuilder,
                feedbackBuilder: widget.feedbackBuilder,
                moveCurve: widget.moveCurve,
                rotateCurve: widget.rotateCurve,
                moveDuration: widget.moveDuration,
                rotateDuration: widget.rotateDuration,
                fit: widget.fit,
                crossLine: widget.crossLine,
                child: widget.child,
              ),
            if (widget.crossLine != null)
              IgnorePointer(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    return CustomPaint(
                      size: Size.square(constraints.biggest.shortestSide),
                      painter: _CrossLinePainter(
                        width: widget.crossLine!.width,
                        count: widget.splitSize,
                        color: widget.crossLine!.color,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _releaseControllers();

    currentPositions = null;
    super.dispose();
  }

  /// Whether the captcha is solved.
  bool checkSolution() =>
      controllers.isNotEmpty && controllers.every((e) => e.solved);

  /// Resets the captcha.
  ///
  /// This will reshuffle positions and angles.
  void reset() => _init(positions: currentPositions!);

  /// Set positions and angles to their solved values.
  void solve() {
    for (var controller in controllers) {
      controller._solve();
    }
  }

  void _init({CaptchaPartPositions? positions}) {
    final dimension = math.min(widget.dimension, context.size!.shortestSide);
    final partSize = dimension / widget.splitSize;

    final newPositions = currentPositions = positions ??
        _createPositions(
          dimension: dimension,
          partSize: partSize,
        );

    _setupControllers(
      positions: newPositions,
      dimension: dimension,
      partSize: partSize,
    );

    setState(() {});
  }

  void _setupControllers({
    required CaptchaPartPositions positions,
    required double dimension,
    required double partSize,
  }) {
    final solutionPositions = positions.toList(growable: false);
    final startPositions = positions.toList(growable: false);
    final angles = Angle.all();

    if (widget.canMove) startPositions.shuffle(_random);

    assert(startPositions.length == solutionPositions.length);

    final canUpdateControllers = controllers.length == positions.length;
    if (!canUpdateControllers) _releaseControllers();

    for (var i = 0; i < solutionPositions.length; i++) {
      final startPosition = startPositions[i];
      final solutionPosition = solutionPositions[i];

      final angle =
          widget.canRotate ? _createRandomAngle(angles) : Angle.zero();
      final layout = (dimension: dimension, size: partSize);

      canUpdateControllers
          ? controllers[i]._update(
              position: startPosition,
              solutionPosition: solutionPosition,
              angle: angle,
              layout: layout,
            )
          : controllers.add(
              FlutterCaptchaPartController(
                angle: angle,
                startPosition: startPosition,
                solutionPosition: solutionPosition,
                layout: layout,
              ),
            );
    }
  }

  CaptchaPartPositions _createPositions({
    required double dimension,
    required double partSize,
  }) {
    final width = partSize, height = partSize;
    final splitSize = widget.splitSize;
    final partsCount = splitSize * splitSize;

    final output = <CaptchaPartPosition>[];

    for (var i = 0; i < partsCount; i++) {
      final x = (i % splitSize) * width;
      final y = (i ~/ splitSize) * height;

      output.add((x: x, y: y));
    }

    return output;
  }

  void _releaseControllers() {
    for (var element in controllers) {
      element.dispose();
    }
    controllers.clear();
  }

  Angle _createRandomAngle(List<Angle> angles) {
    final angleIndex = _random.nextInt(angles.length);

    return angles[angleIndex];
  }
}

class _CrossLinePainter extends CustomPainter {
  final double width;
  final int count;
  final Color color;

  const _CrossLinePainter({
    required this.width,
    required this.count,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / count;
    final double cellHeight = size.height / count;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width;

    for (var i = 1; i < count; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (var i = 1; i < count; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0.0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_CrossLinePainter oldDelegate) =>
      oldDelegate.width != width;
}
