import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  StreamController<ThemeData> themeStreamController = StreamController<ThemeData>.broadcast();
  SharedPreferences? prefs;

  Stream<ThemeData> getThemeStream() {
    return themeStreamController.stream;
  }

  void setTheme(ThemeData selectedTheme, String stringTheme) {
    themeStreamController.add(selectedTheme);
    prefs!.setString('selectedTheme', stringTheme);
    debugPrint('Theme: $stringTheme');
  }

  void loadTheme() async {
    prefs = await SharedPreferences.getInstance();
    ThemeData currentTheme = _createThemeData(Colors.black);
    if (prefs!.containsKey('selectedTheme')) {
      String selectedTheme = prefs!.getString('selectedTheme')!;
      Color primaryColor;
      switch (selectedTheme) {
        case 'black':
          primaryColor = Colors.black;
          break;
        case 'white':
          primaryColor = Colors.white;
          break;
        default:
          primaryColor = Colors.black;
      }
      currentTheme = _createThemeData(primaryColor);
    }
    themeStreamController.add(currentTheme);
  }

  ThemeData _createThemeData(Color primaryColor) {
    bool isDark = primaryColor == Colors.black;
    return ThemeData(
      primaryColor: primaryColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark ? Colors.black : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.black : primaryColor,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ).copyWith(surface: isDark ? Colors.black : Colors.white),
    );
  }
}