import 'dart:ui' as ui show ImageFilter, ColorFilter;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../providers/theme_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LIQUID GLASS — настоящее «жидкое стекло» в духе iOS 26.
///
/// На iOS / Android / macOS (Impeller) используется пакет liquid_glass_renderer:
/// реальная РЕФРАКЦИЯ фона по краям + хроматическая аберрация + блик +
/// СЛИЯНИЕ соседних фигур «каплями» (через [LiquidGlassGroup]).
///
/// На Web / Desktop (Skia) пакет не поддерживается, поэтому используется
/// продвинутый Flutter-фолбэк (BackdropFilter + saturation + squircle + блик).
/// ═══════════════════════════════════════════════════════════════════════════

/// Поддерживается ли аппаратное жидкое стекло (Impeller-платформы).
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

/// Включён ли стеклянный режим текущей темы.
bool isGlassTheme(BuildContext context) =>
    context.watch<ThemeProvider>().isGlass;

/// Обёртка-слушатель прокрутки (оставлена для совместимости API).
class GlassShimmerDriver extends StatelessWidget {
  final Widget child;
  const GlassShimmerDriver({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

/// Базовые настройки жидкого стекла под текущую тему.
LiquidGlassSettings glassSettings({
  required bool isDark,
  Color? tint,
  double? tintOpacity,
  double blur = 8,
  double thickness = 16,
  double saturation = 1.6,
}) {
  final base = tint ?? Colors.white;
  final alpha = tintOpacity ?? (isDark ? 0.10 : 0.18);
  return LiquidGlassSettings(
    thickness: thickness,
    blur: blur,
    glassColor: base.withValues(alpha: alpha),
    chromaticAberration: 2,
    lightIntensity: isDark ? 1.0 : 1.3,
    ambientStrength: isDark ? 0.6 : 0.4,
    saturation: saturation,
  );
}

/// Матрица повышения насыщенности (для модальных стеклянных поверхностей).
List<double> glassSaturationMatrix(double s, {double brightness = 0.0}) {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final sr = (1 - s) * lr, sg = (1 - s) * lg, sb = (1 - s) * lb;
  final b = brightness * 255.0;
  return <double>[
    sr + s, sg,     sb,     0, b,
    sr,     sg + s, sb,     0, b,
    sr,     sg,     sb + s, 0, b,
    0,      0,      0,      1, 0,
  ];
}

/// Композитный фильтр стекла для модалок/листов: блюр + boost насыщенности.
/// Используйте в BackdropFilter диалогов и bottom sheet'ов, чтобы фрост-стекло
/// совпадало по стилю с жидким стеклом остальной темы.
ui.ImageFilter glassBlurFilter({double blur = 16, double saturation = 1.5}) {
  return ui.ImageFilter.compose(
    outer: ui.ColorFilter.matrix(glassSaturationMatrix(saturation)),
    inner: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
  );
}

/// Группа жидкого стекла: дочерние [GlassContainer]/[PillButton], помеченные
/// `inLayer: true`, будут СЛИВАТЬСЯ каплями при сближении (как iOS 26 Dock).
/// Используйте для строки пилюль в шапке/нижнем баре.
class LiquidGlassGroup extends StatelessWidget {
  final Widget child;
  final LiquidGlassSettings? settings;
  const LiquidGlassGroup({super.key, required this.child, this.settings});

  @override
  Widget build(BuildContext context) {
    // Слой создаётся только в glass-теме на Impeller-платформах,
    // иначе возвращаем содержимое без лишней текстуры.
    if (!_liquidSupported || !isGlassTheme(context)) return child;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LiquidGlassLayer(
      settings: settings ?? glassSettings(isDark: isDark),
      child: child,
    );
  }
}

/// «Жидкое стекло» — основной публичный виджет.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final double? tintOpacity;
  final bool border;
  final double highlightShift;
  final double saturation;

  /// Если true и виджет внутри [LiquidGlassGroup] — стекло сливается с соседями.
  final bool inLayer;

  /// Оставлен для обратной совместимости (нативный путь удалён).
  final bool useNative;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 8,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.padding,
    this.tint,
    this.tintOpacity,
    this.border = true,
    this.highlightShift = 0,
    this.saturation = 1.6,
    this.inLayer = false,
    this.useNative = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padded = padding != null
        ? Padding(padding: padding!, child: child)
        : child;
    final radius = borderRadius.topLeft.x;

    if (_liquidSupported) {
      final shape = LiquidRoundedSuperellipse(borderRadius: radius);
      if (inLayer) {
        // Сливается с соседями внутри LiquidGlassGroup.
        return LiquidGlass(shape: shape, child: padded);
      }
      return LiquidGlass.withOwnLayer(
        shape: shape,
        settings: glassSettings(
          isDark: isDark,
          tint: tint,
          tintOpacity: tintOpacity,
          blur: blur,
          saturation: saturation,
        ),
        child: padded,
      );
    }

    // Фолбэк (Web/Desktop/Skia).
    return _FallbackGlass(
      blur: blur < 10 ? 14 : blur,
      borderRadius: borderRadius,
      padding: padding,
      tint: tint,
      tintOpacity: tintOpacity,
      border: border,
      highlightShift: highlightShift,
      saturation: saturation,
      child: child,
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Фолбэк: продвинутый Flutter BackdropFilter (для платформ без Impeller).
/// ─────────────────────────────────────────────────────────────────────────
class _FallbackGlass extends StatefulWidget {
  final Widget child;
  final double blur;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final double? tintOpacity;
  final bool border;
  final double highlightShift;
  final double saturation;

  const _FallbackGlass({
    required this.child,
    required this.blur,
    required this.borderRadius,
    this.padding,
    this.tint,
    this.tintOpacity,
    this.border = true,
    this.highlightShift = 0,
    this.saturation = 1.6,
  });

  @override
  State<_FallbackGlass> createState() => _FallbackGlassState();
}

class _FallbackGlassState extends State<_FallbackGlass> {
  final GlobalKey _key = GlobalKey();

  double _computeShift(BuildContext context) {
    final manual = widget.highlightShift;
    if (manual != 0) return manual.clamp(0.0, 1.0);
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return 0;
    final scrollOffset = scrollable.position.pixels;
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 0;
    final viewport =
        Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (viewport == null) return 0;
    final myPos = box.localToGlobal(Offset.zero, ancestor: viewport);
    final raw = (scrollOffset - myPos.dy * 0.3) / 600.0;
    final t = raw.abs() % 2.0;
    return t <= 1.0 ? t : 2.0 - t;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.tint ?? Colors.white;
    final edgeAlpha = widget.tintOpacity ?? (isDark ? 0.12 : 0.24);
    final centerAlpha = (edgeAlpha * 0.35).clamp(0.0, 1.0);
    final t = _computeShift(context);

    final filter = ui.ImageFilter.compose(
      outer: ui.ColorFilter.matrix(
        glassSaturationMatrix(widget.saturation, brightness: isDark ? 0.02 : 0.0),
      ),
      inner: ui.ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
    );

    final content = BackdropFilter(
      filter: filter,
      child: CustomPaint(
        painter: _GlarePainter(
          borderRadius: widget.borderRadius, isDark: isDark, shift: t),
        foregroundPainter: widget.border
            ? LensBorderPainter(borderRadius: widget.borderRadius, isDark: isDark)
            : null,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.4 + t * 0.8, -0.5),
              radius: 1.15,
              colors: [
                base.withValues(alpha: centerAlpha),
                base.withValues(alpha: edgeAlpha),
              ],
              stops: const [0.5, 1.0],
            ),
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
                blurRadius: 8,
                spreadRadius: -6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.85, 1.0],
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
              ],
            ),
          ),
          child: widget.child,
        ),
      ),
    );

    return KeyedSubtree(
      key: _key,
      child: _SquircleClip(borderRadius: widget.borderRadius, child: content),
    );
  }
}

