import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/widget_service.dart';

/// Хранит выбранную тему и сохраняет её в Hive (бокс 'settings').
/// Бокс должен быть открыт в main(): `await Hive.openBox('settings');`.
class ThemeProvider extends ChangeNotifier {
  static const String boxName = 'settings';
  static const String _key = 'themeChoice';

  late final Box _box;
  AppThemeChoice _choice = AppThemeChoice.system;

  AppThemeChoice get choice => _choice;
  ThemeMode get themeMode => _choice.themeMode;
  bool get isGlass => _choice.isGlass;

  ThemeProvider() {
    _box = Hive.box(boxName);
    final stored = _box.get(_key);
    if (stored is int && stored >= 0 && stored < AppThemeChoice.values.length) {
      _choice = AppThemeChoice.values[stored];
    }
  }

  void setChoice(AppThemeChoice choice) {
    if (choice == _choice) return;
    _choice = choice;
    _box.put(_key, choice.index);
    notifyListeners();
    // Обновляем виджеты под выбранную тему.
    final widgetTheme = switch (choice) {
      AppThemeChoice.light || AppThemeChoice.glassLight => 'light',
      AppThemeChoice.dark || AppThemeChoice.glassDark => 'dark',
      AppThemeChoice.system => 'system',
    };
    unawaited(WidgetService.updateWidget(theme: widgetTheme));
  }
}
