import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' as services;
import 'package:image/image.dart' as img_lib;
import 'package:flutter_captcha/src/flutter_captcha_image.dart';
import 'dart:ui' as ui;

sealed class FlutterCaptchaInput {
  const FlutterCaptchaInput();
  Future<FlutterCaptchaImage> createImage();

  const factory FlutterCaptchaInput.asset(String path) = _AssetInput;
  const factory FlutterCaptchaInput.provider(ImageProvider provider) =
      _ProviderInput;
}

final class _AssetInput extends FlutterCaptchaInput {
  const _AssetInput(this.path);

  final String path;

  @override
  Future<FlutterCaptchaImage> createImage() async {
    final data = await services.rootBundle.load(path);

    // Utilize flutter's built-in decoder to decode asset images as it will be
    // faster than the dart decoder.
    final buffer =
        await ui.ImmutableBuffer.fromUint8List(data.buffer.asUint8List());

    final id = await ui.ImageDescriptor.encoded(buffer);
    final codec = await id.instantiateCodec(
        targetHeight: id.height, targetWidth: id.width);

    final fi = await codec.getNextFrame();

    final uiImage = fi.image;
    final uiBytes = await uiImage.toByteData();

    final image = img_lib.Image.fromBytes(
        width: id.width,
        height: id.height,
        bytes: uiBytes!.buffer,
        numChannels: 4);

    return FlutterCaptchaImage(image);
  }
}

final class _ProviderInput extends FlutterCaptchaInput {
  const _ProviderInput(this.provider);

  final ImageProvider provider;

  @override
  Future<FlutterCaptchaImage> createImage() async {
    final completer = Completer<img_lib.Image>();
    final ImageStreamListener listener = ImageStreamListener(
      (
        ImageInfo imageInfo,
        bool _,
      ) async {
        final image = await _convertFlutterUiToImage(imageInfo.image);

        completer.complete(image);
      },
      onError: (exception, stackTrace) {
        completer.completeError(exception, stackTrace);
      },
    );

    final imageStream = provider.resolve(ImageConfiguration.empty);
    imageStream.addListener(listener);

    final image = await completer.future;

    return FlutterCaptchaImage(image);
  }

  Future<img_lib.Image> _convertFlutterUiToImage(ui.Image input) async {
    final bytes = await input.toByteData();

    final image = img_lib.Image.fromBytes(
      width: input.width,
      height: input.height,
      bytes: bytes!.buffer,
      numChannels: 4,
    );

    return image;
  }
}