/// Squircle-клип. ClipRSuperellipse доступен в Flutter 3.32+.
/// Если SDK старее — замените на ClipRRect.
class _SquircleClip extends StatelessWidget {
  final BorderRadius borderRadius;
  final Widget child;
  const _SquircleClip({required this.borderRadius, required this.child});

  @override
  Widget build(BuildContext context) =>
      ClipRSuperellipse(borderRadius: borderRadius, child: child);
}

class _GlarePainter extends CustomPainter {
  final BorderRadius borderRadius;
  final bool isDark;
  final double shift;
  const _GlarePainter({
    required this.borderRadius,
    required this.isDark,
    required this.shift,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(borderRadius.toRRect(rect));
    final center = Offset(size.width * (0.16 + shift * 0.55), 0);
    final glare = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.22 : 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.6));
    canvas.drawRect(rect, glare);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlarePainter old) =>
      old.shift != shift || old.isDark != isDark;
}

/// «Линзовая» окантовка с двойным rim-light.
class LensBorderPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final bool isDark;
  final double width;
  const LensBorderPainter({
    required this.borderRadius,
    required this.isDark,
    this.width = 1.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(width / 2);
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.70 : 1.0),
          Colors.white.withValues(alpha: isDark ? 0.04 : 0.12),
          Colors.white.withValues(alpha: isDark ? 0.30 : 0.55),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, outer);
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.6
      ..color = Colors.black.withValues(alpha: isDark ? 0.18 : 0.05);
    canvas.drawRRect(rrect.deflate(width * 0.7), inner);
  }

  @override
  bool shouldRepaint(LensBorderPainter old) =>
      old.isDark != isDark ||
      old.width != width ||
      old.borderRadius != borderRadius;
}

/// Цветная подложка-градиент под стеклом (фон glass-режима).
class GlassBackdrop extends StatelessWidget {
  final Widget child;
  const GlassBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF2A1456),
                  Color(0xFF0A0A18),
                  Color(0xFF06304F),
                ]
              : const [
                  Color(0xFFA9C7FF),
                  Color(0xFFE3C9FF),
                  Color(0xFFB6F1DC),
                ],
        ),
      ),
      child: child,
    );
  }
}
