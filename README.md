

#### Flutter Captcha

<a href="https://codecov.io/gh/feduke-nukem/flutter_captcha" > 
 <img src="https://codecov.io/gh/feduke-nukem/flutter_captcha/graph/badge.svg?token=XEATIDADCY"/> 
</a>


<img src="https://github.com/feduke-nukem/flutter_captcha/assets/72284940/4943f240-ffe1-4bcc-98fc-f7f7d8188ac5" alt="2" height="400"/>
<img src="https://github.com/feduke-nukem/flutter_captcha/assets/72284940/add3ad8c-baf2-403e-bb52-2a7ba6005b5b" alt="3" height="400"/>

## Features

Provide any widget, and it will be automatically divided into parts that can be rotated and positioned. At any point, you can check the solution status to confirm if the user has successfully passed the captcha test.

## Getting started

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _controller = FlutterCaptchaController(
    random: Random.secure(),
  )..init();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: FlutterCaptcha(
            controller: _controller,
            crossLine: (color: Colors.white, width: 10),
            fit: BoxFit.cover,
            draggingBuilder: (_, child) => Opacity(opacity: 0.5, child: child),
            child: Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/4/4f/Dash%2C_the_mascot_of_the_Dart_programming_language.png',
            ),
          ),
        ),
      ),
    );
  }
}
```
