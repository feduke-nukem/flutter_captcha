part of 'flutter_captcha.dart';

/// Part position in the captcha.
typedef CaptchaPartPosition = ({
  double x,
  double y,
});
typedef CaptchaLayout = ({
  double dimension,
  double size,
});

typedef CaptchaPartPositions = List<CaptchaPartPosition>;

/// {@template flutter_captcha_part.builder}
/// A builder for the captcha parts.
/// {@endtemplate}
typedef FlutterCaptchaPartBuilder = Widget Function(
  BuildContext context,
  Widget part,
  bool solved,
);

/// {@template flutter_captcha_part}
/// A part of the captcha.
/// {@endtemplate}
class FlutterCaptchaPart extends StatefulWidget {
  /// Desired widget to be used.
  final Widget child;

  /// {@macro flutter_captcha_part.controller}
  final FlutterCaptchaPartController controller;

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

  final BoxFit? fit;

  final FlutterCaptchaCrossLine? crossLine;

  /// @nodoc
  const FlutterCaptchaPart({
    required this.moveCurve,
    required this.rotateCurve,
    required this.child,
    required this.controller,
    required this.canRotate,
    required this.canMove,
    required this.moveDuration,
    required this.rotateDuration,
    this.crossLine,
    this.draggingBuilder,
    this.fit,
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
    var child = widget.builder?.call(
          context,
          widget.child,
          widget.controller.solved,
        ) ??
        widget.child;

    child = _Part(
      dimension: widget.controller._layout.dimension,
      size: widget.controller._layout.size,
      solutionPosition: widget.controller._solutionPosition,
      child: SizedBox.square(
        dimension: widget.controller._layout.size,
        child: widget.fit == null
            ? child
            : FittedBox(
                fit: widget.fit!,
                child: child,
              ),
      ),
    );

    var result = widget.canMove
        ? DragTarget<FlutterCaptchaPartController>(
            onWillAccept: (data) => widget.controller._canMove(data!._position),
            onAcceptWithDetails: (details) =>
                widget.controller.maybeSwapPositions(details.data),
            builder: (context, _, __) => child,
          )
        : child;

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
      final rotated = Transform.rotate(
        angle: widget.controller.angle.absoluteValue * (2 * math.pi),
        child: child,
      );
      final feedback = widget.feedbackBuilder?.call(
            context,
            rotated,
            widget.controller.solved,
          ) ??
          rotated;
      result = AbsorbPointer(
        absorbing: _isDragging,
        child: Draggable(
          onDragEnd: (_) => setState(() => _isDragging = false),
          onDragStarted: () => setState(() => _isDragging = true),
          data: widget.controller,
          childWhenDragging: widget.draggingBuilder?.call(
                context,
                rotated,
                widget.controller.solved,
              ) ??
              rotated,
          feedback: widget.crossLine != null
              ? ClipRect(
                  clipper: _FeedbackClipper(
                    crossLine: widget.crossLine!,
                    layout: widget.controller._layout,
                    position: widget.controller.position,
                  ),
                  child: feedback,
                )
              : feedback,
          child: result,
        ),
      );
    }

    return AnimatedPositioned(
      onEnd: () => widget.controller._isBusy = false,
      curve: widget.moveCurve,
      top: widget.controller.position.y,
      left: widget.controller.position.x,
      duration: widget.moveDuration,
      child: ClipPath(child: result),
    );
  }

