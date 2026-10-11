import 'package:flutter/material.dart';

import 'api.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = await Api.load();
  runApp(StepQuestApp(api: api));
}

class StepQuestApp extends StatelessWidget {
  const StepQuestApp({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Quest',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: api.loggedIn ? HomeScreen(api: api) : LoginScreen(api: api),
    );
  }
}

ThemeData _theme(Brightness brightness) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        brightness: brightness,
      ),
    );
