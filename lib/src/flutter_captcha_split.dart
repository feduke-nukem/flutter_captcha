import 'package:flutter/rendering.dart';

sealed class FlutterCaptchaSplit {
  const FlutterCaptchaSplit();

  int get count;
  List<Alignment> get alignments;
  int get xCount;
  int get yCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlutterCaptchaSplit &&
          runtimeType == other.runtimeType &&
          count == other.count &&
          alignments == other.alignments &&
          xCount == other.xCount &&
          yCount == other.yCount;

  @override
  int get hashCode =>
      count.hashCode ^ alignments.hashCode ^ xCount.hashCode ^ yCount.hashCode;

  const factory FlutterCaptchaSplit.twoByTwo() = _TwoByTwoSplit;
  const factory FlutterCaptchaSplit.threeByThree() = _ThreeByTheeSplit;
}

final class _TwoByTwoSplit extends FlutterCaptchaSplit {
  const _TwoByTwoSplit();

  @override
  final List<Alignment> alignments = const [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];

  @override
  int get count => 2 * 2;

  @override
  int get xCount => 2;

  @override
  int get yCount => 2;
}

final class _ThreeByTheeSplit extends FlutterCaptchaSplit {
  const _ThreeByTheeSplit();

  @override
  final List<Alignment> alignments = const [
    Alignment.topLeft,
    Alignment.topCenter,
    Alignment.topRight,
    Alignment.centerLeft,
    Alignment.center,
    Alignment.centerRight,
    Alignment.bottomLeft,
    Alignment.bottomCenter,
    Alignment.bottomRight,
  ];

  @override
  int get count => 3 * 3;

  @override
  int get xCount => 3;

  @override
  int get yCount => 3;
}
