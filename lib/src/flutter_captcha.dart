import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_captcha/src/flutter_captcha_image.dart';
import 'dart:math' as math;
import 'package:flutter_captcha/src/flutter_captcha_input.dart';
import 'package:flutter_captcha/src/flutter_captcha_part.dart';

typedef FlutterCaptchaParts = Map<FlutterCaptchaPartPosition, Uint8List>;

final class FlutterCaptcha extends StatefulWidget {
  const FlutterCaptcha({
    required this.size,
    required this.controller,
    this.splitMultiplier = 2,
    this.canRotate = true,
    this.canMove = true,
    this.preferIsolate = true,
    this.partsBuilder,
    this.progressBuilder,
    this.whenMovingBuilder,
    this.feedbackBuilder,
    super.key,
  });

  final int splitMultiplier;
  final double size;
  final FlutterCaptchaPartBuilder? partsBuilder;
  final FlutterCaptchaPartBuilder? whenMovingBuilder;
  final FlutterCaptchaPartBuilder? feedbackBuilder;
  final WidgetBuilder? progressBuilder;
  final FlutterCaptchaController controller;
  final bool canRotate;
  final bool canMove;
  final bool preferIsolate;

  @override
  State<FlutterCaptcha> createState() => _FlutterCaptchaState();
}

final class _FlutterCaptchaState extends State<FlutterCaptcha> {
  final _partControllers = FlutterCaptchaPartsControllers();

  @override
  void initState() {
    super.initState();

    _partControllers.addListener(_rebuild);
    widget.controller
      .._bind(this)
      .._takeNextInput();
  }

  @override
  void didUpdateWidget(FlutterCaptcha oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.splitMultiplier != widget.splitMultiplier ||
        oldWidget.size != widget.size ||
        oldWidget.canMove != widget.canMove ||
        oldWidget.canRotate != widget.canRotate) {
      widget.controller._softReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_partControllers.value.isEmpty) {
      return SizedBox.square(
        dimension: widget.size,
        child: widget.progressBuilder != null
            ? Builder(builder: widget.progressBuilder!)
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final partSize = _partSize();

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: Stack(
          children: [
            for (final controller in _partControllers.value)
              FlutterCaptchaPart(
                canMove: widget.canMove,
                canRotate: widget.canRotate,
                builder: widget.partsBuilder,
                dimension: widget.size,
                controller: controller,
                whenMovingBuilder: widget.whenMovingBuilder,
                feedbackBuilder: widget.feedbackBuilder,
                size: partSize,
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
    _partControllers.dispose();
  }

  void _rebuild() => setState(() {});

  double _partSize() {
    final partsCount = widget.splitMultiplier * widget.splitMultiplier;
    final scaleFactor = widget.size / MediaQuery.of(context).size.width;
    final partSize = widget.size / math.sqrt(partsCount) * scaleFactor;

    return partSize;
  }
}

final class FlutterCaptchaController {
  FlutterCaptchaController({
    List<FlutterCaptchaInput> inputs = const [],
  }) : _inputs = inputs;

  List<FlutterCaptchaInput> _inputs;
  int _currentInputIndex = 0;

  FlutterCaptchaImage? _currentImage;
  _FlutterCaptchaState? _state;

  _FlutterCaptchaState get _safeState => _state!;
  FlutterCaptchaPartsControllers get _partControllers =>
      _safeState._partControllers;

  bool get _canTakeNextInput => _currentInputIndex != _inputs.length - 1;

  bool checkSolution() => _partControllers.isSolved;

  Future<void> requestNextInput() async {
    if (!_canTakeNextInput) return;

    _partControllers.reset();

    return _takeNextInput();
  }

  Future<void> restart({
    List<FlutterCaptchaInput>? inputs,
  }) =>
      _hardReset(inputs: inputs);

  void dispose() {
    _unbind();
    _partControllers.dispose();
    _currentImage = null;
    _inputs.clear();
  }

  void _bind(_FlutterCaptchaState state) {
    assert(_state == null);

    _state = state;
  }

  void _unbind() => _state = null;

  Future<void> _takeNextInput() async {
    assert(_canTakeNextInput);

    final imageParts = await _splitInput(
      _inputs[_currentInputIndex++],
    );
    _preparePartControllers(imageParts);
  }

  Future<FlutterCaptchaParts> _splitInput(
    FlutterCaptchaInput input,
  ) async {
    _currentImage = await input.createImage();

    return _currentImage!.split(
      size: _safeState.widget.size,
      splitMultiplier: _safeState.widget.splitMultiplier,
      preferIsolate: _safeState.widget.preferIsolate,
    );
  }

  void _preparePartControllers(FlutterCaptchaParts images) =>
      _partControllers.init(
        images,
        shufflePositions: _safeState.widget.canMove,
        shuffleAngles: _safeState.widget.canRotate,
      );

  Future<void> _softReset() async {
    _partControllers.reset();

    return _preparePartControllers(
      await _currentImage!.split(
        size: _safeState.widget.size,
        splitMultiplier: _safeState.widget.splitMultiplier,
        preferIsolate: _safeState.widget.preferIsolate,
      ),
    );
  }

  Future<void> _hardReset({
    List<FlutterCaptchaInput>? inputs,
  }) {
    _partControllers.reset();
    _currentInputIndex = 0;
    _currentImage = null;

    if (inputs != null) _inputs = inputs;

    return _takeNextInput();
  }
}
