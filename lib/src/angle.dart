/// Represents an angle.
final class Angle {
  const Angle._(this.value);

  /// 0 degrees.
  factory Angle.zero() => const Angle._(0.0);

  /// 90 degrees.
  factory Angle.quarter() => const Angle._(1 / 4);

  /// 180 degrees.
  factory Angle.half() => const Angle._(2 / 4);

  /// 270 degrees.
  factory Angle.third() => const Angle._(3 / 4);

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
  bool get isZero => absoluteValue == 0.0;

  Angle operator +(Angle other) => Angle._(value + other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Angle && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
