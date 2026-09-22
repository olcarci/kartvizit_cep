import 'dart:math' as math;

import 'package:flutter/material.dart';

class IvoryHero extends StatelessWidget {
  const IvoryHero({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const title = Text(
        'Yeni tanışmalar,\nhep elinin altında.',
        style: TextStyle(
          fontFamily: 'Lora',
          fontSize: 30,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: Color(0xFF10382F),
        ),
      );
      if (constraints.maxWidth < 310 ||
          MediaQuery.textScalerOf(context).scale(30) > 39) {
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            Align(alignment: Alignment.centerRight, child: DecorativeCards()),
          ],
        );
      }
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: title),
          SizedBox(width: 8),
          DecorativeCards(),
        ],
      );
    },
  );
}

class DecorativeCards extends StatelessWidget {
  const DecorativeCards({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 106,
      height: 164,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 14,
            left: 6,
            child: Transform.rotate(
              angle: -0.16,
              child: Container(
                width: 80,
                height: 124,
                decoration: BoxDecoration(
                  color: const Color(0xFF174B40),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22655333),
                      blurRadius: 10,
                      offset: Offset(3, 6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 32,
            left: 18,
            child: Transform.rotate(
              angle: 0.13,
              child: Container(
                width: 82,
                height: 122,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFDF8), Color(0xFFEDE5D6)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFFE6DCCB)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33655333),
                      blurRadius: 12,
                      offset: Offset(3, 7),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 25,
                      height: 31,
                      child: CustomPaint(painter: OlivePainter(gold: true)),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Yeni\nbağlantılar,\ndaha fazla\nfırsat.',
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 10,
                            height: 1.25,
                            color: Color(0xFF10382F),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class IvoryFooter extends StatelessWidget {
  const IvoryFooter({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'İnsanlar\nbağlantıyla büyür.',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 15,
                  height: 1.6,
                  letterSpacing: 0.8,
                  color: Color(0xFF3F4938),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 40,
                child: Divider(color: Color(0xFFB99760), thickness: 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ExcludeSemantics(
          child: Transform.rotate(
            angle: 0.15,
            child: const SizedBox(
              width: 58,
              height: 112,
              child: CustomPaint(painter: OlivePainter()),
            ),
          ),
        ),
      ],
    ),
  );
}

class OlivePainter extends CustomPainter {
  final bool gold;
  const OlivePainter({this.gold = false});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 60, size.height / 120);
    final stem = Paint()
      ..color = gold ? const Color(0xFFB99760) : const Color(0xFF7A7D54)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(36, 118)
        ..quadraticBezierTo(16, 62, 34, 4),
      stem,
    );
    for (var i = 0; i < 7; i++) {
      final y = 20.0 + i * 13;
      final x = 26.0 + (i - 3).abs() * 1.3;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i.isEven ? -0.65 : 0.9);
      final side = i.isEven ? -1.0 : 1.0;
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(side * 23, -4, side * 20, -25)
        ..quadraticBezierTo(side * 3, -22, 0, 0);
      canvas.drawPath(
        leaf,
        Paint()
          ..shader = LinearGradient(
            colors: gold
                ? const [Color(0xFFB99760), Color(0xFFD8C498)]
                : const [Color(0xFF63754C), Color(0xFFABB08A)],
          ).createShader(Rect.fromLTWH(math.min(0, side * 23), -25, 23, 25)),
      );
      canvas.drawLine(
        Offset.zero,
        Offset(side * 18, -22),
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..strokeWidth = 0.6,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OlivePainter oldDelegate) =>
      oldDelegate.gold != gold;
}
