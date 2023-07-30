import 'package:flutter_captcha/src/angle.dart';
import 'package:flutter_captcha/src/flutter_captcha.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('controller', () {
    test('swap different positions => swapped normally', () {
      final first = FlutterCaptchaPartController(
        startPosition: (x: 0, y: 1),
        solutionPosition: (x: 1, y: 1),
        angle: Angle.zero(),
      );

      final second = FlutterCaptchaPartController(
        startPosition: (x: 1, y: 1),
        solutionPosition: (x: 0, y: 1),
        angle: Angle.zero(),
      );

      first.maybeSwapPositions(second);

      expect(first.position, (x: 1, y: 1));
      expect(second.position, (x: 0, y: 1));
    });

    test('swap same positions => no swap', () {
      final first = FlutterCaptchaPartController(
        startPosition: (x: 0, y: 1),
        solutionPosition: (x: 1, y: 1),
        angle: Angle.zero(),
      );

      final second = FlutterCaptchaPartController(
        startPosition: (x: 0, y: 1),
        solutionPosition: (x: 1, y: 1),
        angle: Angle.zero(),
      );

      first.maybeSwapPositions(second);

      expect(first.position, (x: 0, y: 1));
      expect(second.position, (x: 0, y: 1));
    });

    test('Angle.zero, turn once=> angle equals Angle.quarter', () {
      final controller = FlutterCaptchaPartController(
        startPosition: (x: 0, y: 1),
        solutionPosition: (x: 1, y: 1),
        angle: Angle.zero(),
      );

      controller.angle += Angle.quarter();

      expect(controller.angle, equals(Angle.quarter()));
    });

    test('Angle.zero, turn twice => angle equals Angle.half', () {
      final controller = FlutterCaptchaPartController(
        startPosition: (x: 0, y: 1),
        solutionPosition: (x: 1, y: 1),
        angle: Angle.zero(),
      );

      controller.angle += Angle.quarter();
      controller.angle += Angle.quarter();

      expect(controller.angle, equals(Angle.half()));
    });
  });
}
