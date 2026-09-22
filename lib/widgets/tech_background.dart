import 'package:flutter/material.dart';
import 'gold_shimmer.dart';

class TechBackground extends StatelessWidget {
  final Widget child;
  const TechBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFDF8), Color(0xFFF2EFE7)],
      ),
    ),
    child: GoldShimmer(radius: 0, child: child),
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
    padding: padding,
    margin: margin,
    decoration: BoxDecoration(
      color: const Color(0xFFFFFDF8),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE7DECE)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10655333),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
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
      color: const Color(0xFFF0EBDF),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF8A692F)),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF10382F),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ),
      ],
    ),
  );
}
