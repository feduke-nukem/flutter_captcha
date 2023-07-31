part of 'flutter_captcha.dart';

/// Part point in the captcha.
typedef CaptchaPoint = ({
  int x,
  int y,
});
typedef CaptchaLayout = ({
  double dimension,
  double size,
});

typedef CaptchaPoints = List<CaptchaPoint>;

/// {@template flutter_captcha_part.builder}
/// A builder for the captcha parts.
/// {@endtemplate}
typedef FlutterCaptchaPartBuilder = Widget Function(
  BuildContext context,
  Widget part,
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

  final CaptchaLayout layout;

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
    required this.layout,
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
        ) ??
        widget.child;

    child = _Part(
      dimension: widget.layout.dimension,
      size: widget.layout.size,
      solutionPoint: widget.controller._solutionPoint,
      child: SizedBox.square(
        dimension: widget.layout.size,
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
            onWillAccept: (data) => widget.controller._canMove(data!._point),
            onAcceptWithDetails: (details) =>
                widget.controller.maybeSwapPoints(details.data),
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
              ) ??
              rotated,
          feedback: widget.crossLine != null
              ? ClipRect(
                  clipper: _FeedbackClipper(
                    crossLine: widget.crossLine!,
                    layout: widget.layout,
                    point: widget.controller.point,
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
      top: widget.layout.size * widget.controller.point.y,
      left: widget.layout.size * widget.controller.point.x,
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
    required CaptchaPoint startPoint,
    required CaptchaPoint solutionPoint,
    required Angle angle,
  })  : _point = startPoint,
        _solutionPoint = solutionPoint,
        _angle = angle;

  CaptchaPoint _solutionPoint;

  /// True if align animation is playing to prevent unwanted collisions.
  bool _isBusy = false;

  CaptchaPoint _point;
  CaptchaPoint get point => _point;
  set point(CaptchaPoint value) {
    if (!_canMove(value)) return;

    _isBusy = true;
    _point = value;
    notifyListeners();
  }

  Angle _angle;
  Angle get angle => _angle;
  set angle(Angle angle) {
    if (angle == _angle) return;
    _angle = angle;
    notifyListeners();
  }

  /// Whether the part is in its solution point.
  bool get solved => _angle.isZero && _point == _solutionPoint;

  /// A part can move to a point if it is not busy and the point is not
  /// the current point.
  void maybeSwapPoints(FlutterCaptchaPartController other) {
    if (_isBusy || other._isBusy) return;

    final changeableNewPosition = other.point;
    other.point = point;
    point = changeableNewPosition;

    if (changeableNewPosition != other.point) {}
  }

  bool _canMove(CaptchaPoint point) => point != _point;

  void _update({
    required CaptchaPoint point,
    required CaptchaPoint solutionPoint,
    required Angle angle,
  }) {
    _point = point;
    _angle = angle;
    _solutionPoint = solutionPoint;
    notifyListeners();
  }

  void _solve() {
    _point = _solutionPoint;
    _angle = Angle.zero();
    notifyListeners();
  }
}

class _Part extends SingleChildRenderObjectWidget {
  final double dimension;
  final double size;
  final CaptchaPoint solutionPoint;

  const _Part({
    required this.dimension,
    required this.size,
    required this.solutionPoint,
    required super.child,
  });

  @override
  _RenderPart createRenderObject(BuildContext context) => _RenderPart(
        dimension: dimension,
        partSize: size,
        point: solutionPoint,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderPart renderObject) {
    renderObject
      ..dimension = dimension
      ..partSize = size
      ..solutionPoint = solutionPoint;
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

  CaptchaPoint _solutionPoint;
  set solutionPoint(CaptchaPoint value) {
    if (_solutionPoint == value) return;

    _solutionPoint = value;
    markNeedsLayout();
  }

  _RenderPart({
    required double dimension,
    required double partSize,
    required CaptchaPoint point,
  })  : _solutionPoint = point,
        _dimension = dimension,
        _partSize = partSize;

  @override
  void performLayout() {
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
        context.canvas.translate(
          -_solutionPoint.x * _partSize,
          -_solutionPoint.y * _partSize,
        );
        super.paint(context, offset);
      },
      oldLayer: layer as ClipRectLayer?,
    );
  }
}

class _FeedbackClipper extends CustomClipper<Rect> {
  final FlutterCaptchaCrossLine crossLine;
  final CaptchaPoint point;
  final CaptchaLayout layout;

  const _FeedbackClipper({
    required this.crossLine,
    required this.point,
    required this.layout,
  });

  @override
  Rect getClip(Size size) {
    final isPositiveX = point.x > 0;
    final isPositiveY = point.y > 0;
    final isAtBoundaryX =
        isPositiveX && point.x != layout.dimension - layout.size;
    final isAtBoundaryY =
        isPositiveY && point.y != layout.dimension - layout.size;
    final clipValue = crossLine.width / 2;

    final top = isPositiveY ? clipValue : 0.0;
    final left = isPositiveX ? clipValue : 0.0;
    final bottom = isAtBoundaryY || point.y == 0 ? clipValue : 0.0;
    final right = isAtBoundaryX || point.x == 0 ? clipValue : 0.0;

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
      oldClipper.point != point ||
      oldClipper.layout != layout;
}
