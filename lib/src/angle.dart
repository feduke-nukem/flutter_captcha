const _zero = 0.0;
const _quarter = 1 / 4;
const _half = 2 / 4;
const _third = 3 / 4;

/// Represents an angle.
final class Angle {
  const Angle._(this.value);

  /// 0 degrees.
  factory Angle.zero() => const Angle._(_zero);

  /// 90 degrees.
  factory Angle.quarter() => const Angle._(_quarter);

  /// 180 degrees.
  factory Angle.third() => const Angle._(_third);

  /// 270 degrees.
  factory Angle.half() => const Angle._(_half);

  /// All possible angles.
  static List<Angle> all() => [
        Angle.zero(),
        Angle.quarter(),
        Angle.half(),
        Angle.third(),
      ];

  /// The value of the angle.
  final double value;

  /// The absolute value of the angle.
  ///
  /// For example, if the angle is 1.25, the absolute value is 0.25.
  double get absoluteValue => value % 1;

  /// Whether the angle is zero.
  bool get isZero => value == _zero || absoluteValue == _zero;

  Angle operator +(Angle other) => Angle._(value + other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Angle && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
