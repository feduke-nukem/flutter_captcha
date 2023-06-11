// import 'dart:math' as math;

import 'package:flutter_captcha/flutter_captcha.dart';
import 'package:flutter/material.dart';

enum _Assets {
  fedor('assets/fedor.jpg'),
  shrek('assets/shrek.jpeg'),
  flutterDash('assets/flutter-dash.png'),
  shrek2('assets/shrek2.webp');

  final String path;
  const _Assets(this.path);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Captcha'),
        ),
        body: FlutterCaptcha(
          split: const FlutterCaptchaSplit.threeByThree(),
          assets: [_Assets.shrek.path],
          imageProviders: [
            NetworkImage(
                'https://images.pushsquare.com/b0d35b53cd1e4/cyberpunk-edgerunners-anime-review.large.jpg')
          ],
        ));
  }
}
