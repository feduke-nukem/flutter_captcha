import 'dart:typed_data';

import 'package:flutter_captcha/src/angle.dart';
import 'package:flutter_captcha/src/flutter_captcha_part.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('controller', () {
    test('swap different positions => swapped normally', () {
      final first = FlutterCaptchaPartController(
        imageBytes: Uint8List.fromList([]),
        startPosition: const CaptchaPartPosition(0, 1),
        solutionPosition: const CaptchaPartPosition(1, 1),
        angle: Angle.zero(),
      );

      final second = FlutterCaptchaPartController(
        imageBytes: Uint8List.fromList([]),
        startPosition: const CaptchaPartPosition(1, 1),
        solutionPosition: const CaptchaPartPosition(0, 1),
        angle: Angle.zero(),
      );

      first.maybeSwapPositions(second);

      expect(first.position, const CaptchaPartPosition(1, 1));
      expect(second.position, const CaptchaPartPosition(0, 1));
    });

    test('swap same positions => no swap', () {
      final first = FlutterCaptchaPartController(
        imageBytes: Uint8List.fromList([]),
        startPosition: const CaptchaPartPosition(0, 1),
        solutionPosition: const CaptchaPartPosition(1, 1),
        angle: Angle.zero(),
      );

      final second = FlutterCaptchaPartController(
        imageBytes: Uint8List.fromList([]),
        startPosition: const CaptchaPartPosition(0, 1),
        solutionPosition: const CaptchaPartPosition(1, 1),
        angle: Angle.zero(),
      );

      first.maybeSwapPositions(second);

      expect(first.position, const CaptchaPartPosition(0, 1));
      expect(second.position, const CaptchaPartPosition(0, 1));
    });

    test('Angle.zero, turn once=> angle equals Angle.quarter', () {
      final controller = FlutterCaptchaPartController(
        imageBytes: Uint8List.fromList([]),
        startPosition: const CaptchaPartPosition(0, 1),
        solutionPosition: const CaptchaPartPosition(1, 1),
        angle: Angle.zero(),
      );

      controller.turn();

      expect(controller.angle, equals(Angle.quarter()));
    });

    test('Angle.zero, turn twice => angle equals Angle.half', () {
      final controller = FlutterCaptchaPartController(
        imageBytes: Uint8List.fromList([]),
        startPosition: const CaptchaPartPosition(0, 1),
        solutionPosition: const CaptchaPartPosition(1, 1),
        angle: Angle.zero(),
      );

      controller.turn();
      controller.turn();

      expect(controller.angle, equals(Angle.half()));
    });
  });
}
