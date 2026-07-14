import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickpass/providers/settings_provider.dart';

void main() {
  group('SettingsProvider', () {
    test('default theme mode is light', () {
      final provider = SettingsProvider();
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, false);
    });

    test('setDarkMode(true) sets dark mode and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = SettingsProvider();

      await provider.setDarkMode(true);

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('setDarkMode(false) sets light mode and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = SettingsProvider();

      await provider.setDarkMode(false);

      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('load() restores dark theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final provider = SettingsProvider();

      await provider.load();

      expect(provider.themeMode, ThemeMode.dark);
    });

    test('load() restores light theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final provider = SettingsProvider();

      await provider.load();

      expect(provider.themeMode, ThemeMode.light);
    });

    test('load() defaults to light when no stored value', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = SettingsProvider();

      await provider.load();

      expect(provider.themeMode, ThemeMode.light);
    });

    test('load() defaults to light for unknown stored value', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'system'});
      final provider = SettingsProvider();

      await provider.load();

      expect(provider.themeMode, ThemeMode.light);
    });

    test('setDarkMode then load preserves the value', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = SettingsProvider();
      await provider.setDarkMode(true);

      final provider2 = SettingsProvider();
      await provider2.load();

      expect(provider2.themeMode, ThemeMode.dark);
    });
  });
}
