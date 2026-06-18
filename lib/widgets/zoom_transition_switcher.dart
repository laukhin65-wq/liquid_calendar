import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// ════════════════════════════════════════════════════════════════════════
/// iOS-style ZOOM-переходы между год → месяц → неделя → день.
///
/// Идея как в Календаре iOS: это НЕ слайд между экранами, а непрерывный
/// «наезд камеры» в ту точку, по которой ты тапнул.
///  • Год → Месяц: сетка года растёт и тает, а полный месяц появляется из
///    той же точки (scale 0.88→1.0 + fade in).
///  • Назад (Месяц → Год): zoom-out — экран ужимается на своё место.
///  • Якорь масштаба = точка тапа, а не центр экрана.
///
/// Движок — настоящая физическая ПРУЖИНА (`SpringSimulation`) с лёгким
/// overshoot, как у Apple. Контроллер `unbounded`, т.к. пружина перелетает
/// за 1.0 и возвращается; прозрачность клампим в [0,1].
/// ════════════════════════════════════════════════════════════════════════

/// Характер пружины. Подбирается под вкус:
///  • stiffness ↑ — быстрее/резче.
///  • damping ↓ — сильнее overshoot (более «пружинисто»); ↑ — мягче, без отскока.
/// Текущие значения ≈ iOS-spring: response ~0.5s, лёгкий отскок ~5%.
const SpringDescription _kSpring = SpringDescription(
  mass: 1.0,
  stiffness: 120.0,
  damping: 17,
);

/// Глобальная точка тапа, из которой пойдёт наезд. Ячейки записывают её
/// перед сменой вида; переключатель читает её в момент анимации.
final ValueNotifier<Offset?> zoomAnchor = ValueNotifier<Offset?>(null);

/// Запомнить точку тапа по контексту виджета-ячейки.
/// ВАЖНО: вызывать ПЕРЕД `provider.setView(...)`.
void setZoomAnchor(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) {
    zoomAnchor.value = null;
    return;
  }
  zoomAnchor.value = box.localToGlobal(box.size.center(Offset.zero));
}

class ZoomTransitionSwitcher extends StatefulWidget {
  /// Текущий вид. Оборачивай в `KeyedSubtree(key: ValueKey(view), child: ...)`.
  final Widget child;

  /// Глубина текущего вида: year=0, month=1, week=2, day=3.
  /// По разнице глубин определяется направление (наезд / отъезд).
  final int depth;

  /// Глобальная точка наезда (обычно `zoomAnchor.value`).
  final Offset? anchorGlobal;

  const ZoomTransitionSwitcher({
    super.key,
    required this.child,
    required this.depth,
    this.anchorGlobal,
  });

  @override
  State<ZoomTransitionSwitcher> createState() => _ZoomTransitionSwitcherState();
}

class _ZoomTransitionSwitcherState extends State<ZoomTransitionSwitcher>
    with SingleTickerProviderStateMixin {
  // unbounded — пружина может перелетать за 1.0 (overshoot).
  late final AnimationController _ctrl =
      AnimationController.unbounded(vsync: this);

  Widget? _outgoing; // снимок предыдущего вида на время анимации
  Alignment _anchor = Alignment.center;
  bool _zoomIn = true;
  int _gen = 0; // поколение анимации — защита от наложения быстрых тапов

  @override
  void didUpdateWidget(covariant ZoomTransitionSwitcher old) {
    super.didUpdateWidget(old);
    if (widget.depth != old.depth) {
      setState(() {
        _outgoing = old.child; // замораживаем старый вид как снимок
        _zoomIn = widget.depth > old.depth; // глубже → наезд, иначе отъезд
        _anchor = _alignmentFromGlobal(widget.anchorGlobal);
      });

      final myGen = ++_gen;
      _ctrl.value = 0;
      _ctrl.animateWith(SpringSimulation(_kSpring, 0, 1, 0)).then((_) {
        // .then у TickerFuture срабатывает только при штатном завершении,
        // не при отмене (новый тап) — поэтому наложения не будет.
        if (mounted && myGen == _gen) {
          setState(() => _outgoing = null);
        }
      });
    }
  }

  /// Глобальная точка → Alignment относительно собственного бокса.
  Alignment _alignmentFromGlobal(Offset? global) {
    final box = context.findRenderObject() as RenderBox?;
    if (global == null || box == null || !box.hasSize) return Alignment.center;
    final local = box.globalToLocal(global);
    final s = box.size;
    return Alignment(
      (local.dx / s.width) * 2 - 1,
      (local.dy / s.height) * 2 - 1,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ВАЖНО: структура дерева ВСЕГДА одинаковая (и в покое, и в анимации),
    // а входящий слой сидит в фиксированном keyed-слоте. Иначе в конце
    // перехода входящий экран (например DayScreen) пересоздавался бы — и его
    // initState/«скролл к текущему времени» проигрывался бы ДВАЖДЫ.
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final bool animating = _outgoing != null;
        final double t = _ctrl.value; // может выходить за [0,1] из-за overshoot

        // Наезд:  входящий 0.88→1.0,  уходящий 1.0→1.12 (улетает вперёд).
        // Отъезд: входящий 1.12→1.0,  уходящий 1.0→0.88 (садится на место).
        final double incFrom = _zoomIn ? 0.88 : 1.12;
        final double outTo = _zoomIn ? 1.12 : 0.88;

        final double incScale = animating ? incFrom + (1.0 - incFrom) * t : 1.0;
        final double incOpacity = animating ? t.clamp(0.0, 1.0) : 1.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // слот 0 — уходящий слой (снимок) или пусто.
            KeyedSubtree(
              key: const ValueKey('zoom_outgoing'),
              child: animating
                  ? Opacity(
                      opacity: (1.0 - t).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 1.0 + (outTo - 1.0) * t,
                        alignment: _anchor,
                        child: _outgoing,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // слот 1 — входящий вид. Стабильная структура → элемент не
            // пересоздаётся при завершении перехода.
            KeyedSubtree(
              key: const ValueKey('zoom_incoming'),
              child: Opacity(
                opacity: incOpacity,
                child: Transform.scale(
                  scale: incScale,
                  alignment: _anchor,
                  child: widget.child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
