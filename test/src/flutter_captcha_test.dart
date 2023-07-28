import 'package:flutter/material.dart';
import 'package:flutter_captcha/src/angle.dart';
import 'package:flutter_captcha/src/flutter_captcha.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GlobalKey<FlutterCaptchaState> key;
  final widget = Container(
    color: Colors.red,
  );

  group('widget', () {
    setUp(() {
      key = GlobalKey<FlutterCaptchaState>();
    });
    testWidgets('init => is not solved', (widgetTester) async {
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              key: key,
              dimension: 300.0,
              fit: BoxFit.cover,
              child: widget,
            ),
          ),
        ),
      );
      expect(key.currentState!.checkSolution(), isFalse);
    });

    testWidgets('init reset => current positions and controllers are different',
        (widgetTester) async {
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              key: key,
              dimension: 300.0,
              fit: BoxFit.cover,
              child: widget,
            ),
          ),
        ),
      );
      final prevPositions = key.currentState!.currentPositions;
      final prevPartControllers = key.currentState!.controllers;

      key.currentState!.reset();

      final resetPositions = key.currentState!.currentPositions;
      final resetPartControllers = key.currentState!.controllers;

      expect(identical(prevPositions, resetPositions), isTrue);
      expect(identical(prevPartControllers, resetPartControllers), isTrue);
    });

    testWidgets(
        'split size 10 => 100 parts, 100 part controllers, 100 widgets found,',
        (widgetTester) async {
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              key: key,
              dimension: 300.0,
              splitSize: 10,
              fit: BoxFit.cover,
              child: widget,
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();

      expect(key.currentState!.currentPositions!.length, equals(100));
      expect(key.currentState!.controllers.length, equals(100));
      expect(find.byType(FlutterCaptchaPart), findsNWidgets(100));
    });

    testWidgets('can rotate equals false => all start angles are zero,',
        (widgetTester) async {
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              key: key,
              canRotate: false,
              dimension: 300.0,
              fit: BoxFit.cover,
              child: widget,
            ),
          ),
        ),
      );
      expect(
        key.currentState!.controllers.every(
          (element) => element.angle == Angle.zero() && element.angle.isZero,
        ),
        isTrue,
      );
    });
    testWidgets('can move and can rotate equals false => all are solved,',
        (widgetTester) async {
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              key: key,
              canMove: false,
              canRotate: false,
              dimension: 300.0,
              child: widget,
            ),
          ),
        ),
      );

      expect(
        key.currentState!.controllers.every((element) => element.solved),
        isTrue,
      );
    });

    testWidgets('parts builder is provided => builder is used',
        (widgetTester) async {
      const key = Key('parts_builder');
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              dimension: 300.0,
              splitSize: 3,
              partsBuilder: (context, child, isSolved) {
                return Container(
                  key: key,
                  child: child,
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

    testWidgets(
        'widget size property changed => controller was softly reset with split',
        (widgetTester) async {
      final size = ValueNotifier(3);

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: size,
              builder: (__, value, _) => FlutterCaptcha(
                key: key,
                dimension: 300.0,
                splitSize: value,
                child: widget,
              ),
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();

      expect(key.currentState!.currentPositions!.length, equals(9));

      size.value = 4;

      await widgetTester.pumpAndSettle();

      expect(key.currentState!.currentPositions!.length, equals(16));

      size.value = 2;

      await widgetTester.pumpAndSettle();

      expect(key.currentState!.currentPositions!.length, equals(4));
    });

    testWidgets('widget dimension property changed => controller was reset',
        (widgetTester) async {
      final dimension = ValueNotifier(300.0);

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: dimension,
              builder: (__, value, _) => FlutterCaptcha(
                key: key,
                dimension: value,
                child: widget,
              ),
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();
      final prevPositions = key.currentState!.currentPositions;
      final prevControllers = key.currentState!.controllers;

      dimension.value = 400;

      await widgetTester.pumpAndSettle();

      final resetPositions = key.currentState!.currentPositions;

      expect(identical(prevPositions, resetPositions), isFalse);
      expect(
        identical(prevControllers, key.currentState!.controllers),
        isTrue,
      );
    });

    testWidgets(
        'widget can move property changed => controller was softly reset',
        (widgetTester) async {
      final canMove = ValueNotifier(true);

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: canMove,
              builder: (__, value, _) => FlutterCaptcha(
                key: key,
                dimension: 300.0,
                canMove: value,
                child: widget,
              ),
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();
      final prevParts = key.currentState!.currentPositions;
      final prevControllers = key.currentState!.controllers;

      canMove.value = false;

      await widgetTester.pumpAndSettle();

      final resetParts = key.currentState!.currentPositions;

      expect(identical(prevParts, resetParts), isTrue);
      expect(
        identical(prevControllers, key.currentState!.controllers),
        isTrue,
      );
    });

    testWidgets(
        'widget can rotate property changed => controller was softly reset',
        (widgetTester) async {
      final canRotate = ValueNotifier(true);

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: canRotate,
              builder: (__, value, _) => FlutterCaptcha(
                key: key,
                dimension: 300.0,
                canRotate: value,
                child: widget,
              ),
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();
      final prevParts = key.currentState!.currentPositions;
      final prevControllers = key.currentState!.controllers;

      canRotate.value = false;

      await widgetTester.pumpAndSettle();

      final resetParts = key.currentState!.currentPositions;

      expect(identical(prevParts, resetParts), isTrue);
      expect(
        identical(prevControllers, key.currentState!.controllers),
        isTrue,
      );
    });

    testWidgets('solve => all parts are solved', (widgetTester) async {
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              key: key,
              dimension: 300.0,
              splitSize: 3,
              child: widget,
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();

      key.currentState!.solve();

      await widgetTester.pumpAndSettle();

      expect(
        key.currentState!.controllers.every((element) => element.solved),
        isTrue,
      );

      expect(key.currentState!.checkSolution(), isTrue);
    });
  });
}
