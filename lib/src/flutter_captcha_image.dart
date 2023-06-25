import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img_lib;

class FlutterCaptchaPartPosition {
  final double x;
  final double y;

  const FlutterCaptchaPartPosition(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlutterCaptchaPartPosition &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class FlutterCaptchaImage {
  final img_lib.Image value;

  const FlutterCaptchaImage(this.value);

  Future<Map<FlutterCaptchaPartPosition, Uint8List>> split({
    required int splitMultiplier,
    required double size,
    required bool preferIsolate,
  }) async {
    if (preferIsolate) {
      return compute(
        (_) async {
          final image = img_lib.copyResizeCropSquare(value, size: size.toInt());

          return _splitImage(image, splitMultiplier: splitMultiplier);
        },
        null,
      );
    }

    final command = img_lib.Command()..image(value);
    command.copyResizeCropSquare(size: size.toInt());
    await command.execute();

    return _splitImage(command.outputImage!, splitMultiplier: splitMultiplier);
  }

  Map<FlutterCaptchaPartPosition, Uint8List> _splitImage(
    img_lib.Image image, {
    required int splitMultiplier,
  }) {
    var x = 0.0, y = 0.0;
    final width = image.width / splitMultiplier;
    final height = image.height / splitMultiplier;

    final output = <FlutterCaptchaPartPosition, Uint8List>{};

    for (int i = 0; i < splitMultiplier; i++) {
      for (int j = 0; j < splitMultiplier; j++) {
        final position = FlutterCaptchaPartPosition(x, y);
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
