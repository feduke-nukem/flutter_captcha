import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_captcha/src/angle.dart';
import 'package:flutter_captcha/src/flutter_captcha.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final widget = Container(
    color: Colors.red,
  );

  group('controller', () {
    test('create with -10 size => throws assertion error', () {
      expect(() => FlutterCaptchaController(size: -10), throwsAssertionError);
    });

    test('init => is not solved', () {
      final controller = FlutterCaptchaController()..init();
      expect(controller.checkSolution(), isFalse);
    });

    test('init reset => current points and controllers are different', () {
      final controller = FlutterCaptchaController()..init();
      final prevPositions = controller.currentPoints;
      final prevPartControllers = controller.controllers;

      controller.reset();

      final resetPositions = controller.currentPoints;
      final resetPartControllers = controller.controllers;

      expect(identical(prevPositions, resetPositions), isTrue);
      expect(identical(prevPartControllers, resetPartControllers), isTrue);
    });

    test('randomize angles equals false => all start angles are zero,', () {
      final controller = FlutterCaptchaController(randomizeAngles: false)
        ..init();

      expect(
        controller.controllers.every(
          (element) => element.angle == Angle.zero() && element.angle.isZero,
        ),
        isTrue,
      );
    });
    test('can move and can rotate equals false => all are solved,', () {
      final controller = FlutterCaptchaController(
        randomizeAngles: false,
        randomizePositions: false,
      )..init();

      expect(
        controller.controllers.every((element) => element.solved),
        isTrue,
      );
    });

    test('split size changed => controller was softly reset with split', () {
      final controller = FlutterCaptchaController(size: 3)..init();

      expect(controller.currentPoints!.length, equals(9));

      controller.size = 4;

      expect(controller.currentPoints!.length, equals(16));

      controller.size = 2;

      expect(controller.currentPoints!.length, equals(4));
    });

    test('randomize angles changed => was softly reset', () {
      final controller = FlutterCaptchaController()..init();

      final prevParts = controller.currentPoints;
      final prevControllers = controller.controllers;

      controller.randomizeAngles = false;

      final resetParts = controller.currentPoints;

      expect(identical(prevParts, resetParts), isTrue);
      expect(
        identical(prevControllers, controller.controllers),
        isTrue,
      );
    });

    test('randomize points changed => was softly reset', () {
      final controller = FlutterCaptchaController()..init();

      final prevParts = controller.currentPoints;
      final prevControllers = controller.controllers;

      controller.randomizePositions = false;

      final resetParts = controller.currentPoints;

      expect(identical(prevParts, resetParts), isTrue);
      expect(
        identical(prevControllers, controller.controllers),
        isTrue,
      );
    });

    testWidgets('solve => all parts are solved', (widgetTester) async {
      final controller = FlutterCaptchaController()..init();
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              controller: controller,
              child: widget,
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();

      controller.solve();

      await widgetTester.pumpAndSettle();

      expect(
        controller.controllers.every((element) => element.solved),
        isTrue,
      );

      expect(controller.checkSolution(), isTrue);
    });
    test('init 3 split size => points correct', () {
      final controller = FlutterCaptchaController(size: 3)..init();

      final points = [
        (x: 0, y: 0),
        (x: 1, y: 0),
        (x: 2, y: 0),
        (x: 0, y: 1),
        (x: 1, y: 1),
        (x: 2, y: 1),
        (x: 0, y: 2),
        (x: 1, y: 2),
        (x: 2, y: 2),
      ];

      expect(listEquals(points, controller.currentPoints), isTrue);
    });

    test('disposes correctly', () {
      final controller = FlutterCaptchaController()..init();

      expect(controller.controllers.length, greaterThan(0));
      expect(controller.currentPoints, isNotNull);

      controller.dispose();

      expect(controller.controllers.length, equals(0));
      expect(controller.currentPoints, isNull);
    });
  });
  group('widget', () {
    testWidgets(
        'split size 10 => 100 parts, 100 part controllers, 100 widgets found,',
        (widgetTester) async {
      final controller = FlutterCaptchaController(size: 10)..init();
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              controller: controller,
              dimension: 300.0,
              fit: BoxFit.cover,
              child: widget,
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();

      expect(controller.currentPoints!.length, equals(100));
      expect(controller.controllers.length, equals(100));
      expect(find.byType(FlutterCaptchaPart), findsNWidgets(100));
    });

    testWidgets('parts builder is provided => builder is used',
        (widgetTester) async {
      const key = Key('parts_builder');
      final controller = FlutterCaptchaController(size: 3)..init();
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              controller: controller,
              partsBuilder: (context, part) {
                return Container(
                  key: key,
                  child: part,
                );
              },
              child: widget,
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();

      final finder = find.byKey(key);

      expect(finder, findsNWidgets(9));
    });
  });
}
