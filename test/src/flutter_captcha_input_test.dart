import 'package:flutter/material.dart';
import 'package:flutter_captcha/flutter_captcha.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transparent_image/transparent_image.dart' as transparent_image;

import 'helper.dart';

void main() {
  setUp(() async {
    await initFakeBundle();
  });
  group('FlutterCaptchaInput', () {
    test('create instance from asset', () {
      expect(
        () => const FlutterCaptchaInput.asset(''),
        returnsNormally,
      );
    });

    test('create instance from ImageProvider', () {
      expect(
        () => const FlutterCaptchaInput.provider(
          AssetImage(''),
        ),
        returnsNormally,
      );
    });

    test('create image from asset input', () async {
      const input = FlutterCaptchaInput.asset('');
      expect(() async => await input.createImage(), returnsNormally);
    });

    test('create image from network provider input', () {
      const input = FlutterCaptchaInput.provider(
        NetworkImage(''),
      );

      provideMockNetworkImage(() async {
        expect(() async => await input.createImage(), returnsNormally);
      });
    });

    test('create image from byte provider input', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      final input = FlutterCaptchaInput.provider(
        MemoryImage(transparent_image.kTransparentImage),
      );

      expect(() async => await input.createImage(), returnsNormally);
    });
  });
}
