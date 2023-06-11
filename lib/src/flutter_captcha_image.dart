import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_captcha/src/flutter_captcha_split.dart';
import 'package:image/image.dart' as img_lib;
import 'dart:ui' as ui;

class Coordinates {
  final int x;
  final int y;

  const Coordinates(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordinates &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class FlutterCaptchaImage {
  final img_lib.Image value;

  const FlutterCaptchaImage._(this.value);

  static Future<FlutterCaptchaImage> fromProvider(
      ImageProvider imageProvider) async {
    final completer = Completer<img_lib.Image>();
    final ImageStreamListener listener =
        ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) async {
      final image = _convertFlutterUiToImage(imageInfo.image);

      completer.complete(image);
    });

    final imageStream = imageProvider.resolve(ImageConfiguration.empty);
    imageStream.addListener(listener);

    final image = await completer.future;

    return FlutterCaptchaImage._(image);
  }

  static Future<FlutterCaptchaImage> fromAsset(String path) async {
    final data = await _loadFrom(path);

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

    return FlutterCaptchaImage._(image);
  }

  static Future<img_lib.Image> _convertFlutterUiToImage(ui.Image input) async {
    final bytes = await input.toByteData();

    final image = img_lib.Image.fromBytes(
      width: input.width,
      height: input.height,
      bytes: bytes!.buffer,
      numChannels: 4,
    );

    return image;
  }

  Map<Alignment, Uint8List> split({
    required FlutterCaptchaSplit split,
  }) {
    return _splitImage(value, split: split);
  }

  Future<Map<Alignment, Uint8List>> splitWithDimension({
    required FlutterCaptchaSplit split,
    required double dimension,
  }) async {
    final command = img_lib.Command()
      ..image(value)
      ..copyResizeCropSquare(size: dimension.round());

    await command.executeThread();

    return _splitImage(command.outputImage!, split: split);
  }

  static Future<ByteData> _loadFrom(String path) async => rootBundle.load(path);

  Map<Alignment, Uint8List> _splitImage(
    img_lib.Image image, {
    required FlutterCaptchaSplit split,
  }) {
    var x = 0, y = 0;
    final width = (image.width / split.xCount).round();
    final height = (image.height / split.yCount).round();

    // Split image to parts
    final parts = <img_lib.Image>[];
    for (int i = 0; i < split.yCount; i++) {
      for (int j = 0; j < split.xCount; j++) {
        parts.add(
          img_lib.copyCrop(
            image,
            x: x,
            y: y,
            width: width,
            height: height,
          ),
        );
        x += width;
      }
      x = 0;
      y += height;
    }

    // convert image from image package to Image Widget to display
    final output = <Alignment, Uint8List>{};

    for (var i = 0; i < split.alignments.length; i++) {
      final image = parts[i];
      final alignment = split.alignments[i];

      output[alignment] = img_lib.encodePng(image);
    }

    return output;
  }
}


// class FlutterCaptchaImage {
//   final img_lib.Image value;

//   const FlutterCaptchaImage._(this.value);

//   static Future<FlutterCaptchaImage> fromProvider(
//       ImageProvider imageProvider) async {
//     final completer = Completer<img_lib.Image>();
//     final ImageStreamListener listener =
//         ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) async {
//       final image = _convertFlutterUiToImage(imageInfo.image);

//       completer.complete(image);
//     });

//     final imageStream = imageProvider.resolve(ImageConfiguration.empty);
//     imageStream.addListener(listener);

//     final image = await completer.future;

//     return FlutterCaptchaImage._(image);
//   }

//   static Future<FlutterCaptchaImage> fromAsset(String path) async {
//     final data = await _loadFrom(path);

//     // Utilize flutter's built-in decoder to decode asset images as it will be
//     // faster than the dart decoder.
//     final buffer =
//         await ui.ImmutableBuffer.fromUint8List(data.buffer.asUint8List());

//     final id = await ui.ImageDescriptor.encoded(buffer);
//     final codec = await id.instantiateCodec(
//         targetHeight: id.height, targetWidth: id.width);

//     final fi = await codec.getNextFrame();

//     final uiImage = fi.image;
//     final uiBytes = await uiImage.toByteData();

//     final image = img_lib.Image.fromBytes(
//         width: id.width,
//         height: id.height,
//         bytes: uiBytes!.buffer,
//         numChannels: 4);

//     return FlutterCaptchaImage._(image);
//   }

//   static Future<img_lib.Image> _convertFlutterUiToImage(ui.Image input) async {
//     final bytes = await input.toByteData();

//     final image = img_lib.Image.fromBytes(
//       width: input.width,
//       height: input.height,
//       bytes: bytes!.buffer,
//       numChannels: 4,
//     );

//     return image;
//   }

//   Map<Alignment, Uint8List> split({
//     required FlutterCaptchaSplit split,
//   }) {
//     return _splitImage(value, split: split);
//   }

//   Future<Map<Alignment, Uint8List>> splitWithDimension({
//     required FlutterCaptchaSplit split,
//     required double dimension,
//   }) async {
//     final command = img_lib.Command()
//       ..image(value)
//       ..copyResizeCropSquare(size: dimension.round());

//     await command.executeThread();

//     return _splitImage(command.outputImage!, split: split);
//   }

//   static Future<ByteData> _loadFrom(String path) async => rootBundle.load(path);

//   Map<Alignment, Uint8List> _splitImage(
//     img_lib.Image image, {
//     required FlutterCaptchaSplit split,
//   }) {
//     var x = 0, y = 0;
//     final width = (image.width / split.xCount).round();
//     final height = (image.height / split.yCount).round();

//     // Split image to parts
//     final parts = <img_lib.Image>[];
//     for (int i = 0; i < split.yCount; i++) {
//       for (int j = 0; j < split.xCount; j++) {
//         parts.add(
//           img_lib.copyCrop(
//             image,
//             x: x,
//             y: y,
//             width: width,
//             height: height,
//           ),
//         );
//         x += width;
//       }
//       x = 0;
//       y += height;
//     }

//     // convert image from image package to Image Widget to display
//     final output = <Alignment, Uint8List>{};

//     for (var i = 0; i < split.alignments.length; i++) {
//       final image = parts[i];
//       final alignment = split.alignments[i];

//       output[alignment] = img_lib.encodePng(image);
//     }

//     return output;
//   }
// }
