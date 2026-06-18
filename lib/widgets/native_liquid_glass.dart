import 'package:flutter/widgets.dart';

/// DEPRECATED: нативный Liquid Glass PlatformView отключён.
///
/// Прежняя нативная реализация (Android RenderEffect на самом контейнере)
/// размывала собственное содержимое, а не backdrop, поэтому реального
/// «жидкого стекла» не давала. Теперь GlassContainer на всех платформах
/// использует Flutter BackdropFilter (Impeller корректно блюрит фон и на
/// Android). Виджет сохранён как passthrough только для совместимости API.
class NativeLiquidGlass extends StatelessWidget {
  final Widget child;
  final double blurAmount;
  final double saturation;
  final double aberrationIntensity;
  final double cornerRadius;
  final double displacementScale;

  const NativeLiquidGlass({
    super.key,
    required this.child,
    this.blurAmount = 0.0625,
    this.saturation = 140,
    this.aberrationIntensity = 2,
    this.cornerRadius = 999,
    this.displacementScale = 70,
  });

  @override
  Widget build(BuildContext context) => child;
}
