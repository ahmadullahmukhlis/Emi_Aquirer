import 'package:flutter/material.dart';

abstract final class PosColors {
  static const ink = Color(0xff003f4a);
  static const accent = Color(0xff007c7b);
  static const background = Color(0xfff6f9fb);
  static const soft = Color(0xffe8f6f4);
}

abstract final class PosTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: PosColors.accent),
    scaffoldBackgroundColor: PosColors.background,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
