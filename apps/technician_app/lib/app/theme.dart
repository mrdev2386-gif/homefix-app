import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.green,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
