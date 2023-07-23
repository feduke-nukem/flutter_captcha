part of 'flutter_captcha.dart';

/// {@template flutter_captcha_input}
/// A captcha input for flutter.
/// {@endtemplate}
abstract base class FlutterCaptchaInput {
  /// @nodoc.
  const FlutterCaptchaInput();

  /// Creates a image from the input.
  Future<FlutterCaptchaImage> createImage();

  /// Constructs a [FlutterCaptchaInput] from an asset path.
  const factory FlutterCaptchaInput.asset(String path) = _AssetInput;

  /// Constructs a [FlutterCaptchaInput] from an [ImageProvider].
  const factory FlutterCaptchaInput.provider(
    ImageProvider provider, {
    AssetBundle? bundle,
  }) = _ProviderInput;

  factory FlutterCaptchaInput.widget(
    Widget widget,
  ) = _WidgetInput;

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

final class _AssetInput extends FlutterCaptchaInput {
  const _AssetInput(this.path);

  final String path;

  @override
  Future<FlutterCaptchaImage> createImage() async {
    final byteData = await services.rootBundle.load(path);

    // Utilize flutter's built-in decoder to decode asset images as it will be
    // faster than the dart decoder.
    final buffer =
        await ui.ImmutableBuffer.fromUint8List(byteData.buffer.asUint8List());

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
      numChannels: 4,
    );

    return FlutterCaptchaImage(image);
  }
}

final class _ProviderInput extends FlutterCaptchaInput {
  const _ProviderInput(
    this.provider, {
    this.bundle,
  });

  final ImageProvider provider;
  final AssetBundle? bundle;

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

    final imageStream = provider.resolve(
      ImageConfiguration(bundle: bundle),
    );
    imageStream.addListener(listener);

    final image = await completer.future;

    return FlutterCaptchaImage(image);
  }
}

final class _WidgetInput extends FlutterCaptchaInput {
  _WidgetInput(this.widget);

  final _completer = Completer<img_lib.Image>();
  final Widget widget;

  @override
  Future<FlutterCaptchaImage> createImage() async =>
      FlutterCaptchaImage(await _completer.future);

  Future<void> _complete(ui.Image image) async => _completer.complete(
        await _convertFlutterUiToImage(image),
      );
}
