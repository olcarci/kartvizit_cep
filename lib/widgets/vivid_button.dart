import 'package:flutter/material.dart';

import 'ivory_button.dart';

class VividButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color accent;
  const VividButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.accent = const Color(0xFF174B40),
  });
  @override
  Widget build(BuildContext context) => IvoryButton(
    label: label,
    icon: icon,
    onPressed: onPressed,
    selected: true,
  );
}
