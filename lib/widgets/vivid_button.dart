import 'package:flutter/material.dart';

class VividButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final List<Color> colors;
  const VividButton({super.key, required this.label, required this.icon,
    required this.onPressed, this.colors = const [Color(0xFF087C72), Color(0xFF006456)]});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: onPressed == null
        ? const [Color(0xFFCBD2DE), Color(0xFFB9C3D1)] : colors),
      borderRadius: BorderRadius.circular(20),
      boxShadow: onPressed == null ? [] : [BoxShadow(
        color: colors.first.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 7),
      )],
    ),
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent, disabledBackgroundColor: Colors.transparent,
        foregroundColor: Colors.white, disabledForegroundColor: const Color(0xFF344054),
        shadowColor: Colors.transparent, minimumSize: const Size(double.infinity, 64),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed, icon: Icon(icon, size: 25), label: Text(label),
    ),
  );
}
