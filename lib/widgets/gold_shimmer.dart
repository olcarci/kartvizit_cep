import 'dart:async';

import 'package:flutter/material.dart';

/// A quiet highlight pass, separated by still intervals.
class GoldShimmer extends StatefulWidget {
  final Widget child;
  final double radius;
  final bool enabled;
  const GoldShimmer({
    super.key,
    required this.child,
    this.radius = 22,
    this.enabled = true,
  });
  @override
  State<GoldShimmer> createState() => _GoldShimmerState();
}

class _GoldShimmerState extends State<GoldShimmer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  Timer? _pause;
  bool _visible = true;
  bool get _allowed =>
      mounted &&
      _visible &&
      widget.enabled &&
      !MediaQuery.disableAnimationsOf(context) &&
      TickerMode.valuesOf(context).enabled;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _schedule();
    });
  }

  void _schedule() {
    _pause?.cancel();
    if (!_allowed) {
      _controller.stop();
      return;
    }
    _pause = Timer(const Duration(seconds: 5), () {
      if (_allowed) _controller.forward(from: 0);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant GoldShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visible = state == AppLifecycleState.resumed;
    _schedule();
  }

  @override
  void dispose() {
    _pause?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.radius),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _GoldPainter(_controller, active: _allowed),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _GoldPainter extends CustomPainter {
  final Animation<double> progress;
  final bool active;
  _GoldPainter(this.progress, {required this.active})
    : super(repaint: progress);
  @override
  void paint(Canvas canvas, Size size) {
    if (!active || progress.value <= 0 || progress.value >= 1) return;
    final center = -size.width + progress.value * size.width * 3;
    final bounds = Rect.fromLTWH(
      center - size.width * 0.35,
      -size.height,
      size.width * 0.7,
      size.height * 3,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.skew(-0.22, 0);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0x00D8B35C),
            Color(0x18D8B35C),
            Color(0x38FFE5A3),
            Color(0x18D8B35C),
            Color(0x00D8B35C),
          ],
          stops: [0, 0.3, 0.5, 0.7, 1],
        ).createShader(bounds),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoldPainter oldDelegate) =>
      oldDelegate.active != active || oldDelegate.progress != progress;
}
