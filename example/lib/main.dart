import 'package:flutter/services.dart';
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

final _inputs = [
  const FlutterCaptchaInput.provider(
    NetworkImage(
      'https://images.immediate.co.uk/production/volatile/sites/3/2022/09/Edgerunners-connect-to-Cyberpunk-2077-timeline-b233bcb.jpg?quality=90&resize=980,654',
    ),
  ),
  const FlutterCaptchaInput.provider(
    NetworkImage(
        'https://cdn.vox-cdn.com/thumbor/3HEIMF3j_RDJXedWcXW2xCLESEQ=/1400x1400/filters:format(jpeg)/cdn.vox-cdn.com/uploads/chorus_asset/file/24016181/Cyberpunk_Edgerunners_Season1_Episode3_00_11_24_03.jpg'),
  ),
  const FlutterCaptchaInput.provider(
    NetworkImage(
      'https://images.pushsquare.com/b0d35b53cd1e4/cyberpunk-edgerunners-anime-review.large.jpg',
    ),
  ),
  FlutterCaptchaInput.widget(
    Container(
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        size: 400,
      ),
    ),
  ),
  ..._Assets.values.map((e) => FlutterCaptchaInput.asset(e.path))
];
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
  final _controller = FlutterCaptchaController(inputs: _inputs);
  int _size = 3;
  bool _canMove = true;
  bool _canRotate = true;
  final _textEditingController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      drawer: Drawer(
        child: Builder(builder: (context) {
          return SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    'Can move',
                    style: TextStyle(fontSize: 20),
                  ),
                  Switch(
                    value: _canMove,
                    onChanged: (value) {
                      setState(() {
                        _canMove = value;
                      });
                    },
                  ),
                  const Text(
                    'Can rotate',
                    style: TextStyle(fontSize: 20),
                  ),
                  Switch(
                    value: _canRotate,
                    onChanged: (value) {
                      setState(() {
                        _canRotate = value;
                      });
                    },
                  ),
                  Text(
                    'Split size: $_size',
                    style: const TextStyle(fontSize: 20),
                  ),
                  Slider(
                    value: _size.toDouble(),
                    min: 2,
                    max: 15,
                    onChanged: (value) {
                      setState(() {
                        _size = value.toInt();
                      });
                    },
                  ),
                  const Text(
                    'Specify url for custom input',
                    style: TextStyle(fontSize: 20),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'URL',
                        suffixIcon: FilledButton(
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                          ),
                          child: const Icon(Icons.check),
                          onPressed: () {
                            final url =
                                Uri.tryParse(_textEditingController.text);

                            if (url == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid url'),
                                ),
                              );
                            } else {
                              setState(() {
                                _controller.hardReset(
                                  inputs: [
                                    FlutterCaptchaInput.provider(
                                      NetworkImage(
                                        url.toString(),
                                      ),
                                    ),
                                  ],
                                );
                              });
                              _controller.hardReset();
                            }

                            Scaffold.of(context).closeDrawer();
                          },
                        ),
                      ),
                      keyboardType: TextInputType.url,
                      onChanged: (value) {
                        setState(() {
                          _controller.hardReset(
                            inputs: [
                              FlutterCaptchaInput.provider(NetworkImage(value))
                            ],
                          );
                        });
                        _controller.hardReset();
                      },
                    ),
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
                      _controller.hardReset();
                      sc.closeDrawer();
                    },
                    child: const Text('Restart'),
                  ),
                  const Text(
                    'Next captcha',
                    style: TextStyle(fontSize: 20),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final sc = Scaffold.of(context);
                      _controller.showNextInput();
                      sc.closeDrawer();
                    },
                    child: const Text('Next'),
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
        canMove: _canMove,
        canRotate: _canRotate,
        controller: _controller,
        dimension: width,
        size: _size,
        draggingBuilder: (_, child, __) => Opacity(opacity: 0.5, child: child),
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
    await _controller.showNextInput();
  }
}
