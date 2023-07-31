import 'package:flutter_captcha/src/angle.dart';
import 'package:flutter_captcha/src/flutter_captcha.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('controller', () {
    test('swap different points => swapped normally', () {
      final first = FlutterCaptchaPartController(
        startPoint: (x: 0, y: 1),
        solutionPoint: (x: 1, y: 1),
        angle: Angle.zero(),
      );

      final second = FlutterCaptchaPartController(
        startPoint: (x: 1, y: 1),
        solutionPoint: (x: 0, y: 1),
        angle: Angle.zero(),
      );

      first.maybeSwapPoints(second);

      expect(first.point, (x: 1, y: 1));
      expect(second.point, (x: 0, y: 1));
    });

    test('swap same points => no swap', () {
      final first = FlutterCaptchaPartController(
        startPoint: (x: 0, y: 1),
        solutionPoint: (x: 1, y: 1),
        angle: Angle.zero(),
      );

      final second = FlutterCaptchaPartController(
        startPoint: (x: 0, y: 1),
        solutionPoint: (x: 1, y: 1),
        angle: Angle.zero(),
      );

      first.maybeSwapPoints(second);

      expect(first.point, (x: 0, y: 1));
      expect(second.point, (x: 0, y: 1));
    });

    test('Angle.zero, turn once=> angle equals Angle.quarter', () {
      final controller = FlutterCaptchaPartController(
        startPoint: (x: 0, y: 1),
        solutionPoint: (x: 1, y: 1),
        angle: Angle.zero(),
      );

      controller.angle += Angle.quarter();

      expect(controller.angle, equals(Angle.quarter()));
    });

    test('Angle.zero, turn twice => angle equals Angle.half', () {
      final controller = FlutterCaptchaPartController(
        startPoint: (x: 0, y: 1),
        solutionPoint: (x: 1, y: 1),
        angle: Angle.zero(),
      );

      controller.angle += Angle.quarter();
      controller.angle += Angle.quarter();

      expect(controller.angle, equals(Angle.half()));
    });
  });
}
