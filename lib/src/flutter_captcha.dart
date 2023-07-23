import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_captcha/src/flutter_captcha_input.dart';
import 'package:flutter_captcha/src/flutter_captcha_part.dart';

import 'angle.dart';

/// {@template flutter_captcha}
/// A captcha widget for flutter.
///
/// This widget will split an image into parts and the user will have to solve
/// the puzzle by moving or rotating the parts to their correct positions.
/// {@endtemplate}
final class FlutterCaptcha extends StatefulWidget {
  const FlutterCaptcha({
    required this.dimension,
    required this.controller,
    this.moveCurve = Curves.fastOutSlowIn,
    this.rotateCurve = Curves.fastOutSlowIn,
    this.moveDuration = const Duration(milliseconds: 400),
    this.rotateDuration = const Duration(milliseconds: 250),
    this.size = 2,
    this.canRotate = true,
    this.canMove = true,
    this.preferIsolate = true,
    this.partsBuilder,
    this.progressBuilder,
    this.draggingBuilder,
    this.feedbackBuilder,
    super.key,
  });

  /// Size of the captcha in terms of number of parts.
  ///
  /// For example, if size is 2, the captcha will be 2x2 parts.
  final int size;

  /// {@macro flutter_captcha_part.dimension}
  final double dimension;

  /// Builder for the parts of the captcha.
  final FlutterCaptchaPartBuilder? partsBuilder;

  /// {@macro flutter_captcha_part.childWhenDragging}}
  final FlutterCaptchaPartBuilder? draggingBuilder;

  /// {@macro flutter_captcha_part.feedbackBuilder}
  final FlutterCaptchaPartBuilder? feedbackBuilder;

  /// Builder for the progress indicator of the captcha when image split is in
  /// progress.
  ///
  /// Splitting the image is an asynchronous operation, so this builder will be
  /// used while the image is being split.
  ///
  /// If this is null, a [CircularProgressIndicator] will be shown.
  final WidgetBuilder? progressBuilder;

  /// {@macro flutter_captcha.controller}
  final FlutterCaptchaController controller;

  /// {@macro flutter_flutter_captcha_part.canRotate}
  final bool canRotate;

  /// {@macro flutter_captcha_part.canMove}
  final bool canMove;

  /// Whether to prefer using isolates when splitting the image.
  final bool preferIsolate;

  /// {@macro flutter_captcha_part.moveCurve}
  final Curve moveCurve;

  /// {@macro flutter_captcha_part.rotateCurve}
  final Curve rotateCurve;

  /// {@macro flutter_captcha_part.moveDuration}}
  final Duration moveDuration;

  /// {@macro flutter_captcha_part.rotateDuration}
  final Duration rotateDuration;

  @override
  State<FlutterCaptcha> createState() => _FlutterCaptchaState();
}

final class _FlutterCaptchaState extends State<FlutterCaptcha> {
  @override
  void initState() {
    super.initState();

    widget.controller
      .._bind(widget)
      ..addListener(_rebuild)
      ..showNextInput();
  }

  @override
  void didUpdateWidget(FlutterCaptcha oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget != widget) widget.controller._bind(widget);

    if (oldWidget.size != widget.size) {
      widget.controller._splitCurrentPartsAndSoftReset();

      return;
    }