  void _rotate() {
    widget.controller.angle += Angle.quarter();
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
    required CaptchaLayout layout,
  })  : _position = startPosition,
        _solutionPosition = solutionPosition,
        _angle = angle,
        _layout = layout;

  CaptchaPartPosition _solutionPosition;
  CaptchaLayout _layout;

  /// True if align animation is playing to prevent unwanted collisions.
  bool _isBusy = false;

  CaptchaPartPosition _position;
  CaptchaPartPosition get position => _position;
  set position(CaptchaPartPosition position) {
    if (!_canMove(position)) return;

    _isBusy = true;
    _position = position;
    notifyListeners();
  }

  Angle _angle;
  Angle get angle => _angle;
  set angle(Angle angle) {
    if (angle == _angle) return;
    _angle = angle;
    notifyListeners();
  }

  /// Whether the part is in its solution position.
  bool get solved => _angle.isZero && _position == _solutionPosition;

  /// A part can move to a position if it is not busy and the position is not
  /// the current position.
  void maybeSwapPositions(FlutterCaptchaPartController other) {
    if (_isBusy || other._isBusy) return;

    final changeableNewPosition = other.position;
    other.position = position;
    position = changeableNewPosition;

    if (changeableNewPosition != other.position) {}
  }

  bool _canMove(CaptchaPartPosition position) => position != _position;

  void _update({
    required CaptchaPartPosition position,
    required CaptchaPartPosition solutionPosition,
    required Angle angle,
    required CaptchaLayout layout,
  }) {
    _position = position;
    _angle = angle;
    _solutionPosition = solutionPosition;
    _layout = layout;
    notifyListeners();
  }

  void _solve() {
    _position = _solutionPosition;
    _angle = Angle.zero();
    notifyListeners();
  }
}

class _Part extends SingleChildRenderObjectWidget {
  final double dimension;
  final double size;
  final CaptchaPartPosition solutionPosition;

  const _Part({
    required this.dimension,
    required this.size,
    required this.solutionPosition,
    required super.child,
  });

  @override
  _RenderPart createRenderObject(BuildContext context) => _RenderPart(
        dimension: dimension,
        partSize: size,
        position: solutionPosition,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderPart renderObject) {
    renderObject
      ..dimension = dimension
      ..partSize = size
      ..solutionPosition = solutionPosition;
  }
}

class _RenderPart extends RenderProxyBox {
  double _dimension;
  set dimension(double value) {
    if (_dimension == value) return;

    _dimension = value;
    markNeedsLayout();
  }

  double _partSize;
  set partSize(double value) {
    if (_partSize == value) return;

    _partSize = value;
    markNeedsLayout();
  }

  CaptchaPartPosition _solutionPosition;
  set solutionPosition(CaptchaPartPosition value) {
    if (_solutionPosition == value) return;

    _solutionPosition = value;
    markNeedsLayout();
  }

  _RenderPart({
    required double dimension,
    required double partSize,
    required CaptchaPartPosition position,
  })  : _solutionPosition = position,
        _dimension = dimension,
        _partSize = partSize;

  @override
  void performLayout() {
    super.performLayout();

    child!.layout(
      BoxConstraints.tightFor(
        width: _dimension,
        height: _dimension,
      ),
      parentUsesSize: true,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    layer = context.pushClipRect(
      needsCompositing,
      offset,
      Rect.fromLTWH(0, 0, _partSize, _partSize),
      (context, offset) {
        context.canvas.translate(-_solutionPosition.x, -_solutionPosition.y);
        super.paint(context, offset);
      },
      oldLayer: layer as ClipRectLayer?,
    );
  }
}

class _FeedbackClipper extends CustomClipper<Rect> {
  final FlutterCaptchaCrossLine crossLine;
  final CaptchaPartPosition position;
  final CaptchaLayout layout;

  const _FeedbackClipper({
    required this.crossLine,
    required this.position,
    required this.layout,
  });

  @override
  Rect getClip(Size size) {
    final isPositiveX = position.x > 0;
    final isPositiveY = position.y > 0;
    final isAtBoundaryX =
        isPositiveX && position.x != layout.dimension - layout.size;
    final isAtBoundaryY =
        isPositiveY && position.y != layout.dimension - layout.size;
    final clipValue = crossLine.width / 2;

    final top = isPositiveY ? clipValue : 0.0;
    final left = isPositiveX ? clipValue : 0.0;
    final bottom = isAtBoundaryY || position.y == 0 ? clipValue : 0.0;
    final right = isAtBoundaryX || position.x == 0 ? clipValue : 0.0;

    return Rect.fromLTRB(
      left,
      top,
      layout.size - right,
      layout.size - bottom,
    );
  }

  @override
  bool shouldReclip(_FeedbackClipper oldClipper) =>
      oldClipper.crossLine != crossLine ||
      oldClipper.position != position ||
      oldClipper.layout != layout;
}
