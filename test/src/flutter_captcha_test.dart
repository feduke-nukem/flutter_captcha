import 'package:flutter/material.dart';
import 'package:flutter_captcha/flutter_captcha.dart';
import 'package:flutter_captcha/src/angle.dart';
import 'package:flutter_captcha/src/flutter_captcha_part.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helper.dart';

void main() {
  group('controller', () {
    setUp(() async {
      await initFakeBundle();
    });
    test('create', () {
      expect(() => FlutterCaptchaController(), returnsNormally);
    });

    testWidgets('init two inputs, show next input twice => index equals 2',
        (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [
          createFakeInput(),
          createFakeInput(),
          createFakeInput(),
        ],
      );

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              preferIsolate: false,
              controller: controller,
              dimension: 300.0,
            ),
          ),
        ),
      );

      expect(controller.currentInputIndex, equals(0));
      await controller.showNextInput();

      expect(controller.currentInputIndex, equals(1));
      await controller.showNextInput();

      expect(controller.currentInputIndex, equals(2));
    });

    testWidgets('init one input, show next input => index equals 0',
        (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [createFakeInput()],
      );

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              preferIsolate: false,
              controller: controller,
              dimension: 300.0,
            ),
          ),
        ),
      );

      await controller.showNextInput();
      await controller.showNextInput();
      await controller.showNextInput();
      expect(controller.currentInputIndex, equals(0));
    });

    testWidgets('init one input => is not solved', (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [createFakeInput()],
      );

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              preferIsolate: false,
              controller: controller,
              dimension: 300.0,
            ),
          ),
        ),
      );
      await controller.showNextInput();
      expect(controller.checkSolution(), isFalse);
    });

    testWidgets(
        'init 3 inputs, show two next, hard reset => was reset to initial',
        (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [
          createFakeInput(),
          createFakeInput(),
          createFakeInput(),
        ],
      );

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              preferIsolate: false,
              controller: controller,
              dimension: 300.0,
            ),
          ),
        ),
      );
      await controller.showNextInput();
      final prevParts = controller.currentParts;
      final prevPartControllers = controller.partControllersMap.values;
      await controller.showNextInput();

      expect(controller.currentInputIndex, equals(2));

      await controller.hardReset();
      final resetPartControllers = controller.partControllersMap.values;
      final resetParts = controller.currentParts;

      expect(controller.currentInputIndex, equals(0));
      expect(identical(prevParts, resetParts), isFalse);
      expect(identical(prevPartControllers, resetPartControllers), isFalse);
    });

    testWidgets(
        'init 3 inputs, show two next, soft reset => was reset to current',
        (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [
          createFakeInput(),
          createFakeInput(),
          createFakeInput(),
        ],
      );

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              preferIsolate: false,
              controller: controller,
              dimension: 300.0,
            ),
          ),
        ),
      );
      await controller.showNextInput();
      final prevParts = controller.currentParts;
      final prevPartControllers = controller.partControllersMap.values;
      await controller.showNextInput();

      expect(controller.currentInputIndex, equals(2));

      controller.softReset();

      final resetParts = controller.currentParts;
      final resetPartControllers = controller.partControllersMap.values;

      expect(controller.currentInputIndex, equals(2));
      expect(identical(prevParts, resetParts), isFalse);
      expect(identical(prevPartControllers, resetPartControllers), isFalse);
    });

    testWidgets('size 10 => 100 parts, 100 part controllers,',
        (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [createFakeInput()],
      );

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              preferIsolate: false,
              controller: controller,
              dimension: 300.0,
              size: 10,
            ),
          ),
        ),
      );

      expect(controller.currentParts!.length, equals(100));
      expect(controller.partControllersMap.length, equals(100));
    });

    testWidgets('init 3 inputs, hard reset to 1 => inputs set correctly,',
        (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [
          createFakeInput(),
          createFakeInput(),
          createFakeInput(),
        ],
      );

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              preferIsolate: false,
              controller: controller,
              dimension: 300.0,
            ),
          ),
        ),
      );

      expect(controller.inputs.length, equals(3));

      await controller.hardReset(inputs: [
        createFakeInput(),
      ]);

      expect(controller.inputs.length, equals(1));
    });

    testWidgets('can rotate equals false => all start angles are zero,',
        (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [createFakeInput()],
      );

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              preferIsolate: false,
              canRotate: false,
              controller: controller,
              dimension: 300.0,
            ),
          ),
        ),
      );
      expect(
        controller.partControllersMap.values.every(
          (element) => element.angle == Angle.zero() && element.angle.isSolved,
        ),
        isTrue,
      );
    });
    testWidgets('can move and can rotate equals false => all are solved,',
        (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [createFakeInput()],
      );

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              preferIsolate: false,
              canMove: false,
              canRotate: false,
              controller: controller,
              dimension: 300.0,
            ),
          ),
        ),
      );

      expect(
        controller.partControllersMap.values
            .every((element) => element.isSolved),
        isTrue,
      );
    });

    testWidgets('controller correctly disposed', (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [createFakeInput()],
      );

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              preferIsolate: false,
              controller: controller,
              dimension: 300.0,
            ),
          ),
        ),
      );

      controller.dispose();

      expect(controller.inputs.isEmpty, isTrue);
      expect(controller.currentParts, isNull);
      expect(controller.partControllersMap.isEmpty, isTrue);
    });
  });

  group('widget', () {
    testWidgets('4 size => 16 part widgets found', (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [createFakeInput()],
      );
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              preferIsolate: false,
              controller: controller,
              dimension: 300.0,
              size: 4,
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();

      expect(find.byType(FlutterCaptchaPart), findsNWidgets(16));
    });

    testWidgets('can move false, size 1 => tap each part until solved',
        (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [createFakeInput()],
      );
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              preferIsolate: false,
              controller: controller,
              dimension: 300.0,
              canMove: false,
              size: 1,
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();

      final finder = find.byType(FlutterCaptchaPart);

      while (!controller.checkSolution()) {
        await widgetTester.tap(finder);
        await widgetTester.pumpAndSettle();
      }

      expect(controller.checkSolution(), isTrue);
    });

    testWidgets('parts builder is provided => builder is used',
        (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [createFakeInput()],
      );
      const key = Key('parts_builder');
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterCaptcha(
              controller: controller,
              dimension: 300.0,
              size: 3,
              progressBuilder: (context) => Container(),
              partsBuilder: (context, child, isSolved) {
                return Container(
                  key: key,
                  child: child,
                );
              },
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
      final controller = FlutterCaptchaController(
        inputs: [createFakeInput()],
      );

      final size = ValueNotifier(3);

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: size,
              builder: (__, value, _) => FlutterCaptcha(
                controller: controller,
                dimension: 300.0,
                size: value,
              ),
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();

      expect(controller.currentParts!.length, equals(9));

      size.value = 4;

      await widgetTester.pumpAndSettle();

      expect(controller.currentParts!.length, equals(16));

      size.value = 1;

      await widgetTester.pumpAndSettle();

      expect(controller.currentParts!.length, equals(1));
    });

    testWidgets(
        'widget dimension property changed => controller was softly reset',
        (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [createFakeInput()],
      );

      final dimension = ValueNotifier(300.0);

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: dimension,
              builder: (__, value, _) => FlutterCaptcha(
                controller: controller,
                dimension: value,
              ),
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();
      final prevParts = controller.currentParts;
      final prevControllers = controller.partControllersMap.values;

      dimension.value = 400;

      await widgetTester.pumpAndSettle();

      final resetParts = controller.currentParts;

      expect(identical(prevParts, resetParts), isTrue);
      expect(
        identical(prevControllers, controller.partControllersMap.values),
        isFalse,
      );
    });

    testWidgets(
        'widget can move property changed => controller was softly reset',
        (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [createFakeInput()],
      );

      final canMove = ValueNotifier(true);

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: canMove,
              builder: (__, value, _) => FlutterCaptcha(
                controller: controller,
                dimension: 300.0,
                canMove: value,
              ),
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();
      final prevParts = controller.currentParts;
      final prevControllers = controller.partControllersMap.values;

      canMove.value = false;

      await widgetTester.pumpAndSettle();

      final resetParts = controller.currentParts;

      expect(identical(prevParts, resetParts), isTrue);
      expect(
        identical(prevControllers, controller.partControllersMap.values),
        isFalse,
      );
    });

    testWidgets(
        'widget can rotate property changed => controller was softly reset',
        (widgetTester) async {
      final controller = FlutterCaptchaController(
        inputs: [createFakeInput()],
      );

      final canRotate = ValueNotifier(true);

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: canRotate,
              builder: (__, value, _) => FlutterCaptcha(
                controller: controller,
                dimension: 300.0,
                canRotate: value,
              ),
            ),
          ),
        ),
      );

      await widgetTester.pumpAndSettle();
      final prevParts = controller.currentParts;
      final prevControllers = controller.partControllersMap.values;

      canRotate.value = false;

      await widgetTester.pumpAndSettle();

      final resetParts = controller.currentParts;

      expect(identical(prevParts, resetParts), isTrue);
      expect(
        identical(prevControllers, controller.partControllersMap.values),
        isFalse,
      );
    });
  });
}
