import 'package:flutter/material.dart';
import 'features/auth/views/session_gate.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dialysis Record',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF256D85),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        cardTheme: const CardThemeData(
          color: Color(0xFFFFFFFF),
          surfaceTintColor: Color(0xFFFFFFFF),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const SessionGate(),
    );
  }
}
