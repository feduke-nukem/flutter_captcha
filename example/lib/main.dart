import 'dart:math';

import 'package:flutter_captcha/flutter_captcha.dart';
import 'package:flutter/material.dart';

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
  bool _crossLined = true;
  double _crossLineWidth = 10.0;
  final _textEditingController = TextEditingController();
  final _controller = FlutterCaptchaController(
    random: Random.secure(),
  )..init();

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Builder(builder: (context) {
          return SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    'Cross lined',
                    style: TextStyle(fontSize: 20),
                  ),
                  Switch(
                    value: _crossLined,
                    onChanged: (value) => setState(() => _crossLined = value),
                  ),
                  const Text(
                    'Can move',
                    style: TextStyle(fontSize: 20),
                  ),
                  Switch(
                    value: _controller.randomizePositions,
                    onChanged: (value) =>
                        setState(() => _controller.randomizePositions = value),
                  ),
                  const Text(
                    'Can rotate',
                    style: TextStyle(fontSize: 20),
                  ),
                  Switch(
                    value: _controller.randomizeAngles,
                    onChanged: (value) =>
                        setState(() => _controller.randomizeAngles = value),
                  ),
                  Text(
                    'Split size: ${_controller.size}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  Slider(
                    value: _controller.size.toDouble(),
                    min: 2,
                    max: 15,
                    onChanged: (value) => setState(
                      () => _controller.size = value.toInt(),
                    ),
                  ),
                  Text(
                    'Cross line width: ${_crossLineWidth.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  Slider(
                    value: _crossLineWidth,
                    min: 1.0,
                    max: 20,
                    onChanged: (value) =>
                        setState(() => _crossLineWidth = value),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    'Check solution',
                    style: TextStyle(fontSize: 20),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await _onCheck(context);
                    },
                    child: const Text('Check'),
                  ),
                  const Text(
                    'Restart',
                    style: TextStyle(fontSize: 20),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final sc = Scaffold.of(context);
                      _controller.reset();
                      sc.closeDrawer();
                    },
                    child: const Text('Restart'),
                  ),
                  const Text(
                    'Solve',
                    style: TextStyle(fontSize: 20),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final sc = Scaffold.of(context);
                      _controller.solve();
                      sc.closeDrawer();
                    },
                    child: const Text('Solve'),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Captcha'),
      ),
      body: FlutterCaptcha(
        controller: _controller,
        crossLine:
            _crossLined ? (color: Colors.white, width: _crossLineWidth) : null,
        fit: BoxFit.cover,
        partsBuilder: (context, part) {
          return ColoredBox(
            color: Colors.red,
            child: part,
          );
        },
        draggingBuilder: (_, child) => Opacity(opacity: 0.5, child: child),
        child: Image.asset('assets/flutter-dash.png'),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(builder: (context) {
            return FloatingActionButton.large(
              onPressed: Scaffold.of(context).openDrawer,
              child: const Icon(Icons.settings),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _onCheck(BuildContext context) async {
    final scaffold = Scaffold.of(context);
    if (_controller.checkSolution()) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('You are not a robot'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          });
      scaffold.closeDrawer();
      return;
    }

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('You are a robot'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        });

    scaffold.closeDrawer();
  }
}
