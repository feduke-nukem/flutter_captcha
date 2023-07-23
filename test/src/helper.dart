import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_captcha/flutter_captcha.dart';
import 'package:flutter_captcha/src/flutter_captcha_image.dart';
import 'package:flutter_captcha/src/flutter_captcha_part.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img_lib;
import 'package:transparent_image/transparent_image.dart' as transparent_image;

FlutterCaptchaInput createFakeInput() => const FakeInput();

final class FakeInput extends FlutterCaptchaInput with Fake {
  const FakeInput();

  @override
  Future<FlutterCaptchaImage> createImage() async =>
      const FakeFlutterCaptchaImage();
}

class FakeFlutterCaptchaImage with Fake implements FlutterCaptchaImage {
  const FakeFlutterCaptchaImage();

  @override
  Future<CaptchaParts> split({
    required int size,
    required double dimension,
    required bool preferIsolate,
  }) async {
    final image = createFakeImage();

    var x = 0.0, y = 0.0;
    final width = image.width / size;
    final height = image.height / size;

    final output = <CaptchaPartPosition, Uint8List>{};

    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        final position = CaptchaPartPosition(x, y);
        output[position] = transparent_image.kTransparentImage;

        x += width;
      }
      x = 0;
      y += height;
    }

    return output;
  }

  @override
  img_lib.Image get value => throw UnimplementedError();
}

img_lib.Image createFakeImage() => img_lib.Image.fromBytes(
      width: 1,
      height: 1,
      bytes: Uint8List.fromList([0, 0, 0, 0]).buffer,
      numChannels: 4,
    );

FakeHttpClient _createMockImageHttpClient(SecurityContext? _) {
  final client = FakeHttpClient();

  return client;
}

R provideMockNetworkImage<R>(
  R Function() fn,
) =>
    HttpOverrides.runZoned(
      fn,
      createHttpClient: _createMockImageHttpClient,
    );

class FakeHttpClient extends Fake implements HttpClient {
  SecurityContext? context;

  @override
  bool autoUncompress = false;

  FakeHttpClientRequest get request => FakeHttpClientRequest();

  FakeHttpClient({
    this.context,
  });

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return request;
  }
}

class FakeHttpClientRequest extends Fake implements HttpClientRequest {
  late final FakeHttpClientResponse response = FakeHttpClientResponse();

  FakeHttpClientRequest();

  @override
  Future<HttpClientResponse> close() async {
    return response;
  }
}

class FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  final FakeHttpHeaders headers = FakeHttpHeaders();

  @override
  int get statusCode => 200;

  @override
  int get contentLength => transparent_image.kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  FakeHttpClientResponse();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    void Function()? onDone,
    Function? onError,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(
        <List<int>>[transparent_image.kTransparentImage]).listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  }
}

class FakeHttpHeaders extends Fake implements HttpHeaders {}

class FakeAssetBundle extends CachingAssetBundle with Fake {
  @override
  Future<ByteData> load(String key) async =>
      transparent_image.kTransparentImage.buffer.asByteData();
}

Future<void> initFakeBundle() async {
  final bundle = FakeAssetBundle();
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      return bundle.load(key);
    },
  );
}
