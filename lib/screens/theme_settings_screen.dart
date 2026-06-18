import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

/// Экран выбора темы оформления (5 вариантов). Открывается из бокового
/// меню → «Настройки».
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final glass = provider.isGlass;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    final body = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: Text(
            'Тема оформления',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        for (final choice in AppThemeChoice.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _ThemeTile(
              choice: choice,
              selected: provider.choice == choice,
              textColor: textColor,
              subtitleColor: subtitleColor,
              onTap: () => context.read<ThemeProvider>().setChoice(choice),
            ),
          ),
      ],
    );

    final scaffold = Scaffold(
      backgroundColor: glass ? Colors.transparent : null,
      appBar: AppBar(
        title: Text('Тема', style: TextStyle(color: textColor)),
        backgroundColor: glass ? Colors.transparent : null,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: body,
    );

    return glass ? GlassBackdrop(child: scaffold) : scaffold;
  }
}

class _ThemeTile extends StatelessWidget {
  final AppThemeChoice choice;
  final bool selected;
  final VoidCallback onTap;
  final Color textColor;
  final Color subtitleColor;

  const _ThemeTile({
    required this.choice,
    required this.selected,
    required this.onTap,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final glass = context.watch<ThemeProvider>().isGlass;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(choice.icon, color: scheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  choice.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  choice.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle, color: scheme.primary)
          else
            Icon(
              Icons.radio_button_unchecked,
              color: scheme.onSurface.withValues(alpha: 0.3),
            ),
        ],
      ),
    );

    final radius = BorderRadius.circular(18);

    // В glass-режиме используем полупрозрачный фон без BackdropFilter
    // (общий GlassBackdrop уже рисует блюр за всем экраном).
    final card = Container(
      decoration: BoxDecoration(
        color: glass
            ? (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.35))
            : Theme.of(context).cardColor,
        borderRadius: radius,
        border: Border.all(
          color: selected
              ? scheme.primary.withValues(alpha: 0.6)
              : (glass
                  ? Colors.white.withValues(alpha: 0.15)
                  : scheme.outlineVariant.withValues(alpha: 0.4)),
          width: selected ? 1.4 : 0.8,
        ),
      ),
      child: content,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: card,
      ),
    );
  }
}
