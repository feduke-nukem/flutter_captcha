import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img_lib;

import 'flutter_captcha_part.dart';

/// {@template flutter_captcha_image}
/// A captcha image for flutter.
/// {@endtemplate}
class FlutterCaptchaImage {
  /// Desired image to be used.
  final img_lib.Image value;

  /// @nodoc
  const FlutterCaptchaImage(this.value);

  /// Splits the image into parts.
  ///
  /// {@macro captcha_part.captcha_parts}
  Future<CaptchaParts> split({
    required int size,
    required double dimension,
    required bool preferIsolate,
  }) async {
    if (preferIsolate) {
      return compute(
        (_) async {
          final image =
              img_lib.copyResizeCropSquare(value, size: dimension.toInt());

          return _split(image, size: size);
        },
        null,
      );
    }

    final command = img_lib.Command()..image(value);
    command.copyResizeCropSquare(size: dimension.toInt());
    await command.execute();

    return _split(command.outputImage!, size: size);
  }

  Map<CaptchaPartPosition, Uint8List> _split(
    img_lib.Image image, {
    required int size,
  }) {
    var x = 0.0, y = 0.0;
    final width = image.width / size;
    final height = image.height / size;

    final output = <CaptchaPartPosition, Uint8List>{};

    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        final position = CaptchaPartPosition(x, y);
        final part = img_lib.copyCrop(
          image,
          x: x.toInt(),
          y: y.toInt(),
          width: width.toInt(),
          height: height.toInt(),
        );
        output[position] = img_lib.encodePng(part);

        x += width;
      }
      x = 0;
      y += height;
    }

    return output;
  }
}
