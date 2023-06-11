const _initial = 0.0;
const _quarter = 1 / 4;
const _half = 2 / 4;
const _third = 3 / 4;
const _solutionValue = _initial;

final class FlutterCaptchaAngle {
  const FlutterCaptchaAngle._(this.value);

  factory FlutterCaptchaAngle.full() => const FlutterCaptchaAngle._(_initial);
  factory FlutterCaptchaAngle.quarter() =>
      const FlutterCaptchaAngle._(_quarter);
  factory FlutterCaptchaAngle.third() => const FlutterCaptchaAngle._(_third);
  factory FlutterCaptchaAngle.half() => const FlutterCaptchaAngle._(_half);

  static double _absoluteValue(double value) => value % 1;
  static List<FlutterCaptchaAngle> allAngles() => [
        FlutterCaptchaAngle.full(),
        FlutterCaptchaAngle.quarter(),
        FlutterCaptchaAngle.half(),
        FlutterCaptchaAngle.third(),
      ];

  final double value;
  double get absoluteValue => _absoluteValue(value);
  bool get isSolved =>
      value == _solutionValue || absoluteValue == _solutionValue;

  FlutterCaptchaAngle turn() => FlutterCaptchaAngle._(value + _quarter);

  FlutterCaptchaAngle operator *(double other) =>
      FlutterCaptchaAngle._(value * other);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlutterCaptchaAngle && value == other.value;
  @override
  int get hashCode => value.hashCode;
}
