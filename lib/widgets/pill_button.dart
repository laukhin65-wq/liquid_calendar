import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'glass.dart';

bool get _liquidSupported {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.android:
    case TargetPlatform.macOS:
      return true;
    default:
      return false;
  }
}

/// «Пилюля»-кнопка в стиле iOS 26 Liquid Glass.
///   • glass-тема → настоящее жидкое стекло (рефракция фона);
///   • обычная тема → лёгкая адаптивная заливка.
/// При нажатии слегка сжимается. Если задан [inLayer] и кнопка внутри
/// [LiquidGlassGroup] — стекло сливается с соседними пилюлями.
class PillButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool inLayer;

  const PillButton({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.inLayer = false,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  static const _pressDuration = Duration(milliseconds: 160);
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final glass = isGlassTheme(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(30);

    final pressBoost = _pressed ? 0.08 : 0.0;

    // Содержимое (текст/иконки) — всегда чёткое, поверх стекла.
    Widget content = Padding(padding: widget.padding, child: widget.child);

    Widget inner;
    if (glass && _liquidSupported) {
      // Настоящее жидкое стекло.
      final shape = LiquidRoundedSuperellipse(borderRadius: 30);
      if (widget.inLayer) {
        inner = LiquidGlass(shape: shape, child: content);
      } else {
        inner = LiquidGlass.withOwnLayer(
          shape: shape,
          settings: glassSettings(
            isDark: isDark,
            blur: 6,
            thickness: 14,
            tintOpacity: (isDark ? 0.10 : 0.16) + pressBoost,
          ),
          child: content,
        );
      }
    } else if (glass) {
      // Фолбэк для платформ без Impeller.
      final fill =
          Colors.white.withValues(alpha: (isDark ? 0.12 : 0.45) + pressBoost);
      inner = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: CustomPaint(
            foregroundPainter:
                LensBorderPainter(borderRadius: radius, isDark: isDark, width: 1),
            child: DecoratedBox(
              decoration: BoxDecoration(color: fill, borderRadius: radius),
              child: content,
            ),
          ),
        ),
      );
    } else {
      // Обычная тема.
      final fill = isDark
          ? Colors.white.withValues(alpha: 0.08 + pressBoost)
          : Colors.black.withValues(alpha: 0.05 + pressBoost);
      inner = ClipRRect(
        borderRadius: radius,
        child: AnimatedContainer(
          duration: _pressDuration,
          curve: Curves.easeOut,
          decoration: BoxDecoration(color: fill, borderRadius: radius),
          child: content,
        ),
      );
    }

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: _pressDuration,
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          onHighlightChanged: _setPressed,
          child: inner,
        ),
      ),
    );
  }
}