    if (oldWidget.dimension != widget.dimension ||
        oldWidget.canMove != widget.canMove ||
        oldWidget.canRotate != widget.canRotate) {
      widget.controller._softReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final partControllers = widget.controller.partControllersMap.values;
    if (partControllers.isEmpty) {
      return SizedBox.square(
        dimension: widget.dimension,
        child: widget.progressBuilder != null
            ? Builder(builder: widget.progressBuilder!)
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final partSize = _partSize();

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.dimension,
        child: Stack(
          children: [
            for (final controller in partControllers)
              FlutterCaptchaPart(
                key: ObjectKey(controller),
                canMove: widget.canMove,
                canRotate: widget.canRotate,
                builder: widget.partsBuilder,
                dimension: widget.dimension,
                controller: controller,
                draggingBuilder: widget.draggingBuilder,
                feedbackBuilder: widget.feedbackBuilder,
                size: partSize,
                moveCurve: widget.moveCurve,
                rotateCurve: widget.rotateCurve,
                moveDuration: widget.moveDuration,
                rotateDuration: widget.rotateDuration,
                child: SizedBox.square(
                  dimension: partSize,
                  child: Image.memory(
                    controller.imageBytes,
                    fit: BoxFit.fill,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    widget.controller._unbind();
  }

  void _rebuild() => setState(() {});

  double _partSize() {
    final partsCount = widget.size * widget.size;
    final scaleFactor = widget.dimension / MediaQuery.of(context).size.width;
    final partSize = widget.dimension / math.sqrt(partsCount) * scaleFactor;

    return partSize;
  }
}

/// {@template flutter_captcha.controller}
/// Controller for the [FlutterCaptcha] widget.
/// {@endtemplate}
final class FlutterCaptchaController extends ChangeNotifier {
  FlutterCaptchaController({
    List<FlutterCaptchaInput> inputs = const [],
  }) : _inputs = inputs;

  final _random = math.Random();

  @visibleForTesting
  final partControllersMap =
      <CaptchaPartPosition, FlutterCaptchaPartController>{};

  List<FlutterCaptchaInput> _inputs;

  @visibleForTesting
  List<FlutterCaptchaInput> get inputs => _inputs;

  @visibleForTesting
  int currentInputIndex = -1;

  @visibleForTesting
  CaptchaParts? currentParts;
  FlutterCaptcha? _widget;

  bool get _canTakeNextInput =>
      _inputs.isNotEmpty && currentInputIndex + 1 < _inputs.length;

  /// Whether the captcha is solved.
  bool checkSolution() =>
      partControllersMap.isNotEmpty &&
      partControllersMap.values.every((element) => element.isSolved);

  /// Move to the next [FlutterCaptchaInput] from the provided [_inputs].
  Future<void> showNextInput() async {
    if (!_canTakeNextInput) return;

    partControllersMap.clear();

    return _acceptInput(_inputs[++currentInputIndex]);
  }

  /// Resets the captcha hardly.
  ///
  /// Starts the captcha from the beginning.
  ///
  /// If [inputs] is not null, the captcha will be reset with the given inputs.
  Future<void> hardReset({List<FlutterCaptchaInput>? inputs}) {
    partControllersMap.clear();
    currentParts = null;

    if (inputs != null) _inputs = inputs;

    return _acceptInput(_inputs[currentInputIndex = 0]);
  }

  /// Resets the captcha softly.
  ///
  /// Resets the captcha with the current inputs.
  void softReset() => _softReset();

  /// @nodoc
  @override
  void dispose() {
    _unbind();
    partControllersMap.clear();
    currentParts = null;
    _inputs.clear();
    super.dispose();
  }

  void _bind(FlutterCaptcha widget) => _widget = widget;

  void _unbind() => _widget = null;

  Future<void> _acceptInput(FlutterCaptchaInput input) async =>
      _initPartControllers(
        currentParts = await _splitInput(input),
        shufflePositions: _widget!.canMove,
        shuffleAngles: _widget!.canRotate,
      );

  Future<CaptchaParts> _splitInput(FlutterCaptchaInput input) async {
    final parts = await input.createImage();

    return parts.split(
      dimension: _widget!.dimension,
      size: _widget!.size,
      preferIsolate: _widget!.preferIsolate,
    );
  }

  void _initPartControllers(
    CaptchaParts seed, {
    required bool shuffleAngles,
    required bool shufflePositions,
  }) {
    final startPositions = seed.keys.toList();
    final solutionPositions = seed.keys.toList();
    final angles = Angle.all();

    if (shufflePositions) startPositions.shuffle(_random);

    assert(startPositions.length == solutionPositions.length);

    for (int i = 0; i < solutionPositions.length; i++) {
      final startPosition = startPositions[i];
      final solutionPosition = solutionPositions[i];

      final angle = shuffleAngles ? _createRandomAngle(angles) : Angle.zero();

      partControllersMap[solutionPosition] = FlutterCaptchaPartController(
        imageBytes: seed[solutionPosition]!,
        angle: angle,
        startPosition: startPosition,
        solutionPosition: solutionPosition,
      );
    }

    notifyListeners();
  }

  Angle _createRandomAngle(List<Angle> angles) {
    final angleIndex = _random.nextInt(angles.length);

    return angles[angleIndex];
  }

  void _softReset() {
    partControllersMap.clear();

    return _initPartControllers(
      currentParts!,
      shufflePositions: _widget!.canMove,
      shuffleAngles: _widget!.canRotate,
    );
  }

  Future<void> _splitCurrentPartsAndSoftReset() async {
    currentParts = await _splitInput(
      _inputs[currentInputIndex],
    );

    _softReset();
  }
}
