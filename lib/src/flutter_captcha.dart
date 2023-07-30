import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  /// The width and height of widget.
  ///
  /// See also [SizedBox.square]
  ///
  /// If it's `null` the [BoxConstraints.biggest] and [Size.shortestSide] will
  /// be used instead within [LayoutBuilder]
  final double? dimension;

  /// Builder for the parts of the captcha.
  final FlutterCaptchaPartBuilder? partsBuilder;

  /// {@macro flutter_captcha_part.childWhenDragging}}
  final FlutterCaptchaPartBuilder? draggingBuilder;

  /// {@macro flutter_captcha_part.feedbackBuilder}
  final FlutterCaptchaPartBuilder? feedbackBuilder;

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

  final FlutterCaptchaController controller;

  const FlutterCaptcha({
    required this.child,
    required this.controller,
    this.moveCurve = Curves.fastOutSlowIn,
    this.rotateCurve = Curves.fastOutSlowIn,
    this.moveDuration = const Duration(milliseconds: 400),
    this.rotateDuration = const Duration(milliseconds: 250),
    this.fit,
    this.partsBuilder,
    this.draggingBuilder,
    this.feedbackBuilder,
    this.crossLine = (color: Colors.white, width: 10.0),
    this.dimension,
    super.key,
  });

  FlutterCaptcha.image({
    required ImageProvider image,
    required this.controller,
    this.moveCurve = Curves.fastOutSlowIn,
    this.rotateCurve = Curves.fastOutSlowIn,
    this.moveDuration = const Duration(milliseconds: 400),
    this.rotateDuration = const Duration(milliseconds: 250),
    this.crossLine = (color: Colors.white, width: 10.0),
    this.partsBuilder,
    this.draggingBuilder,
    this.feedbackBuilder,
    this.fit,
    this.dimension,
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
  State<FlutterCaptcha> createState() => _FlutterCaptchaState();
}

final class _FlutterCaptchaState extends State<FlutterCaptcha> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant FlutterCaptcha oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (_, constraints) {
          final dimension =
              widget.dimension ?? constraints.biggest.shortestSide;
          final partSize = dimension / widget.controller.splitSize;

          return SizedBox.square(
            dimension: dimension,
            child: Stack(
              children: [
                for (final controller in widget.controller.controllers)
                  FlutterCaptchaPart(
                    key: ObjectKey(controller),
                    layout: (dimension: dimension, size: partSize),
                    canMove: widget.controller.randomizePositions,
                    canRotate: widget.controller.randomizeAngles,
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
                    child: CustomPaint(
                      size: Size.square(constraints.biggest.shortestSide),
                      painter: _CrossLinePainter(
                        crossLine: widget.crossLine!,
                        count: widget.controller.splitSize,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _rebuild() => setState(() {});
}

/// Controller for [FlutterCaptcha]
final class FlutterCaptchaController extends ChangeNotifier {
  final math.Random _random;

  int _splitSize;

  /// Captcha will be split into [splitSize]x[splitSize] parts.
  ///
  /// For example, if size is 2, the captcha will contain 4 parts.
  int get splitSize => _splitSize;
  set splitSize(int value) {
    if (_splitSize == value) return;

    _splitSize = value;
    _init();
  }

  bool _randomizeAngles;

  /// Whether the angles will be randomized.
  ///
  /// If `true` - captcha parts can be rotated.
  bool get randomizeAngles => _randomizeAngles;
  set randomizeAngles(bool value) {
    if (_randomizeAngles == value) return;

    _randomizeAngles = value;
    reset();
  }

  bool _randomizePositions;

  /// Whether the positions will be randomized.
  ///
  /// If `true` - captcha parts can be moved.
  bool get randomizePositions => _randomizePositions;
  set randomizePositions(bool value) {
    if (_randomizePositions == value) return;

    _randomizePositions = value;
    reset();
  }

  @visibleForTesting
  final controllers = <FlutterCaptchaPartController>[];

  @visibleForTesting
  CaptchaPartPositions? currentPositions;

  FlutterCaptchaController({
    int splitSize = 2,
    bool randomizeAngles = true,
    bool randomizePositions = true,
    math.Random? random,
  })  : assert(splitSize > 1, 'splitSize must be greater than 1'),
        _splitSize = splitSize,
        _randomizeAngles = randomizeAngles,
        _randomizePositions = randomizePositions,
        _random = random ?? math.Random();

  @override
  void dispose() {
    _releaseControllers();
    currentPositions = null;
    super.dispose();
  }

  void init() => _init();

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
    final newPositions = currentPositions = positions ?? _createPositions();

    _setupControllers(newPositions);

    notifyListeners();
  }

  void _setupControllers(CaptchaPartPositions positions) {
    final solutionPositions = positions.toList(growable: false);
    final startPositions = positions.toList(growable: false);
    final angles = Angle.all();

    if (_randomizePositions) startPositions.shuffle(_random);

    assert(startPositions.length == solutionPositions.length);

    final canUpdateControllers = controllers.length == positions.length;
    if (!canUpdateControllers) _releaseControllers();

    for (var i = 0; i < solutionPositions.length; i++) {
      final startPosition = startPositions[i];
      final solutionPosition = solutionPositions[i];

      final angle =
          _randomizeAngles ? _createRandomAngle(angles) : Angle.zero();

      canUpdateControllers
          ? controllers[i]._update(
              position: startPosition,
              solutionPosition: solutionPosition,
              angle: angle,
            )
          : controllers.add(
              FlutterCaptchaPartController(
                angle: angle,
                startPosition: startPosition,
                solutionPosition: solutionPosition,
              ),
            );
    }
  }

  CaptchaPartPositions _createPositions() {
    final count = _splitSize * _splitSize;

    final output = <CaptchaPartPosition>[];

    for (var i = 0; i < count; i++) {
      final x = (i % _splitSize);
      final y = (i ~/ _splitSize);

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
  final FlutterCaptchaCrossLine crossLine;
  final int count;

  const _CrossLinePainter({
    required this.crossLine,
    required this.count,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / count;
    final double cellHeight = size.height / count;

    final paint = Paint()
      ..color = crossLine.color
      ..strokeWidth = crossLine.width;

    for (var i = 1; i < count; i++) {
      final y = i * cellHeight;
      final x = i * cellWidth;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      canvas.drawLine(Offset(x, 0.0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_CrossLinePainter oldDelegate) =>
      oldDelegate.crossLine != crossLine || oldDelegate.count != count;
}
