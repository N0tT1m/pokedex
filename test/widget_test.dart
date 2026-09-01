// Smoke tests for the app shell. These deliberately avoid pumping the full
// widget tree (the Home tab pulls in Hive storage and network calls that make
// a bare `pumpWidget(MyApp())` flaky in CI); instead they assert the app-level
// wiring that must hold for a build to be shippable.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex/main.dart';
import 'package:pokedex/theme/app_theme.dart';

void main() {
  test('MyApp records the dark-mode flag it is constructed with', () {
    expect(const MyApp(isDarkMode: true).isDarkMode, isTrue);
    expect(const MyApp(isDarkMode: false).isDarkMode, isFalse);
    expect(const MyApp().isDarkMode, isFalse); // default
  });

  test('AppTheme exposes distinct light and dark themes', () {
    expect(AppTheme.lightTheme, isA<ThemeData>());
    expect(AppTheme.darkTheme, isA<ThemeData>());
    expect(AppTheme.lightTheme.brightness, Brightness.light);
    expect(AppTheme.darkTheme.brightness, Brightness.dark);
  });
}
