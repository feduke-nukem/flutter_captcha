import 'package:flutter_captcha/src/flutter_captcha_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart';

import 'helper.dart';

void main() {
  group('FlutterCaptchaImage', () {
    test('create instance', () {
      expect(() => FlutterCaptchaImage(Image.empty()), returnsNormally);
    });

    test('split dimension 100, size 3 => length equals 9', () async {
      final captchaImage = await FlutterCaptchaImage(
        createFakeImage(),
      ).split(
        size: 3,
        dimension: 100,
        preferIsolate: false,
      );

      expect(captchaImage.length, 9);
    });

    test('split dimension 100, size 0 => length equals 0', () async {
      final captchaImage = await FlutterCaptchaImage(
        createFakeImage(),
      ).split(
        size: 0,
        dimension: 100,
        preferIsolate: false,
      );

      expect(captchaImage.length, 0);
    });

    test('split dimension 100, size 1 => length equals 1', () async {
      final captchaImage = await FlutterCaptchaImage(
        createFakeImage(),
      ).split(
        size: 1,
        dimension: 100,
        preferIsolate: false,
      );

      expect(captchaImage.length, 1);
    });

    test('split dimension 0 => throws Exception', () async {
      final image = createFakeImage();

      expect(
        () async => await FlutterCaptchaImage(
          image,
        ).split(
          size: 1,
          dimension: 0,
          preferIsolate: false,
        ),
        throwsException,
      );
    });

    test('split with isolate', () async {
      final image = createFakeImage();

      expect(
        () async => await FlutterCaptchaImage(
          image,
        ).split(
          size: 1,
          dimension: 100,
          preferIsolate: true,
        ),
        returnsNormally,
      );
    });
  });
}
