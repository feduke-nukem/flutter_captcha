import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_captcha/src/flutter_captcha_angle.dart';
import 'package:flutter_captcha/src/flutter_captcha_image.dart';
import 'package:flutter_captcha/src/flutter_captcha_split.dart';
import 'dart:math' as math;
import 'package:collection/collection.dart';

const _opacityDuration = Duration(milliseconds: 460);
const _curve = Curves.fastOutSlowIn;
const _unsolvedOpacity = 0.4;
const _solvedOpacity = 1.0;

typedef _OnPositionChanged = void Function(
  _PartController changer,
  _PartController changeable,
);

final class FlutterCaptcha extends StatefulWidget {
  const FlutterCaptcha({
    required this.assets,
    this.cropAndCenter = true,
    this.imageProviders = const [],
    this.split = const FlutterCaptchaSplit.twoByTwo(),
    super.key,
  });

  final bool cropAndCenter;
  final FlutterCaptchaSplit split;
  final List<String> assets;
  final List<ImageProvider> imageProviders;

  @override
  State<FlutterCaptcha> createState() => _FlutterCaptchaState();
}

final class _FlutterCaptchaState extends State<FlutterCaptcha> {
  final _controllers = <Alignment, _PartController>{};
  late MediaQueryData _mediaQueryData;
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mediaQueryData = MediaQuery.of(context);
  }

  @override
  void didUpdateWidget(covariant FlutterCaptcha oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.split != widget.split || oldWidget.assets != widget.assets) {
      _reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (_, constraints) {
          if (_controllers.isEmpty) {
            return const CircularProgressIndicator();
          }

          final count = widget.split.count;
          final partSize = constraints.maxHeight / math.sqrt(count);

          return Stack(
            children: _controllers.values
                .mapIndexed(
                  (i, e) => _Part(
                    controller: e,
                    size: partSize,
                    onPositionChanged: _onPositionChanged,
                    child: SizedBox.square(
                      dimension: partSize,
                      child: Image.memory(
                        e.imageBytes,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  void _reset() {
    _controllers.clear();
    _init();
  }

  Future<void> _init() async {
    _initControllers(await _splitImages());
    setState(() {});
  }

  Future<Map<Alignment, Uint8List>> _splitImages() async {
    final image = await FlutterCaptchaImage.fromAsset(widget.assets.first);
    final query = _mediaQueryData;

    if (widget.cropAndCenter) {
      return image.splitWithDimension(
        split: widget.split,
        dimension: query.size.width,
      );
    }

    return image.split(split: widget.split);
  }

  void _initControllers(Map<Alignment, Uint8List> images) {
    final random = math.Random.secure();
    final randomAlignments = List<Alignment>.from(widget.split.alignments);
    final angles = FlutterCaptchaAngle.allAngles();
    final alignments = widget.split.alignments;

    angles.shuffle(random);
    randomAlignments.shuffle(random);

    for (int i = 0; i < alignments.length; i++) {
      final randomAlignment = randomAlignments[i];
      final alignment = alignments[i];
      final randomAngleIndex = random.nextInt(angles.length);

      _controllers[alignment] = _PartController(
        imageBytes: images[alignment]!,
        split: widget.split,
        angle: angles[randomAngleIndex],
        startPosition: randomAlignment,
        solutionPosition: alignment,
      );
    }
  }

  void _onPositionChanged(
    _PartController changer,
    _PartController changeable,
  ) {
    if (changeable.isBusy || changer.isBusy) return;

    final changeableNewPosition = changer.position;
    changer.position = changeable.position;
    changeable.position = changeableNewPosition;

    if (changeableNewPosition != changer.position) {
      // widget.onPartSolutionChanged?.call(changer.isSolved);
    }
    _checkSolution();
  }

  void _checkSolution() {
    final isSolved = _controllers.values.every((element) => element.isSolved);

    if (!isSolved) return;

    // setState(() {
    //   _isSolved = isSolved;
    //   widget.onSolved?.call();
    // });
  }
}

class _PartController extends ChangeNotifier
    implements ValueListenable<_PartController> {
  _PartController({
    required this.split,
    required Alignment startPosition,
    required Alignment solutionPosition,
    required FlutterCaptchaAngle angle,
    required this.imageBytes,
  })  : _position = startPosition,
        _solutionPosition = solutionPosition,
        _angle = angle {
    _checkSolution();
  }

  final Alignment _solutionPosition;
  final FlutterCaptchaSplit split;
  final Uint8List imageBytes;

  /// true if align animation is playing
  /// to prevent unwanted collisions
  bool isBusy = false;

  @override
  _PartController get value => this;

  Alignment _position;
  Alignment get position => _position;
  set position(Alignment position) {
    if (!_canMove(position)) return;

    isBusy = true;
    _position = position;
    _checkSolution();
    notifyListeners();
  }

  FlutterCaptchaAngle _angle;
  FlutterCaptchaAngle get angle => _angle;
  void turn() {
    _angle = _angle.turn();
    _checkSolution();
    notifyListeners();
  }

  double get opacity => _opacity;
  bool _isSolved = false;
  bool get isSolved => _isSolved;

  double _opacity = _unsolvedOpacity;

  void _checkSolution() {
    final isSolved = _angle.isSolved && _position == _solutionPosition;

    if (!isSolved) {
      _opacity = _unsolvedOpacity;

      return;
    }
    _isSolved = true;
    _opacity = _solvedOpacity;
  }

  bool _canMove(Alignment alignment) => alignment != _position;
}

class _Part extends StatefulWidget {
  final Widget child;
  final ValueChanged<bool>? onSolutionChanged;
  final bool canInterract;
  final _OnPositionChanged? onPositionChanged;
  final _PartController controller;
  final double size;

  const _Part({
    required this.child,
    required this.controller,
    required this.size,
    this.onPositionChanged,
    this.canInterract = true,
    this.onSolutionChanged,
    super.key,
  });

  @override
  State<_Part> createState() => _PartState();
}

class _PartState extends State<_Part> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<_PartController>(
        valueListenable: widget.controller,
        builder: (_, controller, __) {
          return AnimatedAlign(
            onEnd: () {
              controller.isBusy = false;
            },
            curve: _curve,
            alignment: controller.position,
            duration:
                _isDragging ? Duration.zero : const Duration(milliseconds: 400),
            child: AbsorbPointer(
              absorbing: !widget.canInterract,
              child: Draggable(
                onDragStarted: () => setState(() => _isDragging = true),
                onDragEnd: (_) => setState(() => _isDragging = false),
                data: controller,
                childWhenDragging: SizedBox.square(
                  dimension: widget.size,
                ),
                feedback: _FeedbackPart(
                  controller: controller,
                  child: widget.child,
                ),
                child: GestureDetector(
                  onTap: _rotate,
                  child: AnimatedRotation(
                    filterQuality: FilterQuality.medium,
                    duration: const Duration(milliseconds: 250),
                    curve: _curve,
                    turns: controller.angle.value,
                    child: AnimatedOpacity(
                      opacity: controller.opacity,
                      duration: _opacityDuration,
                      curve: _curve,
                      child: DragTarget<_PartController>(
                        onWillAccept: (data) =>
                            controller._canMove(data!._position),
                        onAcceptWithDetails: (details) {
                          widget.onPositionChanged?.call(
                            details.data,
                            controller,
                          );
                        },
                        builder: (context, _, __) {
                          return widget.child;
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _rotate() {
    widget.controller.turn();

    widget.onSolutionChanged?.call(widget.controller.isSolved);
  }
}

class _FeedbackPart extends StatelessWidget {
  final _PartController controller;
  final Widget child;

  const _FeedbackPart({
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_PartController>(
      valueListenable: controller,
      builder: (_, data, __) => AnimatedOpacity(
        duration: _opacityDuration,
        curve: _curve,
        opacity: data.opacity,
        child: Transform.rotate(
          angle: (data.angle * 2 * math.pi).value,
          child: child,
        ),
      ),
    );
  }
}
