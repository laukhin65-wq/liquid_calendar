import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════
/// Выбор темы оформления. 5 вариантов:
///   • system     — как в системе
///   • light       — светлая
///   • dark        — тёмная
///   • glassLight  — Стекло (светлая)
///   • glassDark   — Стекло (тёмная)
/// «Стеклянные» варианты включают флаг [isGlass] → полупрозрачные поверхности
/// + размытие фона (BackdropFilter), см. widgets/glass.dart.
/// ════════════════════════════════════════════════════════════════════════
enum AppThemeChoice { system, light, dark, glassLight, glassDark }

extension AppThemeChoiceX on AppThemeChoice {
  String get label {
    switch (this) {
      case AppThemeChoice.system:
        return 'Как в системе';
      case AppThemeChoice.light:
        return 'Светлая';
      case AppThemeChoice.dark:
        return 'Тёмная';
      case AppThemeChoice.glassLight:
        return 'Стекло — светлая';
      case AppThemeChoice.glassDark:
        return 'Стекло — тёмная';
    }
  }

  String get subtitle {
    switch (this) {
      case AppThemeChoice.system:
        return 'Следует за настройками устройства';
      case AppThemeChoice.light:
        return 'Всегда светлая';
      case AppThemeChoice.dark:
        return 'Всегда тёмная';
      case AppThemeChoice.glassLight:
        return 'Стеклянные элементы, светлый фон';
      case AppThemeChoice.glassDark:
        return 'Стеклянные элементы, тёмный фон';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeChoice.system:
        return Icons.phone_iphone;
      case AppThemeChoice.light:
        return Icons.light_mode;
      case AppThemeChoice.dark:
        return Icons.dark_mode;
      case AppThemeChoice.glassLight:
      case AppThemeChoice.glassDark:
        return Icons.blur_on;
    }
  }

  /// Какой ThemeMode подать в MaterialApp.
  ThemeMode get themeMode {
    switch (this) {
      case AppThemeChoice.system:
        return ThemeMode.system;
      case AppThemeChoice.light:
      case AppThemeChoice.glassLight:
        return ThemeMode.light;
      case AppThemeChoice.dark:
      case AppThemeChoice.glassDark:
        return ThemeMode.dark;
    }
  }

  /// Включён ли «стеклянный» режим.
  bool get isGlass =>
      this == AppThemeChoice.glassLight || this == AppThemeChoice.glassDark;
}

/// Сборка ThemeData.
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF0A84FF); // iOS blue

  static ThemeData light({bool glass = false}) =>
      _build(Brightness.light, glass);

  static ThemeData dark({bool glass = false}) => _build(Brightness.dark, glass);

  static ThemeData _build(Brightness brightness, bool glass) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    // В glass-режиме фон прозрачный — сквозь него виден градиент-подложка
    // (GlassBackdrop в calendar_screen). В обычном — сплошной фон.
    final scaffoldBg = glass
        ? Colors.transparent
        : (isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7));

    // Стекло: карточки заметно прозрачнее (контент читается сквозь
    // стекло, как в iOS 26), цвет задаёт сам GlassContainer.
    final cardColor = glass
        ? (isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.30))
        : (isDark ? const Color(0xFF1C1C1E) : Colors.white);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      cardColor: cardColor,
    );
  }
}
