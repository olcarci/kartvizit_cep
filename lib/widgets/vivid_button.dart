import 'dart:ui';

import 'package:flutter/material.dart';

class VividButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color accent;
  const VividButton({super.key, required this.label, required this.icon,
    required this.onPressed, this.accent = const Color(0xFF45E9F5)});

  @override
  State<VividButton> createState() => _VividButtonState();
}

class _VividButtonState extends State<VividButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final accent = enabled ? widget.accent : const Color(0xFF556478);
    final accentHsl = HSLColor.fromColor(accent);
    final depth = accentHsl
        .withLightness((accentHsl.lightness * 0.36).clamp(0.06, 1.0))
        .withSaturation((accentHsl.saturation * 0.9).clamp(0.0, 1.0))
        .toColor();
    final depthLight = Color.lerp(depth, Colors.white, 0.14)!;
    final depthDark = Color.lerp(depth, Colors.black, 0.4)!;
    final tilt = Matrix4.identity()
      ..setEntry(3, 2, 0.0035)
      ..rotateX(-0.20)
      ..translateByDouble(0.0, _pressed ? 7.0 : 0.0, 0.0, 1.0);
    return Semantics(
      button: true,
      enabled: enabled,
      child: Listener(
        onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onPointerCancel: enabled ? (_) => setState(() => _pressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          transform: tilt,
          transformAlignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [depthLight, depth, depthDark]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: enabled ? [
              BoxShadow(color: accent.withValues(alpha: _pressed ? 0.18 : 0.50), blurRadius: _pressed ? 16 : 44, offset: Offset(0, _pressed ? 8 : 24)),
              BoxShadow(color: const Color(0xCC020611), blurRadius: _pressed ? 6 : 12, offset: Offset(0, _pressed ? 5 : 12)),
            ] : const [],
          ),
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    stops: const [0.0, 0.42, 1.0],
                    colors: [
                      Colors.white.withValues(alpha: enabled ? 0.30 : 0.07),
                      accent.withValues(alpha: enabled ? 0.22 : 0.05),
                      const Color(0xFF0C1A2E).withValues(alpha: 0.38),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: enabled ? 0.48 : 0.10), width: 1.3),
                ),
                child: Stack(children: [
                  Positioned(left: -26, top: -34,
                    child: IgnorePointer(
                      child: Container(width: 150, height: 110,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            Colors.white.withValues(alpha: enabled ? 0.40 : 0.08),
                            Colors.white.withValues(alpha: 0),
                          ])),
                      ),
                    ),
                  ),
                  Positioned(left: 1, right: 1, top: 1,
                    child: Container(height: 26,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.white.withValues(alpha: enabled ? 0.40 : 0.07), Colors.white.withValues(alpha: 0)]),
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF93A5BB),
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 64),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                    ),
                    onPressed: widget.onPressed,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: enabled ? 0.26 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accent.withValues(alpha: enabled ? 0.65 : 0.15)),
                      ),
                      child: Icon(widget.icon, size: 21, color: enabled ? accent : const Color(0xFF93A5BB)),
                    ),
                    label: Text(widget.label),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
