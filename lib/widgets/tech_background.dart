import 'dart:math' as math;

import 'package:flutter/material.dart';

class TechBackground extends StatelessWidget {
  final Widget child;

  const TechBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF07111F), Color(0xFF0A1830), Color(0xFF11102B)],
              ),
            ),
          ),
          const CustomPaint(painter: _MarketGridPainter()),
          Positioned(
            top: -110,
            right: -90,
            child: _GlowOrb(color: Color(0xFF00D9FF), size: 280),
          ),
          Positioned(
            bottom: -130,
            left: -100,
            child: _GlowOrb(color: Color(0xFF7C4DFF), size: 300),
          ),
          child,
        ],
      );
}

class TechPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  const TechPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFF12223A).withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: const Color(0xFF5EE7F4).withValues(alpha: 0.25)),
          boxShadow: const [
            BoxShadow(color: Color(0x4400D9FF), blurRadius: 24, offset: Offset(0, 10)),
            BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 5)),
          ],
        ),
        child: child,
      );
}

class TechBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const TechBadge({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF00D9FF).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: const Color(0xFF7EF3FF)),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(
            color: Color(0xFFB9F8FF), fontSize: 12, fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          )),
        ]),
      );
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)]),
          ),
        ),
      );
}

class _MarketGridPainter extends CustomPainter {
  const _MarketGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFF55DDEB).withValues(alpha: 0.055)
      ..strokeWidth = 1;
    const spacing = 42.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final points = <Offset>[];
    final base = size.height * 0.64;
    final amplitude = math.min(70.0, size.height * 0.09);
    const steps = 10;
    for (var i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      final trend = amplitude * (i / steps);
      final wave = math.sin(i * 1.7) * amplitude * 0.36;
      points.add(Offset(x, base - trend - wave));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.16)
      ..strokeWidth = 9
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.stroke);
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF45E9F5).withValues(alpha: 0.38)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
